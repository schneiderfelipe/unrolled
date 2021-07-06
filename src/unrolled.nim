import
  macros,
  sugar


func map(parent: NimNode, f: NimNode -> NimNode): NimNode =
  ## Walk over a `NimNode` and return a (possibly) modified one.
  result = f(parent).copy
  for i, child in parent:
    result[i] = map(child, f)


macro unroll*(forLoop: untyped): auto =
  # TODO: if we get a StmtList, find all for-loops and unroll them.
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

  var modBody: NimNode
  for i in start..stop:
    # Substitute all occurences of `index` for literal values...
    modBody = map(body) do (node: NimNode) -> NimNode:
      if node == index:
        quote do:
          `i`
      else:
        node

    # ... then insert `modBody` in place of `body` in its own `block`
    unrolledLoop.add quote do:
      block:
        `modBody`

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

  var x: int
  expandMacros:
    unroll for i in 1..3:
      var j = i + 1
      x += j
    echo x
