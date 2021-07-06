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


# A recipe for making unroll to work with arrays:
# debugEcho treeRepr over  # => Call(Sym "items", Sym "args")
# debugEcho treeRepr over[1].getType  # => BracketExpr(Sym "array", BracketExpr(Sym "range", IntLit 0, IntLit 2))
# The above will have to be called in an external typed macro and stored here in a quote do

# TODO: support unrolling based on types (arrays, tuples, etc.)


func isArrayItemsCall(over: NimNode): bool =
  # Test if a `NimNode` represents a call like `items([1, ...])`.
  let ty = over[1].getType
  over.kind == nnkCall and
  over[0].kind == nnkSym and
  over[0].strVal == "items" and
  ty.kind == nnkBracketExpr and
  ty[0].kind == nnkSym and
  ty[0].strVal == "array"


iterator staticItems(over: NimNode): auto =
  # Attempt to iterate over a `NimNode`.
  if isSlice(over):
    # Unroll something like `for i in 1..10: ...` or `for i in 1..<10: ...`.
    let
      start = over[1].intVal
      stop = over[2].intVal
    case over[0].strVal:
    of "..":
      for i in start..stop: yield i
    of "..<":
      for i in start..<stop: yield i
    else:
      raise newException(ValueError, &"cannot unroll loop over slice '{repr over}'")
  elif isArrayItemsCall(over):
    # Unroll something like `for i in items([1, ...]): ...` or equivalent.
    # debugEcho treeRepr over
    let
      ty = over[1].getType
      start = ty[1][1].intVal
      stop = ty[1][2].intVal
    for i in start..stop: yield i
  else:
    raise newException(ValueError, &"cannot unroll: neither a slice nor a dot expression '{repr over}'")


func staticGet(over, i: auto): auto =
  if isSlice(over):
    quote do:
      `i`
  elif isArrayItemsCall(over):
    let elems = over[1]
    quote do:
      `elems`[`i`]
  else:
    raise newException(ValueError, &"cannot get index {i} of '{repr over}'")


func unrollForImpl(index, over, body: NimNode): NimNode =
  result = newStmtList()

  var modBody: NimNode
  for i in staticItems(over):
    # Substitute all occurences of `index` for literal values...
    modBody = body.map do (node: NimNode) -> NimNode:
      if node == index:
        staticGet(over, i)
      else:
        node

    # ... then insert `modBody` in place of `body` in its own `block`
    result.add newBlockStmt(modBody)


func unrollFor(loop: NimNode): NimNode =
  # Unroll for-loops in general.
  loop.expectKind nnkForStmt
  result = unrollForImpl(
    loop[0], # The variable we're looping over
    loop[1], # The range we're looping over
    loop[2], # The loop body
  )
  # debugEcho treeRepr result


func unrollAll(stmts: NimNode): NimNode =
  # Unroll all for-loops in a statement list.
  stmts.expectKind nnkStmtList

  result = stmts.map do (node: NimNode) -> NimNode:
    if node.kind == nnkForStmt:
      unrollFor(node)
    else:
      node


macro unroll*(x: typed): auto =
  ## Unroll for-loops.
  result = case x.kind:
  of nnkForStmt:
    unrollFor(x)
  of nnkStmtList:
    unrollAll(x)
  else:
    raise newException(ValueError, &"cannot unroll loop '{repr x}'")
  # debugEcho treeRepr result.getType
  # debugEcho treeRepr result


when isMainModule:
  block:
    expandMacros:
      var x: int
      unroll for i in 1..3:
        var j = i + 1
        x += j
      echo x

  block:
    expandMacros:
      var total: int
      unroll for i in 1..<4:
        total += i
      echo total

  # BUG: !!!
  # block:
  #   expandMacros:
  #     var total: int
  #     for i in 1..3:
  #       unroll for j in 1..3:
  #         total += i + j
  #     echo total

  block:
    expandMacros:
      var total: int
      unroll:
        for i in 1..3:
          for j in 1..3:
            total += i + j
      echo total

  block:
    expandMacros:
      var cats: string
      # `fields` already unrolls, see <https://nim-lang.org/docs/iterators.html#fields.i,T>.
      for cat in ("Sandy", "Pelé", "Chamuscado").fields:
      # unroll for cat in ("Sandy", "Pelé", "Chamuscado").fields:
        cats &= cat & ", "
      echo cats

  block:
    expandMacros:
      var total: int
      unroll for i in [1, 2, 3]:
        total += i
      echo total

  block:
    expandMacros:
      let args = [1, 2, 3]
      var total: int
      unroll for i in args:
        total += i
      echo total
