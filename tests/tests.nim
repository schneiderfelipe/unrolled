import
  unittest,
  unrolled

suite "For-loops over slices":
  test "unroll works over slices such as 1.3":
    var total: int
    unroll for i in 1..3:
      total += i
    check total == 1 + 2 + 3
