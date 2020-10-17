# Changelog ([中文](#中文))

## master (unreleased)

## v2.3.8

### New features

* [#955](https://github.com/xmake-io/xmake/issues/955): Add zig project templates
* [#956](https://github.com/xmake-io/xmake/issues/956): Add wasm platform and support Qt/Wasm SDK
* Upgrade luajit vm and support for runing on mips64 device
* [#972](https://github.com/xmake-io/xmake/issues/972): Add `depend.on_changed()` api to simplify adding dependent files
* [#981](https://github.com/xmake-io/xmake/issues/981): Add `set_fpmodels()` for math optimization mode
* [#980](https://github.com/xmake-io/xmake/issues/980): Support Intel C/C++ and Fortran Compiler
* [#986](https://github.com/xmake-io/xmake/issues/986): Support for `c11` and `c17` for MSVC Version 16.8 and Above
* [#979](https://github.com/xmake-io/xmake/issues/979): Add Abstraction for OpenMP. `add_rules("c++.openmp")`

### Change

* [#958](https://github.com/xmake-io/xmake/issues/958): Improve mingw platform to support llvm-mingw toolchain
* Improve `add_requires("zlib~xxx")` to support for installing multi-packages at same time
* [#977](https://github.com/xmake-io/xmake/issues/977): Improve find_mingw for windows
* [#978](https://github.com/xmake-io/xmake/issues/978): Improve toolchain flags order
* Improve Xcode toolchain to support for macOS/arm64

### Bugs fixed

* [#951](https://github.com/xmake-io/xmake/issues/951): Fix emcc support for windows
* [#992](https://github.com/xmake-io/xmake/issues/992): Fix filelock bug

## v2.3.7

### New features

* [#2941](https://github.com/microsoft/winget-pkgs/pull/2941): Add support for winget
* Add xmake-tinyc installer without msvc compiler for windows
* Add tinyc compiler toolchain
* Add emcc compiler toolchain (emscripten) to compiling to asm.js and WebAssembly
* [#947](https://github.com/xmake-io/xmake/issues/947): Add `xmake g --network=private` to enable the private network

### Change

* [#907](https://github.com/xmake-io/xmake/issues/907): Improve to the linker optimization for msvc
* Improve to detect qt sdk environment
* [#918](https://github.com/xmake-io/xmake/pull/918): Improve to support cuda11 toolchains
* Improve Qt support for ubuntu/apt
* Improve CMake project generator
* [#931](https://github.com/xmake-io/xmake/issues/931): Support to export packages with all dependences
* [#930](https://github.com/xmake-io/xmake/issues/930): Support to download package without version list directly
* [#927](https://github.com/xmake-io/xmake/issues/927): Support to switch arm/thumb mode for android ndk
* Improve trybuild/cmake to support android/mingw/iphoneos/watchos toolchains

### Bugs fixed

* [#903](https://github.com/xmake-io/xmake/issues/903): Fix install vcpkg packages fails
* [#912](https://github.com/xmake-io/xmake/issues/912): Fix the custom toolchain
* [#914](https://github.com/xmake-io/xmake/issues/914): Fix bad light userdata pointer for lua on some aarch64 devices

## v2.3.6

### New features

* Add `xmake project -k xcode` generator (use cmake)
* [#870](https://github.com/xmake-io/xmake/issues/870): Support gfortran compiler
* [#887](https://github.com/xmake-io/xmake/pull/887): Support zig compiler
* [#893](https://github.com/xmake-io/xmake/issues/893): Add json module
* [#898](https://github.com/xmake-io/xmake/issues/898): Support cross-compilation for golang
* [#275](https://github.com/xmake-io/xmake/issues/275): Support go package manager to install go packages
* [#581](https://github.com/xmake-io/xmake/issues/581): Support dub package manager to install dlang packages

### Change

* [#868](https://github.com/xmake-io/xmake/issues/868): Support new cl.exe dependency report files, `/sourceDependencies xxx.json`
* [#902](https://github.com/xmake-io/xmake/issues/902): Improve to detect cross-compilation toolchain

## v2.3.5

### New features

* Add `xmake show -l envs` to show all builtin envirnoment variables
* [#861](https://github.com/xmake-io/xmake/issues/861): Support search local package file to install remote package
* [#854](https://github.com/xmake-io/xmake/issues/854): Support global proxy settings for curl, wget and git

### Change

* [#828](https://github.com/xmake-io/xmake/issues/828): Support to import sub-directory files for protobuf rules
* [#835](https://github.com/xmake-io/xmake/issues/835): Improve mode.minsizerel to add /GL flags for msvc
* [#828](https://github.com/xmake-io/xmake/issues/828): Support multi-level directories for protobuf/import
* [#838](https://github.com/xmake-io/xmake/issues/838#issuecomment-643570920): Support to override builtin-rules for `add_files("src/*.c", {rules = {"xx", override = true}})`
* [#847](https://github.com/xmake-io/xmake/issues/847): Support to parse include deps for rc file
* Improve msvc tool chain, remove the dependence of global environment variables
* [#857](https://github.com/xmake-io/xmake/pull/857): Improved `set_toolchains()` when cross-compilation is supported, specific target can be switched to host toolchain and compiled at the same time

### Bugs fixed

* Fix the progress bug for theme
* [#829](https://github.com/xmake-io/xmake/issues/829): Fix invalid sysroot path for macOS
* [#832](https://github.com/xmake-io/xmake/issues/832): Fix find_packages bug for the debug mode

## v2.3.4

### New features

* [#630](https://github.com/xmake-io/xmake/issues/630): Support *BSD system, e.g. FreeBSD, ..
* Add wprint builtin api to show warnings
* [#784](https://github.com/xmake-io/xmake/issues/784): Add `set_policy()` to set and modify some builtin policies
* [#780](https://github.com/xmake-io/xmake/issues/780): Add set_toolchains/set_toolsets for target and improve to detect cross-compilation toolchains
* [#798](https://github.com/xmake-io/xmake/issues/798): Add `xmake show` plugin to show some builtin configuration values and infos
* [#797](https://github.com/xmake-io/xmake/issues/797): Add ninja theme style, e.g. `xmake g --theme=ninja`
* [#816](https://github.com/xmake-io/xmake/issues/816): Add mode.releasedbg and mode.minsizerel rules
* [#819](https://github.com/xmake-io/xmake/issues/819): Support ansi/vt100 terminal control

### Change

* [#771](https://github.com/xmake-io/xmake/issues/771): Check includedirs, linkdirs and frameworkdirs
* [#774](https://github.com/xmake-io/xmake/issues/774): Support ltui windows resize for `xmake f --menu`
* [#782](https://github.com/xmake-io/xmake/issues/782): Add check flags failed tips for add_cxflags, ..
* [#808](https://github.com/xmake-io/xmake/issues/808): Support add_frameworks for cmakelists
* [#820](https://github.com/xmake-io/xmake/issues/820): Support independent working/build directory

### Bugs fixed

* [#786](https://github.com/xmake-io/xmake/issues/786): Fix check header file deps
* [#810](https://github.com/xmake-io/xmake/issues/810): Fix strip debug bug for linux

## v2.3.3

### New features

* [#727](https://github.com/xmake-io/xmake/issues/727): Strip and generate debug symbols file (.so/.dSYM) for android/ios program
* [#687](https://github.com/xmake-io/xmake/issues/687): Support to generate objc/bundle program.
* [#743](https://github.com/xmake-io/xmake/issues/743): Support to generate objc/framework program.
* Support to compile bundle, framework, mac application and ios application, and all some project templates
* Support generate ios *.ipa file and codesign
* Add xmake.cli rule to develop lua program with xmake core engine

### Change

* [#750](https://github.com/xmake-io/xmake/issues/750): Improve qt.widgetapp rule to support private slot
* Improve Qt/deploy for android and support Qt 5.14.0

## v2.3.2

### New features

* Add powershell theme for powershell terminal
* Add `xmake --dry-run -v` to dry run building target and only show verbose build command.
* [#712](https://github.com/xmake-io/xmake/issues/712): Add sdcc platform and support sdcc compiler

### Change

* [#589](https://github.com/xmake-io/xmake/issues/589): Improve and optimize build speed, supports parallel compilation and linking across targets
* Improve the ninja/cmake generator
* [#728](https://github.com/xmake-io/xmake/issues/728): Improve os.cp to support reserve source directory structure
* [#732](https://github.com/xmake-io/xmake/issues/732): Improve find_package to support `homebrew/cmake` pacakges
* [#695](https://github.com/xmake-io/xmake/issues/695): Improve android abi

### Bugs fixed

* Fix the link errors output issues for msvc
* [#718](https://github.com/xmake-io/xmake/issues/718): Fix download cache bug for package
* [#722](https://github.com/xmake-io/xmake/issues/722): Fix invalid package deps
* [#719](https://github.com/xmake-io/xmake/issues/719): Fix process exit bug
* [#720](https://github.com/xmake-io/xmake/issues/720): Fix compile_commands generator

## v2.3.1

### New features

* [#675](https://github.com/xmake-io/xmake/issues/675): Support to compile `*.c` as c++, `add_files("*.c", {sourcekind = "cxx"})`.
* [#681](https://github.com/xmake-io/xmake/issues/681): Support compile xmake on msys/cygwin and add msys/cygwin platform
* Add socket/pipe io modules and support to schedule socket/process/pipe in coroutine
* [#192](https://github.com/xmake-io/xmake/issues/192): Try building project with the third-party buildsystem
* Enable color diagnostics output for gcc/clang
* [#588](https://github.com/xmake-io/xmake/issues/588): Improve project generator, `xmake project -k ninja`, support for build.ninja

### Change

* [#665](https://github.com/xmake-io/xmake/issues/665): Support to parse *nix style command options, thanks [@OpportunityLiu](https://github.com/OpportunityLiu)
* [#673](https://github.com/xmake-io/xmake/pull/673): Improve tab complete to support argument values
* [#680](https://github.com/xmake-io/xmake/issues/680): Improve get.sh scripts and add download mirrors
* Improve process scheduler
* [#651](https://github.com/xmake-io/xmake/issues/651): Improve os/io module syserrors tips

### Bugs fixed

* Fix incremental compilation for checking the dependent file
* Fix log output for parsing xmake-vscode/problem info
* [#684](https://github.com/xmake-io/xmake/issues/684): Fix linker errors for android ndk on windows

## v2.2.9

### New features

* [#569](https://github.com/xmake-io/xmake/pull/569): Add c++ modules build rules
* Add `xmake project -k xmakefile` generator
* [620](https://github.com/xmake-io/xmake/issues/620): Add global `~/.xmakerc.lua` for all projects.
* [593](https://github.com/xmake-io/xmake/pull/593): Add `core.base.socket` module.

### Change

* [#563](https://github.com/xmake-io/xmake/pull/563): Separate build rules for specific language files from action/build
* [#570](https://github.com/xmake-io/xmake/issues/570): Add `qt.widgetapp` and `qt.quickapp` rules
* [#576](https://github.com/xmake-io/xmake/issues/576): Uses `set_toolchain` instead of `add_tools` and `set_tools`
* Improve `xmake create` action
* [#589](https://github.com/xmake-io/xmake/issues/589): Improve the default build jobs number to optimize build speed
* [#598](https://github.com/xmake-io/xmake/issues/598): Improve find_package to support .tbd libraries on macOS
* [#615](https://github.com/xmake-io/xmake/issues/615): Support to install and use other archs and ios conan packages
* [#629](https://github.com/xmake-io/xmake/issues/629): Improve hash.uuid and implement uuid v4
* [#639](https://github.com/xmake-io/xmake/issues/639): Improve to parse argument options to support -jN

### Bugs fixed

* [#567](https://github.com/xmake-io/xmake/issues/567): Fix out of memory for serialize
* [#566](https://github.com/xmake-io/xmake/issues/566): Fix link order problem with remote packages
* [#565](https://github.com/xmake-io/xmake/issues/565): Fix run path for vcpkg packages
* [#597](https://github.com/xmake-io/xmake/issues/597): Fix run `xmake require` command too slowly
* [#634](https://github.com/xmake-io/xmake/issues/634): Fix mode.coverage rule and check flags

## v2.2.8

### New features

* Add protobuf c/c++ rules
* [#468](https://github.com/xmake-io/xmake/pull/468): Add utf-8 support for io module on windows
* [#472](https://github.com/xmake-io/xmake/pull/472): Add `xmake project -k vsxmake` plugin to support call xmake from vs/msbuild
* [#487](https://github.com/xmake-io/xmake/issues/487): Support to build the selected files for the given target
* Add filelock for io
* [#513](https://github.com/xmake-io/xmake/issues/513): Support for android/termux
* [#517](https://github.com/xmake-io/xmake/issues/517): Add `add_cleanfiles` api for target
* [#537](https://github.com/xmake-io/xmake/pull/537): Add `set_runenv` api to override os/envs

### Changes

* [#257](https://github.com/xmake-io/xmake/issues/257): Lock the whole project to avoid other process to access.
* Attempt to enable /dev/shm for the os.tmpdir
* [#542](https://github.com/xmake-io/xmake/pull/542): Improve vs unicode output for link/cl
* Improve binary bitcode lua scripts in the program directory

### Bugs fixed

* [#549](https://github.com/xmake-io/xmake/issues/549): Fix error caused by the new vsDevCmd.bat of vs2019

## v2.2.7

### New features

* [#455](https://github.com/xmake-io/xmake/pull/455): support clang as cuda compiler, try `xmake f --cu=clang`
* [#440](https://github.com/xmake-io/xmake/issues/440): Add `set_rundir()` and `add_runenvs()` api for target/run
* [#443](https://github.com/xmake-io/xmake/pull/443): Add tab completion support
* Add `on_link`, `before_link` and `after_link` for rule and target
* [#190](https://github.com/xmake-io/xmake/issues/190): Add `add_rules("lex", "yacc")` rules to support lex/yacc projects

### Changes

* [#430](https://github.com/xmake-io/xmake/pull/430): Add `add_cugencodes()` api to improve set codegen for cuda
* [#432](https://github.com/xmake-io/xmake/pull/432): support deps analyze for cu file (for CUDA 10.1+)
* [#437](https://github.com/xmake-io/xmake/issues/437): Support explict git source for xmake update, `xmake update github:xmake-io/xmake#dev`
* [#438](https://github.com/xmake-io/xmake/pull/438): Support to only update scripts, `xmake update --scriptonly dev`
* [#433](https://github.com/xmake-io/xmake/issues/433): Improve cuda to support device-link
* [#442](https://github.com/xmake-io/xmake/issues/442): Improve test library

## v2.2.6

### New features

* [#380](https://github.com/xmake-io/xmake/pull/380): Add support to export compile_flags.txt
* [#382](https://github.com/xmake-io/xmake/issues/382): Simplify simple scope settings
* [#397](https://github.com/xmake-io/xmake/issues/397): Add clib package manager support
* [#404](https://github.com/xmake-io/xmake/issues/404): Support Qt for android and deploy android apk
* Add some qt empty project templates, e.g. `widgetapp_qt`, `quickapp_qt_static` and `widgetapp_qt_static`
* [#415](https://github.com/xmake-io/xmake/issues/415): Add `--cu-cxx` config arguments to `nvcc/-ccbin`
* Add `--ndk_stdcxx=y` and `--ndk_cxxstl=gnustl_static` argument options for android NDK

### Changes

* Improve remote package manager
* Improve `target:on_xxx` scripts to support to match `android|armv7-a@macosx,linux|x86_64` pattern
* Improve loadfile to optimize startup speed, decrease 98% time

### Bugs fixed

* [#400](https://github.com/xmake-io/xmake/issues/400): fix c++ languages bug for qt rules

## v2.2.5

### New features

* Add `string.serialize` and `string.deserialize` to serialize and deserialize object, function and others.
* Add `xmake g --menu`
* [#283](https://github.com/xmake-io/xmake/issues/283): Add `target:installdir()` and `set_installdir()` api for target
* [#260](https://github.com/xmake-io/xmake/issues/260): Add `add_platformdirs` api, we can define custom platforms
* [#310](https://github.com/xmake-io/xmake/issues/310): Add theme feature
* [#318](https://github.com/xmake-io/xmake/issues/318): Add `add_installfiles` api to target
* [#339](https://github.com/xmake-io/xmake/issues/339): Improve `add_requires` and `find_package` to integrate the 3rd package manager
* [#327](https://github.com/xmake-io/xmake/issues/327): Integrate with Conan package manager
* Add the builtin api `find_packages("pcre2", "zlib")` to find multiple packages
* [#320](https://github.com/xmake-io/xmake/issues/320): Add template configuration files and replace all variables before building
* [#179](https://github.com/xmake-io/xmake/issues/179): Generate CMakelist.txt file for `xmake project` plugin
* [#361](https://github.com/xmake-io/xmake/issues/361): Support vs2019 preview
* [#368](https://github.com/xmake-io/xmake/issues/368): Support `private, public, interface` to improve dependency inheritance like cmake
* [#284](https://github.com/xmake-io/xmake/issues/284): Add passing user configs description for `package()`
* [#319](https://github.com/xmake-io/xmake/issues/319): Add `add_headerfiles` to improve to set header files and directories
* [#342](https://github.com/xmake-io/xmake/issues/342): Add some builtin help functions for `includes()`, e.g. `check_cfuncs`

### Changes

* Improve to switch version and debug mode for the dependent packages
* [#264](https://github.com/xmake-io/xmake/issues/264): Support `xmake update dev` on windows
* [#293](https://github.com/xmake-io/xmake/issues/293): Add `xmake f/g --mingw=xxx` configuration option and improve to find_mingw
* [#301](https://github.com/xmake-io/xmake/issues/301): Improve precompiled header file
* [#322](https://github.com/xmake-io/xmake/issues/322): Add `option.add_features`, `option.add_cxxsnippets` and `option.add_csnippets`
* Remove some deprecated interfaces of xmake 1.x, e.g. `add_option_xxx`
* [#327](https://github.com/xmake-io/xmake/issues/327): Support conan package manager for `lib.detect.find_package`
* Improve `lib.detect.find_package` and add builtin `find_packages("zlib 1.x", "openssl", {xxx = ...})` api
* Mark `set_modes()` as deprecated, we use `add_rules("mode.debug", "mode.release")` instead of it
* [#353](https://github.com/xmake-io/xmake/issues/353): Improve `target:set`, `target:add` and add `target:del` to modify target configuration
* [#356](https://github.com/xmake-io/xmake/issues/356): Add `qt_add_static_plugins()` api to support static Qt sdk
* [#351](https://github.com/xmake-io/xmake/issues/351): Support yasm for generating vs201x project
* Improve the remote package manager.

### Bugs fixed

* Fix cannot call `set_optimize()` to set optimization flags when exists `add_rules("mode.release")`
* [#289](https://github.com/xmake-io/xmake/issues/289): Fix unarchive gzip file failed on windows
* [#296](https://github.com/xmake-io/xmake/issues/296): Fix `option.add_includedirs` for cuda
* [#321](https://github.com/xmake-io/xmake/issues/321): Fix find program bug with $PATH envirnoment

## v2.2.3

### New features

* [#233](https://github.com/xmake-io/xmake/issues/233): Support windres for mingw platform
* [#239](https://github.com/xmake-io/xmake/issues/239): Add cparser compiler support
* Add plugin manager `xmake plugin --help`
* Add `add_syslinks` api to add system libraries dependence
* Add `xmake l time xmake [--rebuild]` to record compilation time
* [#250](https://github.com/xmake-io/xmake/issues/250): Add `xmake f --vs_sdkver=10.0.15063.0` to change windows sdk version
* Add `lib.luajit.ffi` and `lib.luajit.jit` extension modules
* [#263](https://github.com/xmake-io/xmake/issues/263): Add new target kind: object to only compile object files

### Changes

* [#229](https://github.com/xmake-io/xmake/issues/229): Improve to select toolset for vcproj plugin
* Improve compilation dependences
* Support *.xz for extractor
* [#249](https://github.com/xmake-io/xmake/pull/249): revise progress formatting to space-leading three digit percentages
* [#247](https://github.com/xmake-io/xmake/pull/247): Add `-D` and `--diagnosis` instead of `--backtrace`
* [#259](https://github.com/xmake-io/xmake/issues/259): Improve on_build, on_build_file and on_xxx for target and rule
* [#269](https://github.com/xmake-io/xmake/issues/269): Clean up the temporary files at last 30 days
* Improve remote package manager
* Support to add packages with only header file
* Support to modify builtin package links, e.g. `add_packages("xxx", {links = {}})`

### Bugs fixed

* Fix state inconsistency after failed outage of installation dependency package

## v2.2.2

### New features

* Support fasm assembler
* Add `has_config`, `get_config`, and `is_config` apis
* Add `set_config` to set the default configuration
* Add `$xmake --try` to try building project using third-party buildsystem
* Add `set_enabled(false)` to disable target
* [#69](https://github.com/xmake-io/xmake/issues/69): Add remote package management, `add_requires("tbox ~1.6.1")`
* [#216](https://github.com/xmake-io/xmake/pull/216): Add windows mfc rules

### Changes

* Improve to detect Qt envirnoment and support mingw
* Add debug and release rules to the auto-generated xmake.lua
* [#178](https://github.com/xmake-io/xmake/issues/178): Modify the shared library name for mingw.
* Support case-insensitive path pattern-matching for `add_files()` on windows
* Improve to detect Qt sdk directory for `detect.sdks.find_qt`
* [#184](https://github.com/xmake-io/xmake/issues/184): Improve `lib.detect.find_package` to support vcpkg
* [#208](https://github.com/xmake-io/xmake/issues/208): Improve rpath for shared library
* [#225](https://github.com/xmake-io/xmake/issues/225): Improve to detect vs envirnoment

### Bug fixed

* [#177](https://github.com/xmake-io/xmake/issues/177): Fix the dependent target link bug
* Fix high cpu usage bug and Exit issues for `$ xmake f --menu`
* [#197](https://github.com/xmake-io/xmake/issues/197): Fix Chinese path for generating vs201x project
* Fix wdk rules bug
* [#205](https://github.com/xmake-io/xmake/pull/205): Fix targetdir,objectdir not used in vsproject

## v2.2.1

### New features

* [#158](https://github.com/xmake-io/xmake/issues/158): Support CUDA Toolkit and Compiler
* Add `set_tools` and `add_tools` apis to change the toolchains for special target
* Add builtin rules: `mode.debug`, `mode.release`, `mode.profile` and `mode.check`
* Add `is_mode`, `is_arch` and `is_plat` builtin apis in the custom scripts
* Add color256 codes
* [#160](https://github.com/xmake-io/xmake/issues/160): Support Qt compilation environment and add `qt.console`, `qt.application` rules
* Add some Qt project templates
* [#169](https://github.com/xmake-io/xmake/issues/169): Support yasm for linux, macosx and windows
* [#159](https://github.com/xmake-io/xmake/issues/159): Support WDK driver compilation environment

### Changes

* Add FAQ to the auto-generated xmake.lua
* Support android NDK >= r14
* Improve warning flags for swiftc
* [#167](https://github.com/xmake-io/xmake/issues/167): Improve custom rules
* Improve `os.files` and `os.dirs` api
* [#171](https://github.com/xmake-io/xmake/issues/171): Improve build dependence for qt rule
* Implement `make clean` for generating makefile plugin

### Bugs fixed

* Fix force to add flags bug
* [#157](https://github.com/xmake-io/xmake/issues/157): Fix generate pdb file error if it's output directory does not exists
* Fix strip all symbols bug for macho target file
* [#168](https://github.com/xmake-io/xmake/issues/168): Fix generate vs201x project bug with x86/x64 architectures

## v2.1.9

### New features

* Add `del_files()` api to delete files in the files list
* Add `rule()`, `add_rules()` api to implement the custom build rule and improve `add_files("src/*.md", {rule = "markdown"})`
* Add `os.filesize()` api
* Add `core.ui.xxx` cui components
* Add `xmake f --menu` to configure project with a menu configuration interface
* Add `set_values` api to `option()`
* Support to generate a menu configuration interface from user custom project options
* Add source file position to interpreter and search results in menu

### Changes

* Improve to configure cross-toolchains, add tool alias to support unknown tool name, e.g. `xmake f --cc=gcc@ccmips.exe`
* [#151](https://github.com/xmake-io/xmake/issues/151): Improve to build the share library for the mingw platform
* Improve to generate makefile plugin
* Improve the checking errors tips
* Improve `add_cxflags` .., force to set flags without auto checking: `add_cxflags("-DTEST", {force = true})`
* Improve `add_files`, add force block to force to set flags without auto checking: `add_files("src/*.c", {force = {cxflags = "-DTEST"}})`
* Improve to search the root project directory
* Improve to detect vs environment
* Upgrade luajit to 2.1.0-beta3
* Support to run xmake on linux (arm, arm64)
* Improve to generate vs201x project plugin

### Bugs fixed

* Fix complation dependence
* [#151](https://github.com/xmake-io/xmake/issues/151): Fix `os.nuldev()` for gcc on mingw
* [#150](https://github.com/xmake-io/xmake/issues/150): Fix the command line string limitation for `ar.exe`
* Fix `xmake f --cross` error
* Fix `os.cd` to the windows root path bug

## v2.1.8

### New features

* Add `XMAKE_LOGFILE` environment variable to dump the output info to file
* Support tinyc compiler

### Changes

* Improve support for IDE/editor plugins (e.g. vscode, sublime, intellij-idea)
* Add `.gitignore` file when creating new projects
* Improve to create template project
* Improve to detect toolchains on macosx without xcode
* Improve `set_config_header` to support `set_config_header("config", {version = "2.1.8", build = "%Y%m%d%H%M"})`

### Bugs fixed

* [#145](https://github.com/xmake-io/xmake/issues/145): Fix the current directory when running target

## v2.1.7

### New features

* Add `add_imports` to bulk import modules for the target, option and package script
* Add `xmake -y/--yes` to confirm the user input by default
* Add `xmake l package.manager.install xxx` to install software package
* Add xmake plugin for vscode editor, [xmake-vscode](https://marketplace.visualstudio.com/items?itemName=tboox.xmake-vscode#overview)
* Add `xmake macro ..` to run the last command

### Changes

* Support 24bits truecolors for `cprint()`
* Support `@loader_path` and `$ORIGIN` for `add_rpathdirs()`
* Improve `set_version("x.x.x", {build = "%Y%m%d%H%M"})` and add build version
* Move docs directory to xmake-docs repo
* Improve install and uninstall actions and support DESTDIR and PREFIX envirnoment variables
* Optimize to detect flags
* Add `COLORTERM=nocolor` to disable color output
* Remove `and_bindings` and `add_rbindings` api
* Disable to output colors code to file
* Update project templates with tbox
* Improve `lib.detect.find_program` interface
* Enable colors output for windows cmd
* Add `-w|--warning` arguments to enable the warnings output

### Bugs fixed

* Fix `set_pcxxheader` bug
* [#140](https://github.com/xmake-io/xmake/issues/140): Fix `os.tmpdir()` in fakeroot
* [#142](https://github.com/xmake-io/xmake/issues/142): Fix `os.getenv` charset bug on windows
* Fix compile error with spaces path
* Fix setenv empty value bug

## v2.1.6

### Changes

* Improve `add_files` to configure the compile option of the given files
* Inherit links and linkdirs from the dependent targets and options
* Improve `target.add_deps` and add inherit config, e.g. `add_deps("test", {inherit = false})`
* Remove the binary files of `tbox.pkg`
* Use `/Zi` instead of `/ZI` for msvc

### Bugs fixed

* Fix target deps
* Fix `target:add` and `option:add` bug
* Fix compilation and installation bug on archlinux

## v2.1.5

### New features

* [#83](https://github.com/xmake-io/xmake/issues/83): Add `add_csnippet` and `add_cxxsnippet` into `option` for detecting some compiler features.
* [#83](https://github.com/xmake-io/xmake/issues/83): Add user extension modules to detect program, libraries and files.
* Add `find_program`, `find_file`, `find_library`, `find_tool` and `find_package` module interfaces.
* Add `net.*` and `devel.*` extension modules
* Add `val()` api to get the value of builtin-variable, e.g. `val("host")`, `val("env PATH")`, `val("shell echo hello")` and `val("reg HKEY_LOCAL_MACHINE\\XX;Value")`
* Support to compile the microsoft resource file (.rc)
* Add `has_flags`, `features` and `has_features` for detect module interfaces.
* Add `option.on_check`, `option.after_check` and `option.before_check` api
* Add `target.on_load` api
* [#132](https://github.com/xmake-io/xmake/issues/132): Add `add_frameworkdirs` api
* Add `lib.detect.has_xxx` and `lib.detect.find_xxx` apis.
* Add `add_moduledirs` api
* Add `includes` api instead of `add_subdirs` and `add_subfiles`
* [#133](https://github.com/xmake-io/xmake/issues/133): Improve the project plugin to generate `compile_commands.json` by run  `xmake project -k compile_commands`
* Add `set_pcheader` and `set_pcxxheader` to support the precompiled header, support gcc, clang, msvc
* Add `xmake f -p cross` platform and support the custom platform

### Changes

* [#87](https://github.com/xmake-io/xmake/issues/87): Add includes and links from target deps automatically
* Improve `import` to load user extension and global modules
* [#93](https://github.com/xmake-io/xmake/pull/93): Improve `xmake lua` to run a single line command
* Improve to print gcc error and warning info
* Improve `print` interface to dump table
* [#111](https://github.com/xmake-io/xmake/issues/111): Add `--root` common option to allow run xmake command as root
* [#113](https://github.com/xmake-io/xmake/pull/113): Privilege manage when running as root, store the root privilege and degrade.
* Improve `xxx_script` in `xmake.lua` to support pattern match, e.g. `on_build("iphoneos|arm*", function (target) end)`
* improve builtin-variables to support to get the value envirnoment and registry
* Improve to detect vstudio sdk and cross toolchains envirnoment
* [#71](https://github.com/xmake-io/xmake/issues/71): Improve to detect compiler and linker from env vars
* Improve the option detection (cache and multi-jobs) and increase 70% speed
* [#129](https://github.com/xmake-io/xmake/issues/129): Check link deps and cache the target file
* Support `*.asm` source files for vs201x project plugin
* Mark `add_bindings` and `add_rbindings` as deprecated
* Optimize `xmake rebuild` speed on windows
* Move `core.project.task` to `core.base.task`
* Move `echo` and `app2ipa` plugins to [xmake-plugins](https://github.com/xmake-io/xmake-plugins) repo.
* Add new api `set_config_header("config.h", {prefix = ""})` instead of `set_config_h` and `set_config_h_prefix`

### Bugs fixed

* Fix `try-catch-finally`
* Fix interpreter bug when parsing multi-level subdirs
* [#115](https://github.com/xmake-io/xmake/pull/115): Fix the path problem of the install script `get.sh`
* Fix cache bug for import()

## v2.1.4

### New features

* [#68](https://github.com/xmake-io/xmake/issues/68): Add `$(programdir)` and `$(xmake)` builtin variables
* add `is_host` api to get current host operating system
* [#79](https://github.com/xmake-io/xmake/issues/79): Improve `xmake lua` to run interactive commands, read-eval-print (REPL)

### Changes

* Modify option menu color.
* [#71](https://github.com/xmake-io/xmake/issues/71): Improve to map optimization flags for cl.exe
* [#73](https://github.com/xmake-io/xmake/issues/73): Attempt to get executable path as xmake's program directory
* Improve the scope of `xmake.lua` in `add_subdirs` and use independent sub-scope to avoid dirty scope
* [#78](https://github.com/xmake-io/xmake/pull/78): Get terminal size in runtime and soft-wrap the help printing
* Avoid generate `.xmake` directory if be not in project

### Bugs fixed

* [#67](https://github.com/xmake-io/xmake/issues/67): Fix `sudo make install` permission problem
* [#70](https://github.com/xmake-io/xmake/issues/70): Fix check android compiler error
* Fix temporary file path conflict
* Fix `os.host` and `os.arch` interfaces
* Fix interpreter bug for loading root api
* [#77](https://github.com/xmake-io/xmake/pull/77): fix `cprint` no color reset eol

## v2.1.3

### New features

* [#65](https://github.com/xmake-io/xmake/pull/65): Add `set_default` api for target to modify default build and install behavior
* Allows to run `xmake` command in project subdirectories, it will find the project root directory automatically
* Add `add_rpathdirs` for target and option

### Changes

* [#61](https://github.com/xmake-io/xmake/pull/61): Provide safer `xmake install` and `xmake uninstall` task with administrator permission
* Provide `rpm`, `deb` and `osxpkg` install package
* [#63](https://github.com/xmake-io/xmake/pull/63): More safer build and install xmake
* [#61](https://github.com/xmake-io/xmake/pull/61): Check run command as root
* Improve check toolchains and implement delay checking
* Add user tips when scanning and generating `xmake.lua` automatically

### Bugs fixed

* Fix error tips for checking xmake min version
* [#60](https://github.com/xmake-io/xmake/issues/60): Fix self-build for macosx and windows
* [#64](https://github.com/xmake-io/xmake/issues/64): Fix compile android `armv8-a` error
* [#50](https://github.com/xmake-io/xmake/issues/50): Fix only position independent executables issue for android program

## v2.1.2

### New features

* Add aur package script and support to install xmake from yaourt
* Add [set_basename](#http://xmake.io/#/manual?id=targetset_basename) api for target

### Changes

* Support vs2017
* Support compile rust for android
* Improve vs201x project plugin and support multi-modes compilation.

### Bugs fixed

* Fix cannot find android sdk header files
* Fix checking option bug
* [#57](https://github.com/xmake-io/xmake/issues/57): Fix code files mode to 0644

## v2.1.1

### New features

* Add `--links`, `--linkdirs` and `--includedirs` configure arguments
* Add app2ipa plugin
* Add dictionary syntax style for `xmake.lua`
* Provide smart scanning and building mode without `xmake.lua`
* Add `set_xmakever` api for `xmake.lua`
* Add `add_frameworks` api for `objc` and `swift`
* Support multi-languages extension and add `golang`, `dlang` and `rust` language
* Add optional `target_end`, `option_end`, `task_end` apis for scope
* Add `golang`, `dlang` and `rust` project templates

### Changes

* Support vs2017 for the project plugin
* Improve gcc error and warning tips
* Improve lanuage module
* Improve print interface, support lua print and format output
* Automatically scan project files and generate it for building if xmake.lua not exists
* Modify license to Apache License 2.0
* Remove some binary tools
* Remove install.bat script and provide nsis install package
* Rewrite [documents](http://www.xmake.io/#/home/) using [docute](https://github.com/egoist/docute)
* Improve `os.run`, `os.exec`, `os.cp`, `os.mv` and `os.rm` interfaces and support wildcard pattern
* Optimize the output info and add `-q|--quiet` option
* Improve makefile generator, uses $(XX) variables for tools and flags

### Bugs fixed

* [#41](https://github.com/waruqi/xmake/issues/41): Fix checker bug for windows
* [#43](https://github.com/waruqi/xmake/issues/43): Avoid to generate unnecessary .xmake directory
* Add c++ stl search directories for android
* Fix compile error for rhel 5.10
* Fix `os.iorun` bug

## v2.0.5

### New features

* Add some interpreter builtin-modules
* Support ml64 assembler for windows x64

### Changes

* Improve ipairs and pairs interfaces and support filter
* Add filters for generating vs201x project
* Remove `core/tools` (msys toolchains) and uses xmake to compile core sources on windows
* Remove `xmake/packages` for templates

### Bugs fixed

* Fix `-def:xxx.def` flags failed for msvc
* Fix ml.exe assembler script
* Fix options linking order bug

## v2.0.4

### New features

* Add native shell support for `xmake.lua`. e.g. `add_ldflags("$(shell pkg-config --libs sqlite3)")`
* Enable pdb symbol files for windows
* Add debugger support on windows (vsjitdebugger, ollydbg, windbg ... )
* Add `getenv` interface for the global scope of `xmake.lua`
* Add plugin for generating vstudio project file (vs2002 - vs2015)
* Add `set_default` api for option

### Changes

* Improve builtin-variable format
* Support option for string type

### Bugs fixed

* Fix check ld failed without g++ on linux
* Fix compile `*.cxx` files failed

## v2.0.3

### New features

* Add check includes dependence automatically
* Add print colors
* Add debugger support, e.g. `xmake run -d program ...`

### Changes

* Improve the interfaces of run shell
* Upgrade luajit to v2.0.4
* Improve to generate makefile plugin
* Optimizate the multitasking compiling speed

### Bugs fixed

* Fix install directory bug
* Fix the root directory error for `import` interface
* Fix check visual stdio error on windows

## v2.0.2

### Changes

* Change install and uninstall actions
* Update templates
* Improve to check function

### Bugs fixed

* [#7](https://github.com/waruqi/xmake/issues/7): Fix create project bug with '[targetname]'
* [#9](https://github.com/waruqi/xmake/issues/9): Support clang with c++11
* Fix api scope leaks bug
* Fix path bug for windows
* Fix check function bug
* Fix check toolchains failed
* Fix compile failed for android on windows

## v2.0.1

### New features

* Add task api for running custom tasks
* Add plugin expansion and provide some builtin plugins
* Add export ide project plugin(e.g. makefile and will support to export other projects for vs, xcode in feature)
* Add demo plugin for printing 'hello xmake'
* Add make doxygen documents plugin
* Add macro script plugin
* Add more modules for developing plugin
* Add exception using try/catch and simplify grammar for plugin script
* Add option bindings
* Show progress when building

### Changes

* Rewrite interpreter for xmake.lua
* More strict syntax detection mechanism
* More strict api scope for xmake.lua
* Simplify template development
* Extend platforms, tools, templates and actions fastly
* Simplify api and support import modules
* Remove dependence for gnu make/nmake, no longer need makefile
* Optimize speed for building and faster x4 than v1.0.4
* Optimize automatic detection
* Modify some api name, but be compatible with the old version
* Optimize merging static library
* Simplify cross compilation using argument `--sdk=xxx`
* Simplify boolean option for command line, e.g. `xmake config --xxx=[y|n|yes|no|true|false]`
* Merge iphoneos and iphonesimulator platforms
* Merge watchos and watchsimulator platformss

### Bugs fixed

* [#3](https://github.com/waruqi/xmake/issues/3): ArchLinux compilation failed
* [#4](https://github.com/waruqi/xmake/issues/4): Install failed for windows
* Fix envirnoment variable bug for windows

## v1.0.4

### New features

* Support windows assembler
* Add some project templates
* Support swift codes
* Add -v argument for outputing more verbose info
* Add apple platforms：watchos, watchsimulator
* Add architecture x64, amd64, x86_amd64 for windows
* Support switch static and share library
* Add `-j/--jobs` argument for supporting multi-jobs

### Changes

* Improve `add_files` api and support to add `*.o/obj/a/lib` files for merging static library and object files
* Optimize installation and remove some binary files

### Bugs fixed

* [#1](https://github.com/waruqi/xmake/issues/4): Install failed for win7
* Fix checking toolchains bug
* Fix install script bug
* Fix install bug for linux x86_64

## v1.0.3

### New features

* Add `set_runscript` api and support custom action
* Add import api and support import modules in xmake.lua, e.g. os, path, utils ...
* Add new architecture: arm64-v8a for android

### Bugs fixed

* Fix api bug for `set_installscript`
* Fix install bug for windows `x86_64`
* Fix relative path bug

<h1 id="中文"></h1>

# 更新日志

## master (开发中)

## v2.3.8

### 新特性

* [#955](https://github.com/xmake-io/xmake/issues/955): 添加 Zig 空工程模板
* [#956](https://github.com/xmake-io/xmake/issues/956): 添加 Wasm 编译平台，并且支持 Qt/Wasm SDK
* 升级luajit到v2.1最新分支版本，并且支持mips64上运行xmake
* [#972](https://github.com/xmake-io/xmake/issues/972): 添加`depend.on_changed()`去简化依赖文件的处理
* [#981](https://github.com/xmake-io/xmake/issues/981): 添加`set_fpmodels()`去抽象化设置math/float-point编译优化模式
* [#980](https://github.com/xmake-io/xmake/issues/980): 添加对 Intel C/C++ 和 Fortran 编译器的全平台支持
* [#986](https://github.com/xmake-io/xmake/issues/986): 对16.8以上msvc编译器增加 `c11`/`c17` 支持
* [#979](https://github.com/xmake-io/xmake/issues/979): 添加对OpenMP的跨平台抽象配置。`add_rules("c++.openmp")`

### 改进

* [#958](https://github.com/xmake-io/xmake/issues/958): 改进mingw平台，增加对 llvm-mingw 工具链的支持，以及 arm64/arm 架构的支持
* 增加 `add_requires("zlib~xxx")` 模式使得能够支持同时安装带有多种配置的同一个包，作为独立包存在
* [#977](https://github.com/xmake-io/xmake/issues/977): 改进 find_mingw 在 windows 上的探测
* [#978](https://github.com/xmake-io/xmake/issues/978): 改进工具链的flags顺序
* 改进XCode工具链，支持macOS/arm64

### Bugs修复

* [#951](https://github.com/xmake-io/xmake/issues/951): 修复 emcc (WebAssembly) 工具链在windows上的支持
* [#992](https://github.com/xmake-io/xmake/issues/992): 修复文件锁偶尔打开失败问题

## v2.3.7

### 新特性

* [#2941](https://github.com/microsoft/winget-pkgs/pull/2941): 支持通过 winget 来安装 xmake
* 添加 xmake-tinyc 安装包，内置tinyc编译器，支持windows上无msvc环境也可直接编译c代码
* 添加 tinyc 编译工具链
* 添加 emcc (emscripten) 编译工具链去编译 asm.js 和 WebAssembly
* [#947](https://github.com/xmake-io/xmake/issues/947): 通过 `xmake g --network=private` 配置设置私有网络模式，避免远程依赖包下载访问外网导致编译失败

### 改进

* [#907](https://github.com/xmake-io/xmake/issues/907): 改进msvc的链接器优化选项，生成更小的可执行程序
* 改进ubuntu下Qt环境的支持
* [#918](https://github.com/xmake-io/xmake/pull/918): 改进cuda11工具链的支持
* 改进Qt支持，对通过 ubuntu/apt 安装的Qt sdk也进行了探测支持，并且检测效率也优化了下
* 改进 CMake 工程文件生成器
* [#931](https://github.com/xmake-io/xmake/issues/931): 改进导出包，支持导出所有依赖包
* [#930](https://github.com/xmake-io/xmake/issues/930): 如果私有包定义没有版本定义，支持直接尝试下载包
* [#927](https://github.com/xmake-io/xmake/issues/927): 改进android ndk，支持arm/thumb指令模式切换
* 改进 trybuild/cmake 支持 Android/Mingw/iPhoneOS/WatchOS 工具链

### Bugs修复

* [#903](https://github.com/xmake-io/xmake/issues/903): 修复vcpkg包安装失败问题
* [#912](https://github.com/xmake-io/xmake/issues/912): 修复自定义工具链
* [#914](https://github.com/xmake-io/xmake/issues/914): 修复部分aarch64设备上运行lua出现bad light userdata pointer问题

## v2.3.6

### 新特性

* 添加xcode工程生成器插件，`xmake project -k cmake` （当前采用cmake生成）
* [#870](https://github.com/xmake-io/xmake/issues/870): 支持gfortran编译器
* [#887](https://github.com/xmake-io/xmake/pull/887): 支持zig编译器
* [#893](https://github.com/xmake-io/xmake/issues/893): 添加json模块
* [#898](https://github.com/xmake-io/xmake/issues/898): 改进golang项目构建，支持交叉编译
* [#275](https://github.com/xmake-io/xmake/issues/275): 支持go包管理器去集成第三方go依赖包
* [#581](https://github.com/xmake-io/xmake/issues/581): 支持dub包管理器去集成第三方dlang依赖包

### 改进

* [#868](https://github.com/xmake-io/xmake/issues/868): 支持新的cl.exe的头文件依赖输出文件格式，`/sourceDependencies xxx.json`
* [#902](https://github.com/xmake-io/xmake/issues/902): 改进交叉编译工具链

## v2.3.5

### 新特性

* 添加`xmake show -l envs`去显示xmake内置的环境变量列表
* [#861](https://github.com/xmake-io/xmake/issues/861): 支持从指定目录搜索本地包去直接安装远程依赖包
* [#854](https://github.com/xmake-io/xmake/issues/854): 针对wget, curl和git支持全局代理设置

### 改进

* [#828](https://github.com/xmake-io/xmake/issues/828): 针对protobuf规则增加导入子目录proto文件支持
* [#835](https://github.com/xmake-io/xmake/issues/835): 改进mode.minsizerel模式，针对msvc增加/GL支持，进一步优化目标程序大小
* [#828](https://github.com/xmake-io/xmake/issues/828): protobuf规则支持import多级子目录
* [#838](https://github.com/xmake-io/xmake/issues/838#issuecomment-643570920): 支持完全重写内置的构建规则，`add_files("src/*.c", {rules = {"xx", override = true}})`
* [#847](https://github.com/xmake-io/xmake/issues/847): 支持rc文件的头文件依赖解析
* 改进msvc工具链，去除全局环境变量的依赖
* [#857](https://github.com/xmake-io/xmake/pull/857): 改进`set_toolchains()`支持交叉编译的时候，特定target可以切换到host工具链同时编译

### Bugs修复

* 修复进度字符显示
* [#829](https://github.com/xmake-io/xmake/issues/829): 修复由于macOS大小写不敏感系统导致的sysroot无效路径问题
* [#832](https://github.com/xmake-io/xmake/issues/832): 修复find_packages在debug模式下找不到的问题

## v2.3.4

### 新特性

* [#630](https://github.com/xmake-io/xmake/issues/630): 支持*BSD系统，例如：FreeBSD, ..
* 添加wprint接口去显示警告信息
* [#784](https://github.com/xmake-io/xmake/issues/784): 添加`set_policy()`去设置修改一些内置的策略，比如：禁用自动flags检测和映射
* [#780](https://github.com/xmake-io/xmake/issues/780): 针对target添加set_toolchains/set_toolsets实现更完善的工具链设置，并且实现platform和toolchains分离
* [#798](https://github.com/xmake-io/xmake/issues/798): 添加`xmake show`插件去显示xmake内置的各种信息
* [#797](https://github.com/xmake-io/xmake/issues/797): 添加ninja主题风格，显示ninja风格的构建进度条，`xmake g --theme=ninja`
* [#816](https://github.com/xmake-io/xmake/issues/816): 添加mode.releasedbg和mode.minsizerel编译模式规则
* [#819](https://github.com/xmake-io/xmake/issues/819): 支持ansi/vt100终端字符控制

### 改进

* [#771](https://github.com/xmake-io/xmake/issues/771): 检测includedirs,linkdirs和frameworkdirs的输入有效性
* [#774](https://github.com/xmake-io/xmake/issues/774): `xmake f --menu`可视化配置菜单支持窗口大小Resize调整
* [#782](https://github.com/xmake-io/xmake/issues/782): 添加add_cxflags等配置flags自动检测失败提示
* [#808](https://github.com/xmake-io/xmake/issues/808): 生成cmakelists插件增加对add_frameworks的支持
* [#820](https://github.com/xmake-io/xmake/issues/820): 支持独立的工作目录和构建目录，保持项目目录完全干净

### Bugs修复

* [#786](https://github.com/xmake-io/xmake/issues/786): 修复头文件依赖检测
* [#810](https://github.com/xmake-io/xmake/issues/810): 修复linux下gcc strip debug符号问题

## v2.3.3

### 新特性

* [#727](https://github.com/xmake-io/xmake/issues/727): 支持为android, ios程序生成.so/.dSYM符号文件
* [#687](https://github.com/xmake-io/xmake/issues/687): 支持编译生成objc/bundle程序
* [#743](https://github.com/xmake-io/xmake/issues/743): 支持编译生成objc/framework程序
* 支持编译bundle, framework程序，以及mac, ios应用程序，并新增一些工程模板
* 支持对ios应用程序打包生成ipa文件，以及代码签名支持
* 增加一些ipa打包、安装、重签名等辅助工具
* 添加xmake.cli规则来支持开发带有xmake/core引擎的lua扩展程序

### 改进

* [#750](https://github.com/xmake-io/xmake/issues/750): 改进qt.widgetapp规则，支持qt私有槽
* 改进Qt/android的apk部署，并且支持Qt5.14.0新版本sdk

## v2.3.2

### 新特性

* 添加powershell色彩主题用于powershell终端下背景色显示
* 添加`xmake --dry-run -v`命令去空运行构建，仅仅为了查看详细的构建命令
* [#712](https://github.com/xmake-io/xmake/issues/712): 添加sdcc平台，并且支持sdcc编译器

### 改进

* [#589](https://github.com/xmake-io/xmake/issues/589): 改进优化构建速度，支持跨目标间并行编译和link，编译速度和ninja基本持平
* 改进ninja/cmake工程文件生成器插件
* [#728](https://github.com/xmake-io/xmake/issues/728): 改进os.cp支持保留源目录结构层级的递归复制
* [#732](https://github.com/xmake-io/xmake/issues/732): 改进find_package支持查找homebrew/cmake安装的包
* [#695](https://github.com/xmake-io/xmake/issues/695): 改进采用android ndk最新的abi命名

### Bugs修复

* 修复windows下link error显示问题
* [#718](https://github.com/xmake-io/xmake/issues/718): 修复依赖包下载在多镜像时一定概率缓存失效问题
* [#722](https://github.com/xmake-io/xmake/issues/722): 修复无效的包依赖导致安装死循环问题
* [#719](https://github.com/xmake-io/xmake/issues/719): 修复windows下主进程收到ctrlc后，.bat子进程没能立即退出的问题
* [#720](https://github.com/xmake-io/xmake/issues/720): 修复compile_commands生成器的路径转义问题

## v2.3.1

### 新特性

* [#675](https://github.com/xmake-io/xmake/issues/675): 支持通过设置强制将`*.c`作为c++代码编译, `add_files("*.c", {sourcekind = "cxx"})`。
* [#681](https://github.com/xmake-io/xmake/issues/681): 支持在msys/cygwin上编译xmake，以及添加msys/cygwin编译平台
* 添加socket/pipe模块，并且支持在协程中同时调度process/socket/pipe
* [#192](https://github.com/xmake-io/xmake/issues/192): 尝试构建带有第三方构建系统的项目，还支持autotools项目的交叉编译
* 启用gcc/clang的编译错误色彩高亮输出
* [#588](https://github.com/xmake-io/xmake/issues/588): 改进工程生成插件`xmake project -k ninja`，增加对build.ninja生成支持

### 改进

* [#665](https://github.com/xmake-io/xmake/issues/665): 支持 *nix style 的参数输入，感谢[@OpportunityLiu](https://github.com/OpportunityLiu)的贡献
* [#673](https://github.com/xmake-io/xmake/pull/673): 改进tab命令补全，增加对参数values的补全支持
* [#680](https://github.com/xmake-io/xmake/issues/680): 优化get.sh安装脚本，添加国内镜像源，加速下载
* 改进process调度器
* [#651](https://github.com/xmake-io/xmake/issues/651): 改进os/io模块系统操作错误提示

### Bugs修复

* 修复增量编译检测依赖文件的一些问题
* 修复log输出导致xmake-vscode插件解析编译错误信息失败问题
* [#684](https://github.com/xmake-io/xmake/issues/684): 修复windows下android ndk的一些linker错误

## v2.2.9

### 新特性

* [#569](https://github.com/xmake-io/xmake/pull/569): 增加对c++模块的实验性支持
* 添加`xmake project -k xmakefile`生成器
* [620](https://github.com/xmake-io/xmake/issues/620): 添加全局`~/.xmakerc.lua`配置文件，对所有本地工程生效.
* [593](https://github.com/xmake-io/xmake/pull/593): 添加`core.base.socket`模块，为下一步远程编译和分布式编译做准备。

### 改进

* [#563](https://github.com/xmake-io/xmake/pull/563): 重构构建逻辑，将特定语言的构建抽离到独立的rules中去
* [#570](https://github.com/xmake-io/xmake/issues/570): 改进Qt构建，将`qt.application`拆分成`qt.widgetapp`和`qt.quickapp`两个构建规则
* [#576](https://github.com/xmake-io/xmake/issues/576): 使用`set_toolchain`替代`add_tools`和`set_tools`，解决老接口使用歧义，提供更加易理解的设置方式
* 改进`xmake create`创建模板工程
* [#589](https://github.com/xmake-io/xmake/issues/589): 改进默认的构建任务数，充分利用cpu core来提速整体编译速度
* [#598](https://github.com/xmake-io/xmake/issues/598): 改进`find_package`支持在macOS上对.tbd系统库文件的查找
* [#615](https://github.com/xmake-io/xmake/issues/615): 支持安装和使用其他arch和ios的conan包
* [#629](https://github.com/xmake-io/xmake/issues/629): 改进hash.uuid并且实现uuid v4
* [#639](https://github.com/xmake-io/xmake/issues/639): 改进参数解析器支持`-jN`风格传参

### Bugs修复

* [#567](https://github.com/xmake-io/xmake/issues/567): 修复序列化对象时候出现的内存溢出问题
* [#566](https://github.com/xmake-io/xmake/issues/566): 修复安装远程依赖的链接顺序问题
* [#565](https://github.com/xmake-io/xmake/issues/565): 修复vcpkg包的运行PATH设置问题
* [#597](https://github.com/xmake-io/xmake/issues/597): 修复xmake require安装包时间过长问题
* [#634](https://github.com/xmake-io/xmake/issues/634): 修复mode.coverage构建规则，并且改进flags检测

## v2.2.8

### 新特性

* 添加protobuf c/c++构建规则
* [#468](https://github.com/xmake-io/xmake/pull/468): 添加对 Windows 的 UTF-8 支持
* [#472](https://github.com/xmake-io/xmake/pull/472): 添加`xmake project -k vsxmake`去更好的支持vs工程的生成，内部直接调用xmake来编译
* [#487](https://github.com/xmake-io/xmake/issues/487): 通过`xmake --files="src/*.c"`支持指定一批文件进行编译。
* 针对io模块增加文件锁接口
* [#513](https://github.com/xmake-io/xmake/issues/513): 增加对android/termux终端的支持，可在android设备上执行xmake来构建项目
* [#517](https://github.com/xmake-io/xmake/issues/517): 为target增加`add_cleanfiles`接口，实现快速定制化清理文件
* [#537](https://github.com/xmake-io/xmake/pull/537): 添加`set_runenv`接口去覆盖写入系统envs

### 改进

* [#257](https://github.com/xmake-io/xmake/issues/257): 锁定当前正在构建的工程，避免其他xmake进程同时对其操作
* 尝试采用/dev/shm作为os.tmpdir去改善构建过程中临时文件的读写效率
* [#542](https://github.com/xmake-io/xmake/pull/542): 改进vs系列工具链的unicode输出问题
* 对于安装的lua脚本，启用lua字节码存储，减少安装包大小（<2.4M），提高运行加载效率。

### Bugs修复

* [#549](https://github.com/xmake-io/xmake/issues/549): 修复新版vs2019下检测环境会卡死的问题

## v2.2.7

### 新特性

* [#455](https://github.com/xmake-io/xmake/pull/455): 支持使用 clang 作为 cuda 编译器，`xmake f --cu=clang`
* [#440](https://github.com/xmake-io/xmake/issues/440): 为target/run添加`set_rundir()`和`add_runenvs()`接口设置
* [#443](https://github.com/xmake-io/xmake/pull/443): 添加命令行tab自动完成支持
* 为rule/target添加`on_link`,`before_link`和`after_link`阶段自定义脚本支持
* [#190](https://github.com/xmake-io/xmake/issues/190): 添加`add_rules("lex", "yacc")`规则去支持lex/yacc项目

### 改进

* [#430](https://github.com/xmake-io/xmake/pull/430): 添加`add_cugencodes()`api为cuda改进设置codegen
* [#432](https://github.com/xmake-io/xmake/pull/432): 针对cuda编译支持依赖分析检测（仅支持 CUDA 10.1+）
* [#437](https://github.com/xmake-io/xmake/issues/437): 支持指定更新源，`xmake update github:xmake-io/xmake#dev`
* [#438](https://github.com/xmake-io/xmake/pull/438): 支持仅更新脚本，`xmake update --scriptonly dev`
* [#433](https://github.com/xmake-io/xmake/issues/433): 改进cuda构建支持device-link设备代码链接
* [#442](https://github.com/xmake-io/xmake/issues/442): 改进tests测试框架

## v2.2.6

### 新特性

* [#380](https://github.com/xmake-io/xmake/pull/380): 添加导出compile_flags.txt
* [#382](https://github.com/xmake-io/xmake/issues/382): 简化域设置语法
* [#397](https://github.com/xmake-io/xmake/issues/397): 添加clib包集成支持
* [#404](https://github.com/xmake-io/xmake/issues/404): 增加Qt/Android编译支持，并且支持android apk生成和部署
* 添加一些Qt空工程模板，例如：`widgetapp_qt`, `quickapp_qt_static` and `widgetapp_qt_static`
* [#415](https://github.com/xmake-io/xmake/issues/415): 添加`--cu-cxx`配置参数到`nvcc/-ccbin`
* 为Android NDK添加`--ndk_stdcxx=y`和`--ndk_cxxstl=gnustl_static`参数选项

### 改进

* 改进远程依赖包管理，丰富包仓库
* 改进`target:on_xxx`自定义脚本，去支持匹配`android|armv7-a@macosx,linux|x86_64`模式
* 改进loadfile，优化启动速度，windows上启动xmake时间提速98%

### Bugs修复

* [#400](https://github.com/xmake-io/xmake/issues/400): 修复qt项目c++语言标准设置无效问题

## v2.2.5

### 新特性

* 添加`string.serialize`和`string.deserialize`去序列化，反序列化对象，函数以及其他类型
* 添加`xmake g --menu`去图形化配置全局选项
* [#283](https://github.com/xmake-io/xmake/issues/283): 添加`target:installdir()`和`set_installdir()`接口
* [#260](https://github.com/xmake-io/xmake/issues/260): 添加`add_platformdirs`接口，用户现在可以自定义扩展编译平台
* [#310](https://github.com/xmake-io/xmake/issues/310): 新增主题设置支持，用户可随意切换和扩展主题样式
* [#318](https://github.com/xmake-io/xmake/issues/318): 添加`add_installfiles`接口到target去自定义安装文件
* [#339](https://github.com/xmake-io/xmake/issues/339): 改进`add_requires`和`find_package`使其支持对第三方包管理的集成支持
* [#327](https://github.com/xmake-io/xmake/issues/327): 实现对conan包管理的集成支持
* 添加内置API `find_packages("pcre2", "zlib")`去同时查找多个依赖包，不需要通过import导入即可直接调用
* [#320](https://github.com/xmake-io/xmake/issues/320): 添加模板配置文件相关接口，`add_configfiles`和`set_configvar`
* [#179](https://github.com/xmake-io/xmake/issues/179): 扩展`xmake project`插件，新增CMakelist.txt生成支持
* [#361](https://github.com/xmake-io/xmake/issues/361): 增加对vs2019 preview的支持
* [#368](https://github.com/xmake-io/xmake/issues/368): 支持`private, public, interface`属性设置去继承target配置
* [#284](https://github.com/xmake-io/xmake/issues/284): 通过`add_configs()`添加和传递用户自定义配置到`package()`
* [#319](https://github.com/xmake-io/xmake/issues/319): 添加`add_headerfiles`接口去改进头文件的设置
* [#342](https://github.com/xmake-io/xmake/issues/342): 为`includes()`添加一些内置的辅助函数，例如：`check_cfuncs`

### 改进

* 针对远程依赖包，改进版本和调试模式切换
* [#264](https://github.com/xmake-io/xmake/issues/264): 支持在windows上更新dev/master版本，`xmake update dev`
* [#293](https://github.com/xmake-io/xmake/issues/293): 添加`xmake f/g --mingw=xxx` 配置选线，并且改进find_mingw检测
* [#301](https://github.com/xmake-io/xmake/issues/301): 改进编译预处理头文件以及依赖头文件生成，编译速度提升30%
* [#322](https://github.com/xmake-io/xmake/issues/322): 添加`option.add_features`, `option.add_cxxsnippets` 和 `option.add_csnippets`
* 移除xmake 1.x的一些废弃接口, 例如：`add_option_xxx`
* [#327](https://github.com/xmake-io/xmake/issues/327): 改进`lib.detect.find_package`增加对conan包管理器的支持
* 改进`lib.detect.find_package`并且添加内建的`find_packages("zlib 1.x", "openssl", {xxx = ...})`接口
* 标记`set_modes()`作为废弃接口， 我们使用`add_rules("mode.debug", "mode.release")`来替代它
* [#353](https://github.com/xmake-io/xmake/issues/353): 改进`target:set`, `target:add` 并且添加`target:del`去动态修改target配置
* [#356](https://github.com/xmake-io/xmake/issues/356): 添加`qt_add_static_plugins()`接口去支持静态Qt sdk
* [#351](https://github.com/xmake-io/xmake/issues/351): 生成vs201x插件增加对yasm的支持
* 重构改进整个远程依赖包管理器，更加快速、稳定、可靠，并提供更多的常用包

### Bugs修复

* 修复无法通过 `set_optimize()` 设置优化选项，如果存在`add_rules("mode.release")`的情况下
* [#289](https://github.com/xmake-io/xmake/issues/289): 修复在windows下解压gzip文件失败
* [#296](https://github.com/xmake-io/xmake/issues/296): 修复`option.add_includedirs`对cuda编译不生效
* [#321](https://github.com/xmake-io/xmake/issues/321): 修复PATH环境改动后查找工具不对问题

## v2.2.3

### 新特性

* [#233](https://github.com/xmake-io/xmake/issues/233): 对mingw平台增加windres的支持
* [#239](https://github.com/xmake-io/xmake/issues/239): 添加cparser编译器支持
* 添加插件管理器，`xmake plugin --help`
* 添加`add_syslinks`接口去设置系统库依赖，分离与`add_links`添加的库依赖之间的链接顺序
* 添加 `xmake l time xmake [--rebuild]` 去记录编译耗时
* [#250](https://github.com/xmake-io/xmake/issues/250): 添加`xmake f --vs_sdkver=10.0.15063.0`去改变windows sdk版本
* 添加`lib.luajit.ffi`和`lib.luajit.jit`扩展模块
* [#263](https://github.com/xmake-io/xmake/issues/263): 添加object目标类型，仅仅用于编译生成object对象文件
* [#269](https://github.com/xmake-io/xmake/issues/269): 每天第一次构建时候后台进程自动清理最近30天的临时文件

### 改进

* [#229](https://github.com/xmake-io/xmake/issues/229): 改进vs toolset选择已经vcproj工程文件生成
* 改进编译依赖，对源文件列表的改动进行依赖判断
* 支持解压*.xz文件
* [#249](https://github.com/xmake-io/xmake/pull/249): 改进编译进度信息显示格式
* [#247](https://github.com/xmake-io/xmake/pull/247): 添加`-D`和`--diagnosis`去替换`--backtrace`，改进诊断信息显示
* [#259](https://github.com/xmake-io/xmake/issues/259): 改进 on_build, on_build_file 和 on_xxx 等接口
* 改进远程包管理器，更加方便的包依赖配置切换
* 支持only头文件依赖包的安装
* 支持对包内置links的手动调整，`add_packages("xxx", {links = {}})`

### Bugs修复

* 修复安装依赖包失败中断后的状态不一致性问题

## v2.2.2

### 新特性

* 新增fasm汇编器支持
* 添加`has_config`, `get_config`和`is_config`接口去快速判断option和配置值
* 添加`set_config`接口去设置默认配置
* 添加`$xmake --try`去尝试构建工程
* 添加`set_enabled(false)`去显示的禁用target
* [#69](https://github.com/xmake-io/xmake/issues/69): 添加远程依赖包管理, `add_requires("tbox ~1.6.1")`
* [#216](https://github.com/xmake-io/xmake/pull/216): 添加windows mfc编译规则

### 改进

* 改进Qt编译编译环境探测，增加对mingw sdk的支持
* 在自动扫描生成的xmake.lua中增加默认debug/release规则
* [#178](https://github.com/xmake-io/xmake/issues/178): 修改mingw平台下的目标名
* 对于`add_files()`在windows上支持大小写不敏感路径模式匹配
* 改进`detect.sdks.find_qt`对于Qt根目录的探测
* [#184](https://github.com/xmake-io/xmake/issues/184): 改进`lib.detect.find_package`支持vcpkg
* [#208](https://github.com/xmake-io/xmake/issues/208): 改进rpath对动态库的支持
* [#225](https://github.com/xmake-io/xmake/issues/225): 改进vs环境探测

### Bugs修复

* [#177](https://github.com/xmake-io/xmake/issues/177): 修复被依赖的动态库target，如果设置了basename后链接失败问题
* 修复`$ xmake f --menu`中Exit问题以及cpu过高问题
* [#197](https://github.com/xmake-io/xmake/issues/197): 修复生成的vs201x工程文件带有中文路径乱码问题
* 修复WDK规则编译生成的驱动在Win7下运行蓝屏问题
* [#205](https://github.com/xmake-io/xmake/pull/205): 修复vcproj工程生成targetdir, objectdir路径设置不匹配问题

## v2.2.1

### 新特性

* [#158](https://github.com/xmake-io/xmake/issues/158): 增加对Cuda编译环境的支持
* 添加`set_tools`和`add_tools`接口为指定target目标设置编译工具链
* 添加内建规则：`mode.debug`, `mode.release`, `mode.profile`和`mode.check`
* 添加`is_mode`, `is_arch` 和`is_plat`内置接口到自定义脚本域
* 添加color256代码
* [#160](https://github.com/xmake-io/xmake/issues/160): 增加对Qt SDK编译环境的跨平台支持，并且增加`qt.console`, `qt.application`等规则
* 添加一些Qt工程模板
* [#169](https://github.com/xmake-io/xmake/issues/169): 支持yasm汇编器
* [#159](https://github.com/xmake-io/xmake/issues/159): 增加对WDK驱动编译环境支持

### 改进

* 添加FAQ到自动生成的xmake.lua文件，方便用户快速上手
* 支持Android NDK >= r14的版本
* 改进swiftc对warning flags的支持
* [#167](https://github.com/xmake-io/xmake/issues/167): 改进自定义规则：`rule()`
* 改进`os.files`和`os.dirs`接口，加速文件模式匹配
* [#171](https://github.com/xmake-io/xmake/issues/171): 改进Qt环境的构建依赖
* 在makefile生成插件中实现`make clean`

### Bugs修复

* 修复无法通过`add_ldflags("xx", "xx", {force = true})`强制设置多个flags的问题
* [#157](https://github.com/xmake-io/xmake/issues/157): 修复pdb符号输出目录不存在情况下编译失败问题
* 修复对macho格式目标strip all符号失效问题
* [#168](https://github.com/xmake-io/xmake/issues/168): 修复生成vs201x工程插件，在x64下失败的问题

## v2.1.9

### 新特性

* 添加`del_files()`接口去从已添加的文件列表中移除一些文件
* 添加`rule()`, `add_rules()`接口实现自定义构建规则，并且改进`add_files("src/*.md", {rule = "markdown"})`
* 添加`os.filesize()`接口
* 添加`core.ui.xxx`等cui组件模块，实现终端可视化界面，用于实现跟用户进行短暂的交互
* 通过`xmake f --menu`实现可视化菜单交互配置，简化工程的编译配置
* 添加`set_values`接口到option
* 改进option，支持根据工程中用户自定义的option，自动生成可视化配置菜单
* 在调用api设置工程配置时以及在配置菜单中添加源文件位置信息

### 改进

* 改进交叉工具链配置，通过指定工具别名定向到已知的工具链来支持未知编译工具名配置, 例如: `xmake f --cc=gcc@ccmips.exe`
* [#151](https://github.com/xmake-io/xmake/issues/151): 改进mingw平台下动态库生成
* 改进生成makefile插件
* 改进检测错误提示
* 改进`add_cxflags`等flags api的设置，添加force参数，来禁用自动检测和映射，强制设置选项：`add_cxflags("-DTEST", {force = true})`
* 改进`add_files`的flags设置，添加force域，用于设置不带自动检测和映射的原始flags：`add_files("src/*.c", {force = {cxflags = "-DTEST"}})`
* 改进搜索工程根目录策略
* 改进vs环境探测，支持加密文件系统下vs环境的探测
* 升级luajit到最新2.1.0-beta3
* 增加对linux/arm, arm64的支持，可以在arm linux上运行xmake
* 改进vs201x工程生成插件，更好的includedirs设置支持

### Bugs修复

* 修复依赖修改编译和链接问题
* [#151](https://github.com/xmake-io/xmake/issues/151): 修复`os.nuldev()`在mingw上传入gcc时出现问题
* [#150](https://github.com/xmake-io/xmake/issues/150): 修复windows下ar.exe打包过长obj列表参数，导致失败问题
* 修复`xmake f --cross`无法配置问题
* 修复`os.cd`到windows根路径问题

## v2.1.8

### 新特性

* 添加`XMAKE_LOGFILE`环境变量，启用输出到日志文件
* 添加对tinyc编译器的支持

### 改进

* 改进对IDE和编辑器插件的集成支持，例如：Visual Studio Code, Sublime Text 以及 IntelliJ IDEA
* 当生成新工程的时候，自动生成一个`.gitignore`文件，忽略一些xmake的临时文件和目录
* 改进创建模板工程，使用模板名代替模板id作为参数
* 改进macOS编译平台的探测，如果没有安装xcode也能够进行编译构建，如果有编译器的话
* 改进`set_config_header`接口，支持局部版本号设置，优先于全局`set_version`，例如：`set_config_header("config", {version = "2.1.8", build = "%Y%m%d%H%M"})`

### Bugs修复

* [#145](https://github.com/xmake-io/xmake/issues/145): 修复运行target的当前目录环境

## v2.1.7

### 新特性

* 添加`add_imports`去为target，option和package的自定义脚本批量导入模块，简化自定义脚本
* 添加`xmake -y/--yes`去确认用户输入
* 添加`xmake l package.manager.install xxx`模块，进行跨平台一致性安装软件包
* 添加vscode编辑器插件支持，更加方便的使用xmake，[xmake-vscode](https://marketplace.visualstudio.com/items?itemName=tboox.xmake-vscode#overview)
* 添加`xmake macro ..`快速运行最近一次命令

### 改进

* 改进`cprint()`，支持24位真彩色输出
* 对`add_rpathdirs()`增加对`@loader_path`和`$ORIGIN`的内置变量支持，提供可迁移动态库加载
* 改进`set_version("x.x.x", {build = "%Y%m%d%H%M"})` 支持buildversion设置
* 移除docs目录，将其放置到独立xmake-docs仓库中，减少xmake.zip的大小，优化下载安装的效率
* 改进安装和卸载脚本，支持DESTDIR和PREFIX环境变量设置
* 通过缓存优化flags探测，加速编译效率
* 添加`COLORTERM=nocolor`环境变量开关，禁用彩色输出
* 移除`add_rbindings`和`add_bindings`接口
* 禁止在重定向的时候进行彩色输出，避免输出文件中带有色彩代码干扰
* 更新tbox工程模板
* 改进`lib.detect.find_program`模块接口
* 为windows cmd终端增加彩色输出
* 增加`-w|--warning`参数来启用实时警告输出

### Bugs修复

* 修复`set_pcxxheader`编译没有继承flags配置问题
* [#140](https://github.com/xmake-io/xmake/issues/140): 修复`os.tmpdir()`在fakeroot下的冲突问题
* [#142](https://github.com/xmake-io/xmake/issues/142): 修复`os.getenv` 在windows上的中文编码问题
* 修复在带有空格路径的情况下，编译错误问题
* 修复setenv空值的崩溃问题

## v2.1.6

### 改进

* 改进`add_files`，支持对files粒度进行编译选项的各种配置，更加灵活。
* 从依赖的target和option中继承links和linkdirs。
* 改进`target.add_deps`接口，添加继承配置，允许手动禁止依赖继承，例如：`add_deps("test", {inherit = false})`
* 移除`tbox.pkg`二进制依赖，直接集成tbox源码进行编译

### Bugs修复

* 修复目标级联依赖问题
* 修复`target:add`和`option:add`问题
* 修复在archlinux上的编译和安装问题
* 修复`/ZI`的兼容性问题，用`/Zi`替代

## v2.1.5

### 新特性

* [#83](https://github.com/xmake-io/xmake/issues/83): 添加 `add_csnippet`，`add_cxxsnippet`到`option`来检测一些编译器特性
* [#83](https://github.com/xmake-io/xmake/issues/83): 添加用户扩展模块去探测程序，库文件以及其他主机环境
* 添加`find_program`, `find_file`, `find_library`, `find_tool`和`find_package` 等模块接口
* 添加`net.*`和`devel.*`扩展模块
* 添加`val()`接口去获取内置变量，例如：`val("host")`, `val("env PATH")`, `val("shell echo hello")` and `val("reg HKEY_LOCAL_MACHINE\\XX;Value")`
* 增加对微软.rc资源文件的编译支持，当在windows上编译时，可以增加资源文件了
* 增加`has_flags`, `features`和`has_features`等探测模块接口
* 添加`option.on_check`, `option.after_check` 和 `option.before_check` 接口
* 添加`target.on_load`接口
* [#132](https://github.com/xmake-io/xmake/issues/132): 添加`add_frameworkdirs`接口
* 添加`lib.detect.has_xxx`和`lib.detect.find_xxx`接口
* 添加`add_moduledirs`接口在工程中定义和加载扩展模块
* 添加`includes`接口替换`add_subdirs`和`add_subfiles`
* [#133](https://github.com/xmake-io/xmake/issues/133): 改进工程插件，通过运行`xmake project -k compile_commands`来导出`compile_commands.json`
* 添加`set_pcheader`和`set_pcxxheader`去支持跨编译器预编译头文件，支持`gcc`, `clang`和`msvc`
* 添加`xmake f -p cross`平台用于交叉编译，并且支持自定义平台名

### 改进

* [#87](https://github.com/xmake-io/xmake/issues/87): 为依赖库目标自动添加：`includes` 和 `links`
* 改进`import`接口，去加载用户扩展模块
* [#93](https://github.com/xmake-io/xmake/pull/93): 改进 `xmake lua`，支持运行单行命令和模块
* 改进编译错误提示信息输出
* 改进`print`接口去更好些显示table数据
* [#111](https://github.com/xmake-io/xmake/issues/111): 添加`--root`通用选项去临时支持作为root运行
* [#113](https://github.com/xmake-io/xmake/pull/113): 改进权限管理，现在作为root运行也是非常安全的
* 改进`xxx_script`工程描述api，支持多平台模式选择, 例如：`on_build("iphoneos|arm*", function (target) end)`
* 改进内置变量，支持环境变量和注册表数据的获取
* 改进vstudio环境和交叉工具链的探测
* [#71](https://github.com/xmake-io/xmake/issues/71): 改进从环境变量中探测链接器和编译器
* 改进option选项检测，通过多任务检测，提升70%的检测速度
* [#129](https://github.com/xmake-io/xmake/issues/129): 检测链接依赖，如果源文件没有改变，就不必重新链接目标文件了
* 在vs201x工程插件中增加对`*.asm`文件的支持
* 标记`add_bindings`和`add_rbindings`为废弃接口
* 优化`xmake rebuild`在windows上的构建速度
* 将`core.project.task`模块迁移至`core.base.task`
* 将`echo` 和 `app2ipa` 插件迁移到 [xmake-plugins](https://github.com/xmake-io/xmake-plugins) 仓库
* 添加`set_config_header("config.h", {prefix = ""})` 代替 `set_config_h` 和 `set_config_h_prefix`

### Bugs修复

* 修复`try-catch-finally`
* 修复解释器bug，解决当加载多级子目录时，根域属性设置不对
* [#115](https://github.com/xmake-io/xmake/pull/115): 修复安装脚本`get.sh`的路径问题
* 修复`import()`导入接口的缓存问题

## v2.1.4

### 新特性

* [#68](https://github.com/xmake-io/xmake/issues/68): 增加`$(programdir)`和`$(xmake)`内建变量
* 添加`is_host`接口去判断当前的主机环境
* [#79](https://github.com/xmake-io/xmake/issues/79): 增强`xmake lua`，支持交互式解释执行

### 改进

* 修改菜单选项颜色
* [#71](https://github.com/xmake-io/xmake/issues/71): 针对widows编译器改进优化选项映射
* [#73](https://github.com/xmake-io/xmake/issues/73): 尝试获取可执行文件路径来作为xmake的脚本目录
* 在`add_subdirs`中的子`xmake.lua`中，使用独立子作用域，避免作用域污染导致的干扰问题
* [#78](https://github.com/xmake-io/xmake/pull/78): 美化非全屏终端窗口下的`xmake --help`输出
* 避免产生不必要的`.xmake`目录，如果不在工程中的时候

### Bugs修复

* [#67](https://github.com/xmake-io/xmake/issues/67): 修复 `sudo make install` 命令权限问题
* [#70](https://github.com/xmake-io/xmake/issues/70): 修复检测android编译器错误
* 修复临时文件路径冲突问题
* 修复`os.host`, `os.arch`等接口
* 修复根域api加载干扰其他子作用域问题
* [#77](https://github.com/xmake-io/xmake/pull/77): 修复`cprint`色彩打印中断问题

## v2.1.3

### 新特性

* [#65](https://github.com/xmake-io/xmake/pull/65): 为target添加`set_default`接口用于修改默认的构建所有targets行为
* 允许在工程子目录执行`xmake`命令进行构建，xmake会自动检测所在的工程根目录
* 添加`add_rpathdirs` api到target和option，支持动态库的自动加载运行

### 改进

* [#61](https://github.com/xmake-io/xmake/pull/61): 提供更加安全的`xmake install` and `xmake uninstall`任务，更友好的处理root安装问题
* 提供`rpm`, `deb`和`osxpkg`安装包
* [#63](https://github.com/xmake-io/xmake/pull/63): 改进安装脚本，实现更加安全的构建和安装xmake
* [#61](https://github.com/xmake-io/xmake/pull/61): 禁止在root权限下运行xmake命令，增强安全性
* 改进工具链检测，通过延迟延迟检测提升整体检测效率
* 当自动扫面生成`xmake.lua`时，添加更友好的用户提示，避免用户无操作

### Bugs修复

* 修复版本检测的错误提示信息
* [#60](https://github.com/xmake-io/xmake/issues/60): 修复macosx和windows平台的xmake自举编译
* [#64](https://github.com/xmake-io/xmake/issues/64): 修复构建android `armv8-a`架构失败问题
* [#50](https://github.com/xmake-io/xmake/issues/50): 修复构建android可执行程序，无法运行问题

## v2.1.2

### 新特性

* 添加aur打包脚本，并支持用`yaourt`包管理器进行安装。
* 添加[set_basename](#http://xmake.io/#/zh/manual?id=targetset_basename)接口，便于定制化修改生成后的目标文件名

### 改进

* 支持vs2017编译环境
* 支持编译android版本的rust程序
* 增强vs201x工程生成插件，支持同时多模式、架构编译

### Bugs修复

* 修复编译android程序，找不到系统头文件问题
* 修复检测选项行为不正确问题
* [#57](https://github.com/xmake-io/xmake/issues/57): 修复代码文件权限到0644

## v2.1.1

### 新特性

* 添加`--links`, `--linkdirs` and `--includedirs` 配置参数
* 添加app2ipa插件
* 为`xmake.lua`工程描述增加dictionay语法风格
* 提供智能扫描编译模式，在无任何`xmake.lua`等工程描述文件的情况下，也能直接快速编译
* 为`xmake.lua`工程描述添加`set_xmakever`接口，更加友好的处理版本兼容性问题
* 为`objc`和`swift`程序添加`add_frameworks`接口
* 更加快速方便的多语言扩展支持，增加`golang`, `dlang`和`rust`程序构建的支持
* 添加`target_end`, `option_end` 和`task_end`等可选api，用于显示结束描述域，进入根域设置，提高可读性
* 添加`golang`, `dlang`和`rust`工程模板

### 改进

* 工程生成插件支持vs2017
* 改进gcc/clang编译器警告和错误提示
* 重构代码架构，改进多语言支持，更加方便灵活的扩展语言支持
* 改进print接口，同时支持原生lua print以及格式化打印
* 如果xmake.lua不存在，自动扫描工程代码文件，并且生成xmake.lua进行编译
* 修改license，使用更加宽松的Apache License 2.0
* 移除一些二进制工具文件
* 移除install.bat脚本，提供windows nsis安装包支持
* 使用[docute](https://github.com/egoist/docute)重写[文档](http://www.xmake.io/#/zh/)，提供更加完善的文档支持
* 增强`os.run`, `os.exec`, `os.cp`, `os.mv` 和 `os.rm` 等接口，支持通配符模式匹配和批量文件操作
* 精简和优化构建输出信息，添加`-q|--quiet`选项实现静默构建
* 改进`makefile`生成插件，抽取编译工具和编译选项到全局变量

### Bugs修复

* [#41](https://github.com/waruqi/xmake/issues/41): 修复在windows下自动检测x64失败问题
* [#43](https://github.com/waruqi/xmake/issues/43): 避免创建不必要的.xmake工程缓存目录
* 针对android版本添加c++ stl搜索目录，解决编译c++失败问题
* 修复在rhel 5.10上编译失败问题
* 修复`os.iorun`返回数据不对问题

## v2.0.5

### 新特性

* 为解释器作用域增加一些内建模块支持
* 针对windows x64平台，支持ml64汇编器

### 改进

* 增强ipairs和pairs接口，支持过滤器模式，简化脚本代码
* 为vs201x工程生成增加文件filter
* 移除`core/tools`目录以及msys工具链，在windows上使用xmake自编译core源码进行安装，优化xmake源码磁盘空间
* 移除`xmake/packages`，默认模板安装不再内置二进制packages，暂时需要手动放置，以后再做成自动包依赖下载编译

### Bugs修复

* 修复msvc的编译选项不支持问题：`-def:xxx.def`
* 修复ml.exe汇编器脚本
* 修复选项链接顺序问题

## v2.0.4

### 新特性

* 在`xmake.lua`中添加原生shell支持，例如：`add_ldflags("$(shell pkg-config --libs sqlite3)")`
* 编译windows目标程序，默认默认启用pdb符号文件
* 在windows上添加调试器支持（vsjitdebugger, ollydbg, windbg ... ）
* 添加`getenv`接口到`xmake.lua`的全局作用域中
* 添加生成vstudio工程插件(支持：vs2002 - vs2015)
* 为option添加`set_default`接口

### 改进

* 增强内建变量的处理
* 支持字符串类型的选项option设置

### Bugs修复

* 修复在linux下检测ld连接器失败，如果没装g++的话
* 修复`*.cxx`编译失败问题

## v2.0.3

### 新特性

* 增加头文件依赖自动检测和增量编译，提高编译速度
* 在终端中进行颜色高亮提示
* 添加调试器支持，`xmake run -d program ...`

### 改进

* 增强运行shell的系列接口
* 更新luajit到v2.0.4版本
* 改进makefile生成插件，移除对xmake的依赖，并且支持`windows/linux/macosx`等大部分pc平台
* 优化多任务编译速度，在windows下编译提升较为明显

### Bugs修复

* 修复安装目录错误问题
* 修复`import`根目录错误问题
* 修复在多版本vs同时存在的情况下，检测vs环境失败问题

## v2.0.2

### 改进

* 修改安装和卸载的action处理
* 更新工程模板
* 增强函数检测

### Bugs修复

* [#7](https://github.com/waruqi/xmake/issues/7): 修复用模板创建工程后，target名不对问题：'[targetname]'
* [#9](https://github.com/waruqi/xmake/issues/9): 修复clang不支持c++11的问题
* 修复api作用域泄露问题
* 修复在windows上的一些路径问题
* 修复检测宏函数失败问题
* 修复检测工具链失败问题
* 修复windows上编译android版本失败

## v2.0.1

### 新特性

* 增加task任务机制，可运行自定义任务脚本
* 实现plugin扩展机制，可以很方便扩展实现自定义插件，目前已实现的一些内置插件
* 增加project文件导出插件(目前已支持makefile的生成，后续会支持：vs, xcode等工程的生成)
* 增加hello xmake插件（插件demo）
* 增加doxygen文档生成插件
* 增加自定义宏脚本插件（支持动态宏记录、宏回放、匿名宏、批量导入、导出等功能）
* 增加更多的类库用于插件化开发
* 实现异常捕获机制，简化上层调用逻辑
* 增加多个option进行宏绑定，实现配置一个参数，就可以同时对多个配置进行生效
* 增加显示全局构建进度

### 改进

* 重构整个xmake.lua描述文件的解释器，更加的灵活可扩展
* 更加严格的语法检测机制
* 更加严格的作用域管理，实现沙盒引擎，对xmake.lua中脚本进行沙盒化处理，使得xmake.lua更加的安全
* 简化模板的开发，简单几行描述就可以扩展一个新的自定义工程模板
* 完全模块化platforms、tools、templates、actions，以及通过自注册机制，只需把自定义的脚本放入对应目录，就可实现快速扩展
* 针对所有可扩展脚本所需api进行大量简化，并实现大量类库，通过import机制进行导入使用
* 移除对gnu make/nmake等make工具的依赖，不再需要makefile，实现自己的make算法，
* 优化构建速度，支持多任务编译(支持vs编译器)（实测：比v1.0.4提升x4倍的构建性能）
* 优化自动检测机制，更加的稳定和准确
* 修改部分工程描述api，增强扩展性，减少一些命名歧义（对低版本向下兼容）
* 优化静态库合并：`add_files("*.a")`，修复一些bug
* 优化交叉编译，通过`--sdk=xxx`参数实现更加方便智能的进行交叉编译配置，简化mingw平台的编译配置
* 简化命令行配置开关, 支持`xmake config --xxx=[y|n|yes|no|true|false]`等开关值
* 合并iphoneos和iphonesimulator平台，以及watchos和watchsimulator平台，通过arch来区分，使得打包更加方便，能够支持一次性打包iphoneos的所有arch到一个包中

### Bugs修复

* [#3](https://github.com/waruqi/xmake/issues/3): 修复ArchLinux 编译失败问题
* [#4](https://github.com/waruqi/xmake/issues/4): 修复windows上安装失败问题
* 修复windows上环境变量设置问题

## v1.0.4

### 新特性

* 增加对windows汇编器的支持
* 为xmake create增加一些新的工程模板，支持tbox版本
* 支持swift代码
* 针对-v参数，增加错误输出信息
* 增加apple编译平台：watchos, watchsimulator的编译支持
* 增加对windows: x64, amd64, x86_amd64架构的编译支持
* 实现动态库和静态库的快速切换
* 添加-j/--jobs参数，手动指定是否多任务编译，默认改为单任务编译

### 改进

* 增强`add_files`接口，支持直接添加`*.o/obj/a/lib`文件，并且支持静态库的合并
* 裁剪xmake的安装过程，移除一些预编译的二进制程序

### Bugs修复

* [#1](https://github.com/waruqi/xmake/issues/4): 修复win7上安装失败问题
* 修复和增强工具链检测
* 修复一些安装脚本的bug, 改成外置sudo进行安装
* 修复linux x86_64下安装失败问题

## v1.0.3

### 新特性

* 添加set_runscript接口，支持自定义运行脚本扩展
* 添加import接口，使得在xmake.lua中可以导入一些扩展模块，例如：os，path，utils等等，使得脚本更灵活
* 添加android平台arm64-v8a支持

### Bugs修复

* 修复set_installscript接口的一些bug
* 修复在windows x86_64下，安装失败的问题
* 修复相对路径的一些bug
