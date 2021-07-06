# Package

version       = "0.1.0"
author        = "Felipe S. S. Schneider"
description   = "Unroll for-loops at compile-time."
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.4.8"

# Tasks

task docs, "Generate documentation":
  exec "nim doc --project --index:on --git.url:https://github.com/schneiderfelipe/unrolled --git.commit:master --outdir:docs src/unrolled.nim"
  exec "ln -s unrolled.html docs/index.html || true"
