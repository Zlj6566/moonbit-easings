# Example workflow

The runnable demo is kept in `cmd/demo` so it is built by the same MoonBit
toolchain as the library:

```sh
moon run cmd/demo
```

It prints a custom CSS-style Cubic-Bezier tween, finite-difference velocity,
and a keyframe track with a curve report. The example intentionally has no
runtime dependency on a rendering backend; a UI, game, SVG, or video exporter
can consume the same samples.
