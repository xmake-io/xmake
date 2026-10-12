# launcher_app

A minimal C binary that prints its argv and a few environment variables. It is
packaged with `xpack` so the `runenvs`/`runargs` launcher wrappers can be
exercised for each host-supported format.

The `xpack` config sets:

```lua
add_runargs("--mode", "test")
add_runenvs("XMAKE_TEST_ENV", "launcher-ok")
add_runenvs("XMAKE_TEST_HERE", "$HERE")
add_runenvs("XMAKE_TEST_PREFIX", "$PREFIX")
```

`$HERE`/`$PREFIX` are expanded at runtime by the generated launcher (they are
literally present in the wrapper when the variable is undefined, e.g. `$PREFIX`
for an appimage).

## Running the tests

The tests are picked up automatically by `tests/run.lua` on every platform CI:

```sh
xmake lua -v -D tests/run.lua launcher_app
```

They contain two layers:

- unit tests for `plugins.pack.launcher` with a mock package (every platform)
- integration tests that pack the fixture and run the launcher, gated per host:
  appimage/runself/deb/rpm/srpm on linux, nsis/wix on windows, dmg on macos.
  Formats are skipped when their packaging tool is unavailable.

Format coverage:

| Format  | Host    | Verified |
| ------- | ------- | -------- |
| appimage | linux  | packed + run, `$HERE` expanded |
| runself  | linux  | packed + run, `$PREFIX` expanded |
| deb      | linux  | packed (requires `debuild`) |
| rpm      | linux  | packed (requires `rpmbuild`) |
| srpm     | linux  | packed (requires `rpmbuild`) |
| nsis     | windows | packed |
| wix      | windows | packed (requires the WiX toolset) |
| dmg      | macos  | packed |
