# Local launcher feature validation

This fixture (`launcher_app`) is a minimal C binary that prints its argv and the
`XMAKE_TEST_ENV` env var, packaged with `xpack` formats so the "runenvs/runargs
launcher" feature (commit e290b3a) can be exercised and validated locally.

## Build & run on Linux

Only `nsis` builds a real installer on Linux. `wix` generates the `.wxs` but the
MSI cannot be built on Linux (WiX toolchain is Windows-only). `dmg` requires macOS.

Tools (no sudo):

- `makensis` extracted from Debian's `nsis` + `nsis-common` `.debs` (or `sudo apt install nsis`)
- `UAC.nsh` (+ `UAC.dll`) from https://github.com/xmake-mirror/nsis/releases/download/v309/UAC.zip
- `wix` dotnet tool: `dotnet tool install --global wix --version 4.0.6`

```sh
export XMAKE_PROGRAM_DIR=/path/to/xmake-src/xmake   # use this repo's lua sources
export PATH="$HOME/.dotnet/tools:$HOME/.local/opt/nsis/usr/bin:$PATH"
export NSISDIR="$HOME/.local/opt/nsis/usr/share/nsis"

# the nsis plugin only runs when the target platform is windows (makensis is
# cross-platform, so a Windows installer can be built from any host)
xmake f -y -m release -p windows -a x64 -P .   # needs a windows toolchain (e.g. mingw)
xmake pack -y --formats=nsis --autobuild=y -P .      # -> build/xpack/launcher_app/*.exe
# wix still requires a Windows host (the WiX toolset cannot build MSIs on Linux)
```

The NSIS installer can be exercised under wine:

```sh
WINEPREFIX=/tmp/wp wine build/xpack/launcher_app/launcher_app-1.0.0.exe /S /NOADMIN
```

## Findings (validated on real generated artifacts, 2026-08-03)

The launcher feature (commit e290b3a) was broken for every format except
appimage. All issues were fixed in this branch:

| Format | Status | Fix / remaining limitation |
|---|---|---|
| appimage | works, run-tested | AppRun sets env + args; verified `--mode test` prepended and `XMAKE_TEST_ENV` set at runtime |
| srpm/rpm | works | wrapper installed in place of the real binary, real binary renamed to `<name>-real`; verified in the built rpm |
| deb | works | same wrapper scheme; verified in the built .deb (full build needs `devscripts` + `-d` to skip the xmake build-dep check) |
| nsis | works | shortcut wired into `makensis.nsi`; `.cmd` wrapper installed for env vars; verified the .exe builds and installs under wine |
| wix | `.wxs` correct | relative target, single `Arguments`, inline title, `ApplicationProgramsFolder` defined, gated; `runenvs` unsupported (warned); MSI build needs Windows |
| runself | wiring correct | `$PREFIX/bin/<name>` + gated on envs/args; runtime limited by a pre-existing runself issue (install writes to a host path, not `$PREFIX`) |
| dmg | code correct | relative exec path inside the `.app` bundle; cannot build on Linux (hdiutil/macOS) |

Root causes fixed:

- `launcher.lua:main_executable()` returned an *absolute* path (via
  `package:bindir()`); it now returns a prefixdir-relative path like `bin/foo`.
- `launcher.generate()` now single-quotes env values and args (exec path stays
  in double quotes to allow `$PREFIX`/`${HERE}` expansion).
- deb/srpm wrappers are now registered as install commands (rename the real
  binary to `<name>-real`, install the wrapper in its place) instead of being
  dropped unused into the source archive.
- nsis `PACKAGE_NSIS_STARTMENU_SHORTCUT` was never referenced in the template;
  it is wired in now. Env vars are applied via an installed `.cmd` wrapper.
- wix had an absolute target path, duplicate `Arguments` attrs, unresolved
  `${PACKAGE_TITLE}` and an undefined `ApplicationProgramsFolder`; all fixed.

Also fixed while testing:

- `io.gsub(..., {encoding = "ansi"})` reads 0 bytes on Linux, silently breaking
  nsis specfile substitution (only used on Windows hosts now).
- nsis/wix plugins were gated on `is_host("windows")`; nsis is now gated on the
  target platform (`package:is_plat("windows", "mingw")`) so Linux can cross-pack
  it (makensis is cross-platform). wix stays host-gated (WiX can't build MSIs on
  Linux).
- `get_zig_target` mapped `-p windows` to `x86_64-windows-msvc`; zig bundles the
  mingw headers, so it now maps to `-windows-gnu` on any host (use `--cross` for
  an explicit MSVC target).
- `debian/compat` (9) conflicted with `debhelper-compat (= 13)` in the deb
  template; the stale compat file was removed.
