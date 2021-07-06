import
  macros,
  sugar


func map(parent: NimNode, f: NimNode -> NimNode): NimNode =
  ## Walk over a `NimNode` and return a (possibly) modified one.
  result = parent.copy
  for i, child in parent:
    result[i] = map(child, f)
  result = f(result)


# A recipe for making unroll to work with arrays:
# debugEcho treeRepr over  # => Call(Sym "items", Sym "args")
# debugEcho treeRepr getType over[1]  # => BracketExpr(Sym "array", BracketExpr(Sym "range", IntLit 0, IntLit 2))
# The above will have to be called in an external typed macro and stored here in a quote do


func unrollForSlice(index, over, body: NimNode): NimNode =
  # We make sure it's something like `1..10`
  # TODO: support unrolling based on types (arrays, tuples, etc.)
  over.expectKind nnkInfix
  assert over[0].strVal == ".."
  over[1].expectKind nnkIntLit
  over[2].expectKind nnkIntLit

  result = newStmtList()
  let
    start = over[1].intVal
    stop = over[2].intVal
  var modBody: NimNode

  for i in start..stop:
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
  stmts.expectKind nnkStmtList

  result = stmts.map do (node: NimNode) -> NimNode:
    if node.kind == nnkForStmt:
      unrollFor(node)
    else:
      node


macro unroll*(x: untyped): auto =
  result = case x.kind:
  of nnkForStmt:
    unrollFor(x)
  of nnkStmtList:
    unrollAll(x)
  else:
    debugEcho "COULD NOT UNROLL"
    x
  # debugEcho treeRepr result


when isMainModule:
  block:
    # expandMacros:
      var total: int
      unroll for i in 1..3:
        total += i
      echo total

  block:
    # expandMacros:
      var x: int
      unroll for i in 1..3:
        var j = i + 1
        x += j
      echo x

  block:
    expandMacros:
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
