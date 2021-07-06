# unrolled

Unroll loops at compile-time.

```nim
var total: int
unroll for i in 1..3:
  total += i
echo total
```

The above actually executes the following

```nim
var total: int
block:
  let i = 1
  total += i
block:
  let i = 2
  total += i
block:
  let i = 3
  total += i
echo [total]
```

## Other projects

- [Unrolled.jl](https://github.com/cstjean/Unrolled.jl) (Julia)
