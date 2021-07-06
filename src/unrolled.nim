import macros

macro unroll*(forLoop: untyped): auto =
  # TODO: if we get a StmtList, find all for loops and apply macro
  forLoop.expectKind nnkForStmt

  let
    index = forLoop[0] # The variable we're looping over
    over = forLoop[1]  # The range we're looping over
    body = forLoop[2]  # The loop body

    start = over[1].intVal
    stop = over[2].intVal
    unrolledLoop = newStmtList()

  # We make sure it's something like `1..10`
  # TODO: support unrolling based on types (arrays, tuples, etc.)
  over.expectKind nnkInfix
  assert over[0].strVal == ".."
  over[1].expectKind nnkIntLit
  over[2].expectKind nnkIntLit

  # TODO: substitute values into the body
  for i in start..stop:
    unrolledLoop.add quote do:
      block:
        let `index` = `i`
        `body`

  # TODO: can we safely remove the compilation test?
  result = quote do:
    when compiles(`forLoop`):
      `unrolledLoop`
    else:
      `forLoop`

  # debugEcho treeRepr result

when isMainModule:
  expandMacros:
    var total: int
    unroll for i in 1..3:
      total += i
    echo total
