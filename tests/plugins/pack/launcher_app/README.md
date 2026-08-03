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

| Format | Status | Issue |
|---|---|---|
| appimage | works | launcher (AppRun) gets env + args, correct exec path |
| nsis | dead code | `PACKAGE_NSIS_STARTMENU_SHORTCUT` is never referenced in `makensis.nsi`; zero `CreateShortCut` emitted; runenvs unsupported |
| wix | broken | shortcut target is an absolute build path, duplicate `Arguments` attrs, unresolved `${PACKAGE_TITLE}`, `ApplicationProgramsFolder` undefined, shortcut added unconditionally, runenvs unsupported |
| deb/srpm | not wired | wrapper is dropped into the source archive but never installed into the package; exec path would be `/usr/<abs>` |
| dmg | broken path | exec line `/usr/local/<abs>`; cannot build on Linux (hdiutil/macOS) |
| runself | broken path + unconditional | `exec "$PREFIX/<abs>"`; appends exec block even with no envs/args |

Root cause for the path issues: `launcher.lua:main_executable()` uses
`package:bindir()` which returns an *absolute* path, while every caller expects a
path relative to the prefixdir (e.g. `bin/foo`).

Also uncovered: `io.gsub(..., {encoding = "ansi"})` reads 0 bytes on Linux, which
broke the nsis specfile substitution (only relevant once nsis runs on non-Windows).
