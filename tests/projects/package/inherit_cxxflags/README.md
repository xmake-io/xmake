# Public/interface package flags regression

From the repository root, using the local Xmake scripts:

```console
xmake lua tests/run.lua inherit_cxxflags
```

Or run the minimal project directly:

```console
cd tests/projects/package/inherit_cxxflags
xmake f -c -y -m debug
xmake build -r
xmake run consumer
xmake run no_inherit
xmake run override_consumer
```

The three local, empty packages export `-DPACKAGE_*` through raw `cxxflags`,
not the named `defines` setting. No packages need to be downloaded.

`producer` attaches these packages as public, private, and interface-only.
The consumer must inherit only the public/interface flags through a phony
intermediate target. Compile-time checks also ensure that private flags do
not leak, interface-only flags do not affect the producer, `inherit = false`
is respected, and per-target package flag overrides are preserved.

Without the fix, the consumer fails with
`Missing transitive public/interface package flags`. The automated test
builds and runs the consumers with the default toolchain and additionally
clang-cl when available on Windows.
