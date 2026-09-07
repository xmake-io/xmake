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
| srpm/rpm | works, runtime-verified in chroot | wrapper installed in place of the real binary (renamed to `<name>-real`); installed into a fake root and run via `unshare -Ur chroot` — env+args applied |
| deb | works, runtime-verified in chroot | same wrapper scheme; verified in the built .deb via fake-root chroot run (full build needs `devscripts` + `-d` to skip the xmake build-dep check) |
| nsis | works, runtime-verified under wine | shortcut wired into `makensis.nsi`; `.cmd` wrapper installed for env vars; installed to a space-free path and the `.cmd` run via `wine cmd` — env+args applied |
| wix | `.wxs` correct | relative target, single `Arguments`, inline title, `ApplicationProgramsFolder` defined, gated; runenvs applied via an installed `.cmd` wrapper the shortcut points at; MSI build needs Windows |
| runself | works, runtime-verified | setup.sh now builds then installs into `$PREFIX` (the extraction dir) and launches with env+args; verified under a TTY |
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
- nsis `_translate_filepath` produced forward-slash paths on non-Windows hosts;
  `SetOutPath "$InstDir/bin"` made NSIS install the binary to a path with the
  separator dropped (e.g. `C:\launcherbin`). Emitted paths are now converted to
  backslashes (`_nsis_path`), which fixed the binary landing in the wrong dir.
- runself `setup.sh` referenced `$PREFIX`, which makeself never defines, and
  never built the sources. It now defines `PREFIX="$(pwd)"` and translates the
  install paths to `$PREFIX`, and builds the targets before installing.
- wix `runenvs` were warned-and-skipped; a `.cmd` wrapper is now generated and
  installed so the shortcut can apply env vars (like nsis).
- `debian/compat` (9) conflicted with `debhelper-compat (= 13)` in the deb
  template; the stale compat file was removed.
