# Full-BMI include-path regression

This standalone project has no package or standard-library-module dependencies.
The module's global fragment uses one normal include directory and one system
include directory, both with spaces in their names. The executable checks that
both headers were found and the compiled module returns 42.

On Windows with clang-cl 19 or newer:

```console
xmake f -c -y --toolchain=clang-cl --ccache=n --policies=build.c++.modules.two_phases:y,build.c++.modules.clang.precompile_reduced_bmi:n
xmake b -rv
xmake r
```

On Linux/macOS, use `--toolchain=clang` with Clang 19 or newer instead.

Before the fix, the PCM-to-object command retains `-I` and, on clang-cl,
`-external:I`. `-Werror=unused-command-line-argument` makes it fail with:

```text
clang-cl: error: argument unused during compilation: '-I local headers' [-Werror,-Wunused-command-line-argument]
clang-cl: error: argument unused during compilation: '-external:I system headers' [-Werror,-Wunused-command-line-argument]
```

After the fix, the same commands build and run successfully. Include directories
remain on source-to-BMI and ordinary source compilations. The project test also
checks one-phase compilation and no-op incremental builds:

```console
xmake lua tests/run.lua pcm_include_flags
```

Run that last command from the XMake repository root using its local scripts.
