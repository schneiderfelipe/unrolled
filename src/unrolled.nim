import
  macros,
  sugar


func map(parent: NimNode, f: NimNode -> NimNode): NimNode =
  # Walk over a `NimNode` and return a (possibly) modified one.
  result = parent.copy
  for i, child in parent:
    result[i] = map(child, f)
  result = f(result)


iterator staticItems(over: NimNode): auto =
  # Attempt to iterate over a `NimNode`.
  over.expectKind nnkInfix
  over[1].expectKind nnkIntLit
  over[2].expectKind nnkIntLit

  let
    start = over[1].intVal
    stop = over[2].intVal
  case over[0].strVal:
  of "..":
    for i in start..stop: yield i
  of "..<":
    for i in start..<stop: yield i
  else:
    assert false


# A recipe for making unroll to work with arrays:
# debugEcho treeRepr over  # => Call(Sym "items", Sym "args")
# debugEcho treeRepr getType over[1]  # => BracketExpr(Sym "array", BracketExpr(Sym "range", IntLit 0, IntLit 2))
# The above will have to be called in an external typed macro and stored here in a quote do

# TODO: support unrolling based on types (arrays, tuples, etc.)


func unrollForSlice(index, over, body: NimNode): NimNode =
  # Unroll something like `for i in 1..10: ...` or `for i in 1..<10: ...`.
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

  let unrolledLoop = unrollForSlice(
    loop[0],  # The variable we're looping over
    loop[1],  # The range we're looping over
    loop[2],  # The loop body
  )

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


macro unroll*(x: untyped): auto =
  ## Unroll for-loops.
  result = case x.kind:
  of nnkForStmt:
    unrollFor(x)
  of nnkStmtList:
    unrollAll(x)
  else:
    debugEcho "COULD NOT UNROLL"
    assert false
    x
  # debugEcho treeRepr result


when isMainModule:
  block:
    expandMacros:
      var total: int
      unroll for i in 1..<4:
        total += i
      echo total

  block:
    var x: int
    unroll for i in 1..3:
      var j = i + 1
      x += j
    echo x

  block:
    var total: int
    unroll:
      for i in 1..3:
        for j in 1..3:
          total += i + j
    echo total

  # block:
  #   expandMacros:
  #     let args = [1, 2, 3]
  #     unroll for i in args:
  #       echo $i
