import
  macros,
  strformat,
  sugar


func map(parent: NimNode, f: NimNode -> NimNode): NimNode =
  # Walk over a `NimNode` and return a (possibly) modified one.
  result = parent.copyNimNode
  for child in parent:
    result.add map(child, f)
  result = f(result)


func isSlice(over: NimNode): bool =
  # Test if a `NimNode` represents a slice.
  over.kind == nnkInfix and
  over[1].kind == nnkIntLit and
  over[2].kind == nnkIntLit


iterator staticItems(over: NimNode): auto =
  # Attempt to iterate over a `NimNode`.
  assert isSlice(over), &"not a slice '{repr over}'"

  let
    start = over[1].intVal
    stop = over[2].intVal
  case over[0].strVal:
  of "..":
    for i in start..stop: yield i
  of "..<":
    for i in start..<stop: yield i
  else:
    raise newException(ValueError, &"cannot not unroll loop over '{repr over}'")


# A recipe for making unroll to work with arrays:
# debugEcho treeRepr over  # => Call(Sym "items", Sym "args")
# debugEcho treeRepr getType over[1]  # => BracketExpr(Sym "array", BracketExpr(Sym "range", IntLit 0, IntLit 2))
# The above will have to be called in an external typed macro and stored here in a quote do

# TODO: support unrolling based on types (arrays, tuples, etc.)


func unrollForSlice(index, over, body: NimNode): NimNode =
  # Unroll something like `for i in 1..10: ...` or `for i in 1..<10: ...`.
  assert isSlice(over), &"not a slice '{repr over}'"

  result = newStmtList()

  var modBody: NimNode
  for i in staticItems(over):
    # Substitute all occurences of `index` for literal values...
    modBody = body.map do (node: NimNode) -> NimNode:
      if node == index:
        quote do:
          `i`
      else:
        node

    # ... then insert `modBody` in place of `body` in its own `block`
    result.add quote do:
      block:
        `modBody`


func unrollFor(loop: NimNode): NimNode =
  # Unroll for-loops in general.
  loop.expectKind nnkForStmt

  var unrolledLoop: NimNode
  if isSlice(loop[1]):
    unrolledLoop = unrollForSlice(
      loop[0],  # The variable we're looping over
      loop[1],  # The range we're looping over
      loop[2],  # The loop body
    )
  else:
    raise newException(ValueError, &"cannot not unroll loop over '{repr loop[1]}'")

  # TODO: can we safely remove the compilation test?
  result = quote do:
    when compiles(`loop`):
      `unrolledLoop`
    else:
      `loop`


func unrollAll(stmts: NimNode): NimNode =
  # Unroll all for-loops in a statement list.
  stmts.expectKind nnkStmtList

  result = stmts.map do (node: NimNode) -> NimNode:
    if node.kind == nnkForStmt:
      unrollFor(node)
    else:
      node


macro unroll*(x: untyped): untyped =
  ## Unroll for-loops.
  result = case x.kind:
  of nnkForStmt:
    unrollFor(x)
  of nnkStmtList:
    unrollAll(x)
  else:
    raise newException(ValueError, &"cannot not unroll loop '{repr x}'")
  # debugEcho treeRepr result


when isMainModule:
  block:
    var x: int
    unroll for i in 1..3:
      var j = i + 1
      x += j
    echo x

  block:
    var total: int
    unroll for i in 1..<4:
      total += i
    echo total

  block:
    var total: int
    for i in 1..3:
      unroll for j in 1..3:
        total += i + j
    echo total

  block:
    var total: int
    unroll:
      for i in 1..3:
        for j in 1..3:
          total += i + j
    echo total

  # block:
  #   expandMacros:
  #     var cats: string
  #     unroll for cat in ("Sandy", "Junior", "Chamuscado").fields:
  #       cats &= cat & ", "
  #     echo cats

  # block:
  #   let args = [1, 2, 3]
  #   unroll for i in args:
  #     echo $i
