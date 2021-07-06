# unrolled

Unroll loops at compile-time.

```nim
var total: int
unroll for i in 1..3:
  total += i
echo total
```

The above actually executes the following (see with [`expandMacros`](https://nim-lang.org/docs/macros.html#expandMacros.m%2Ctyped))

```nim
var total: int
block:
  total += 1
block:
  total += 2
block:
  total += 3
echo total
```

(The usage of `block`s ensure variables never "leak".)

## Other projects

- [Unrolled.jl](https://github.com/cstjean/Unrolled.jl) (Julia)
