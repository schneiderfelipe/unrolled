import
  unittest,
  macros,  # for eyeballing `expandMacros` results
  unrolled

suite "For-loops over slices":
  test "unroll works over slices such as 1.3":
    expandMacros:
      var total: int
      unroll for i in 1..3:
        total += i
    check total == 1 + 2 + 3

  test "unroll works when variables are defined within the loop":
    expandMacros:
      var x: int
      unroll for i in 1..3:
        var j = i + 1
        x += j
    check x == (1 + 1) + (2 + 1) + (3 + 1)

  test "unroll works in inner nested loops":
    expandMacros:
      var total: int
      for i in 1..3:
        unroll for j in 1..3:
          total += i + j
    check total == (1 + 1) + (1 + 2) + (1 + 3) +
                   (2 + 1) + (2 + 2) + (2 + 3) +
                   (3 + 1) + (3 + 2) + (3 + 3)

  test "unroll works in outer nested loops":
    expandMacros:
      var total: int
      unroll for i in 1..3:
        for j in 1..3:
          total += i + j
    check total == (1 + 1) + (1 + 2) + (1 + 3) +
                   (2 + 1) + (2 + 2) + (2 + 3) +
                   (3 + 1) + (3 + 2) + (3 + 3)

  test "unroll works with multiple nested loops":
    expandMacros:
      var total: int
      unroll:
        for i in 1..3:
          for j in 1..3:
            total += i + j
    check total == (1 + 1) + (1 + 2) + (1 + 3) +
                   (2 + 1) + (2 + 2) + (2 + 3) +
                   (3 + 1) + (3 + 2) + (3 + 3)
