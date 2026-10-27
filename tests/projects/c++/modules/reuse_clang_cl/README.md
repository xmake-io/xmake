# clang-cl module reuse regression

From the repository root, using the local Xmake scripts:

```console
xmake lua tests/run.lua cxx_module_flags
xmake lua tests/run.lua reuse_clang_cl
```

For a manual reproduction on Windows with clang-cl 19 or newer:

```console
cd tests/projects/c++/modules/reuse_clang_cl
xmake f -c -y -m debug --toolchain=clang-cl --ccache=n
xmake build -rvD
```

`producer` exports a primary interface, a `.cpp` interface partition, and an
ordinary module implementation. Two consumers only differ from the producer
in their PDB output path and an additional system include directory. They
should reuse the producer's modules instead of rebuilding them.

The test also covers a module-only producer, a different language standard,
and a different macro under strict reuse checking. Incompatible consumers
must not reuse the producer's BMI. Ordinary implementations must not be
reinserted into dependency consumers' C++ compilation queues, or compiled by
the BMI-only producer.

The automated test exercises both one-phase and two-phase compilation,
checks implementation compile counts and reuse decisions, runs every
consumer, and checks a no-op incremental build. No external packages or
HitagiEngine sources are needed.
