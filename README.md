# unrolled

Unroll for-loops at compile-time.

```nim
var total: int
unroll for i in 1..3:
  total += i
```

The above generates the following code (check with [`expandMacros`](https://nim-lang.org/docs/macros.html#expandMacros.m%2Ctyped))

```nim
var total: int
block:
  total += 1
block:
  total += 2
block:
  total += 3
```

(The usage of `block`s ensure variables never "leak".)

**Note**: currently, we have two serious known bugs,
one regarding variable definitions in the loop body (see [#1](https://github.com/schneiderfelipe/unrolled/issues/1)), and
one about nested loops (see [#2](https://github.com/schneiderfelipe/unrolled/issues/2)).
I expect to solve them some time soon.

## Installation

unrolled supports Nim 1.0.0+ and can be installed using [Nimble](https://github.com/nim-lang/Nimble):

    $ nimble install unrolled

## Other projects

- [Unrolled.jl](https://github.com/cstjean/Unrolled.jl) (Julia)
