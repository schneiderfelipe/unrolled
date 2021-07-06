import
  unittest,
  unrolled

suite "For-loops over slices":
  test "unroll works over slices such as 1.3":
    var total: int
    unroll for i in 1..3:
      total += i
    check total == 1 + 2 + 3

  test "unroll works when variables are defined within the loop":
    var x: int
    unroll for i in 1..3:
      var j = i + 1
      x += j
    check x == (1 + 1) + (2 + 1) + (3 + 1)
