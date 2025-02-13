<div align="center">
  <a href="https://xmake.io">
    <img width="160" height="160" src="https://tboox.org/static/img/xmake/logo256c.png">
  </a>

  <h1>xmake</h1>

  <div>
    <a href="https://github.com/xmake-io/xmake/actions?query=workflow%3AWindows">
      <img src="https://img.shields.io/github/actions/workflow/status/xmake-io/xmake/windows.yml?branch=master&style=flat-square&logo=windows" alt="github-ci" />
    </a>
    <a href="https://github.com/xmake-io/xmake/actions?query=workflow%3ALinux">
      <img src="https://img.shields.io/github/actions/workflow/status/xmake-io/xmake/linux.yml?branch=master&style=flat-square&logo=linux" alt="github-ci" />
    </a>
    <a href="https://github.com/xmake-io/xmake/actions?query=workflow%3AmacOS">
      <img src="https://img.shields.io/github/actions/workflow/status/xmake-io/xmake/macos.yml?branch=master&style=flat-square&logo=apple" alt="github-ci" />
    </a>
    <a href="https://github.com/xmake-io/xmake/releases">
      <img src="https://img.shields.io/github/release/xmake-io/xmake.svg?style=flat-square" alt="Github All Releases" />
    </a>
  </div>
  <div>
    <a href="https://github.com/xmake-io/xmake/blob/master/LICENSE.md">
      <img src="https://img.shields.io/github/license/xmake-io/xmake.svg?colorB=f48041&style=flat-square" alt="license" />
    </a>
    <a href="https://www.reddit.com/r/xmake/">
      <img src="https://img.shields.io/badge/chat-on%20reddit-ff3f34.svg?style=flat-square" alt="Reddit" />
    </a>
    <a href="https://t.me/tbooxorg">
      <img src="https://img.shields.io/badge/chat-on%20telegram-blue.svg?style=flat-square" alt="Telegram" />
    </a>
    <a href="https://jq.qq.com/?_wv=1027&k=5hpwWFv">
      <img src="https://img.shields.io/badge/chat-on%20QQ-ff69b4.svg?style=flat-square" alt="QQ" />
    </a>
    <a href="https://discord.gg/xmake">
      <img src="https://img.shields.io/badge/chat-on%20discord-7289da.svg?style=flat-square" alt="Discord" />
    </a>
    <a href="https://xmake.io/#/sponsor">
      <img src="https://img.shields.io/badge/donate-us-orange.svg?style=flat-square" alt="Donate" />
    </a>
  </div>

  <b>A cross-platform build utility based on Lua</b><br/>
  <i>Modern C/C++ build tool: Simple, Fast, Powerful dependency package integration</i><br/>
</div>

## Support this project

Support this project by [becoming a sponsor](https://xmake.io/#/about/sponsor). Your logo will show up here with a link to your website. 🙏

<a href="https://opencollective.com/xmake#sponsors" target="_blank"><img src="https://opencollective.com/xmake/sponsors.svg?width=890"></a>
<a href="https://opencollective.com/xmake#backers" target="_blank"><img src="https://opencollective.com/xmake/backers.svg?width=890"></a>

## Technical support

You can also consider sponsoring us to get extra technical support services via the [Github sponsor program](https://github.com/sponsors/waruqi). If you do, you can get access to the [xmake-io/technical-support](https://github.com/xmake-io/technical-support) repository, which has the following benefits:

- [X] Handling Issues with higher priority
- [X] One-to-one technical consulting service
- [X] Review your xmake.lua and provide suggestions for improvement

## Introduction ([中文](/README_zh.md))

What is Xmake?

1. Xmake is a cross-platform build utility based on the Lua scripting language.
2. Xmake is very lightweight and has no dependencies outside of the standard library.
3. Uses the `xmake.lua` file to maintain project builds with a simple and readable syntax.

Xmake can be used to directly build source code (like with Make or Ninja), or it can generate project source files like CMake or Meson. It also has a *built-in* package management system to help users integrate C/C++ dependencies.

```
Xmake = Build backend + Project Generator + Package Manager + [Remote|Distributed] Build + Cache
```

Although less precise, one can still understand Xmake in the following way:

```
Xmake ≈ Make/Ninja + CMake/Meson + Vcpkg/Conan + distcc + ccache/sccache
```

If you want to know more, please refer to: the [Documentation](https://xmake.io/#/getting_started), [GitHub](https://github.com/xmake-io/xmake) or [Gitee](https://gitee.com/tboox/xmake). You are also welcome to join our [community](https://xmake.io/#/about/contact).

The official Xmake repository can be found at [xmake-io/xmake-repo](https://github.com/xmake-io/xmake-repo).

![](https://github.com/xmake-io/xmake-docs/raw/master/assets/img/index/xmake-basic-render.gif)

## Installation

### With cURL

```bash
curl -fsSL https://xmake.io/shget.text | bash
```

### With Wget

```bash
wget https://xmake.io/shget.text -O - | bash
```

### With PowerShell

```sh
irm https://xmake.io/psget.text | iex
```

### Other installation methods

If you don't want to use the above scripts to install Xmake, visit the [Installation Guide](https://xmake.io/#/guide/installation) for other installation methods (building from source, package managers, etc.).

## Simple Project Description

```lua
target("console")
    set_kind("binary")
    add_files("src/*.c")
```

Creates a new target `console` of kind `binary`, and adds all the files ending in `.c` in the `src` directory.

## Package dependencies

```lua
add_requires("tbox 1.6.*", "zlib", "libpng ~1.6")
```

Adds a requirement of tbox v1.6, zlib (any version), and libpng v1.6.

The official xmake package repository exists at: [xmake-repo](https://github.com/xmake-io/xmake-repo)

<p align="center">
<img src="https://github.com/xmake-io/xmake-docs/raw/master/assets/img/index/package.gif" width="650px" />
</p>

## Command line interface reference

The below assumes you are currently in the project's root directory.

### Build a project

```bash
$ xmake
```

### Run target

```bash
$ xmake run console
```

### Debug target

```bash
$ xmake run -d console
```

### Run test

```bash
$ xmake test
```

### Configure platform

```bash
$ xmake f -p [windows|linux|macosx|android|iphoneos ..] -a [x86|arm64 ..] -m [debug|release]
$ xmake
```

### Menu configuration

```bash
$ xmake f --menu
```

<p align="center">
<img src="https://xmake.io/assets/img/index/menuconf.png" width="650px"/>
</p>

## Supported platforms

* Windows (x86, x64, arm, arm64, arm64ec)
* macOS (i386, x86_64, arm64)
* Linux (i386, x86_64, arm, arm64, riscv, mips, 390x, sh4 ...)
* *BSD (i386, x86_64)
* Android (x86, x86_64, armeabi, armeabi-v7a, arm64-v8a)
* iOS (armv7, armv7s, arm64, i386, x86_64)
* WatchOS (armv7k, i386)
* AppleTVOS (armv7, arm64, i386, x86_64)
* AppleXROS (arm64, x86_64)
* MSYS (i386, x86_64)
* MinGW (i386, x86_64, arm, arm64)
* Cygwin (i386, x86_64)
* Wasm (wasm32, wasm64)
* Haiku (i386, x86_64)
* Harmony (x86_64, armeabi-v7a, arm64-v8a)
* Cross (cross-toolchains ..)

## Supported toolchains

```bash
$ xmake show -l toolchains
xcode         Xcode IDE
msvc          Microsoft Visual C/C++ Compiler
clang-cl      LLVM Clang C/C++ Compiler compatible with msvc
yasm          The Yasm Modular Assembler
clang         A C language family frontend for LLVM
go            Go Programming Language Compiler
dlang         D Programming Language Compiler (Auto)
dmd           D Programming Language Compiler
ldc           The LLVM-based D Compiler
gdc           The GNU D Compiler (GDC)
gfortran      GNU Fortran Programming Language Compiler
zig           Zig Programming Language Compiler
sdcc          Small Device C Compiler
cuda          CUDA Toolkit (nvcc, nvc, nvc++, nvfortran)
ndk           Android NDK
rust          Rust Programming Language Compiler
swift         Swift Programming Language Compiler
llvm          A collection of modular and reusable compiler and toolchain technologies
cross         Common cross compilation toolchain
nasm          NASM Assembler
gcc           GNU Compiler Collection
mingw         Minimalist GNU for Windows
gnu-rm        GNU Arm Embedded Toolchain
envs          Environment variables toolchain
fasm          Flat Assembler
tinycc        Tiny C Compiler
emcc          A toolchain for compiling to asm.js and WebAssembly
icc           Intel C/C++ Compiler
ifort         Intel Fortran Compiler
ifx           Intel LLVM Fortran Compiler
muslcc        The musl-based cross-compilation toolchain
fpc           Free Pascal Programming Language Compiler
wasi          WASI-enabled WebAssembly C/C++ toolchain
nim           Nim Programming Language Compiler
circle        A new C++20 compiler
armcc         ARM Compiler Version 5 of Keil MDK
armclang      ARM Compiler Version 6 of Keil MDK
c51           Keil development tools for the 8051 Microcontroller Architecture
icx           Intel LLVM C/C++ Compiler
dpcpp         Intel LLVM C++ Compiler for data parallel programming model based on Khronos SYCL
masm32        The MASM32 SDK
iverilog      Icarus Verilog
verilator     Verilator open-source SystemVerilog simulator and lint system
cosmocc       build-once run-anywhere
hdk           Harmony SDK
ti-c2000      TI-CGT C2000 compiler
ti-c6000      TI-CGT C6000 compiler
iararm        IAR ARM C/C++ Compiler
kotlin-native Kotlin Native Programming Language Compiler
```

## Supported languages

* C and C++
* Objective-C and Objective-C++
* Swift
* Assembly
* Golang
* Rust
* Dlang
* Fortran
* Cuda
* Zig
* Vala
* Pascal
* Nim
* Verilog
* FASM
* NASM
* YASM
* MASM32
* Cppfront
* Kotlin

## Features

Xmake exhibits:

* Simple yet flexible configuration grammar.
* Quick, dependency-free installation.
* Easy compilation for most all supported platforms.
* Supports cross-compilation with intelligent analysis of cross toolchain information.
* Extremely fast parallel compilation support.
* Supports C++ modules (new in C++20).
* Supports cross-platform C/C++ dependencies with built-in package manager.
* Multi-language compilation support including mixed-language projects.
* Rich plug-in support with various project generators (ex. Visual Studio/Makefiles/CMake/`compile_commands.json`)
* REPL interactive execution support
* Incremental compilation support with automatic analysis of header files
* Built-in toolchain management
* A large number of expansion modules
* Remote compilation support
* Distributed compilation support
* Local and remote build cache support

## Supported Project Types

Xmake supports the below types of projects:

* Static libraries
* Shared libraries
* Console/CLI applications
* CUDA programs
* Qt applications
* WDK drivers (umdf/kmdf/wdm)
* WinSDK applications
* MFC applications
* Darwin applications (with metal support)
* Frameworks and bundles (in Darwin)
* SWIG modules (Lua, Python, ...)
* LuaRocks modules
* Protobuf programs
* Lex/Yacc programs
* Linux kernel modules

## Package management

### Download and build

Xmake can automatically fetch and install dependencies!

<p align="center">
<img src="https://xmake.io/assets/img/index/package_manage.png" width="650px" />
</p>

### Supported package repositories

* Official package repository [xmake-repo](https://github.com/xmake-io/xmake-repo) (tbox >1.6.1)
* Official package manager [Xrepo](https://github.com/xmake-io/xrepo)
* [User-built repositories](https://xmake.io/#/package/remote_package?id=using-self-built-private-package-repository)
* Conan (conan::openssl/1.1.1g)
* Conda (conda::libpng 1.3.67)
* Vcpkg (vcpkg:ffmpeg)
* Homebrew/Linuxbrew (brew::pcre2/libpcre2-8)
* Pacman on archlinux/msys2 (pacman::libcurl)
* Apt on ubuntu/debian (apt::zlib1g-dev)
* Clib (clib::clibs/bytes@0.0.4)
* Dub (dub::log 0.4.3)
* Portage on Gentoo/Linux (portage::libhandy)
* Nimble for nimlang (nimble::zip >1.3)
* Cargo for rust (cargo::base64 0.13.0)
* Zypper on openSUSE (zypper::libsfml2 2.5)

### Package management features

* The official repository provides nearly 500+ packages with simple compilation on all supported platforms
* Full platform package support, support for cross-compiled dependent packages
* Support package virtual environment using `xrepo env shell`
* Precompiled package acceleration for Windows (NT)
* Support self-built package repositories and private repository deployment
* Third-party package repository support for repositories such as: vcpkg, conan, conda, etc.
* Supports automatic pulling of remote toolchains
* Supports dependency version locking

## Processing architecture

Below is a diagram showing roughly the architecture of Xmake, and thus how it functions.

<p align="center">
<img src="https://xmake.io/assets/img/index/package_arch.png" width="650px" />
</p>

## Distributed Compilation

- [X] Cross-platform support.
- [X] Support for MSVC, Clang, GCC and other cross-compilation toolchains.
- [X] Support for building for Android, Linux, Windows NT, and Darwin hosts.
- [X] No dependencies other than the compilation toolchain.
- [X] Support for build server load balancing scheduling.
- [X] Support for real time compressed transfer of large files (lz4).
- [X] Almost zero configuration cost, no shared filesystem required, for convenience and security.

For more details see: [#274](https://github.com/xmake-io/xmake/issues/274)

## Remote Compilation

For more details see: [#622](https://github.com/xmake-io/xmake/issues/622)

## Local/Remote Build Cache

For more details see: [#622](https://github.com/xmake-io/xmake/issues/2371)

## Benchmark

Xmake's speed on is par with Ninja! The test project: [xmake-core](https://github.com/xmake-io/xmake/tree/master/core)

### Multi-task parallel compilation


| buildsystem      | Termux (8core/-j12) | buildsystem      | MacOS (8core/-j12) |
| ------------------ | --------------------- | ------------------ | -------------------- |
| xmake            | 24.890s             | xmake            | 12.264s            |
| ninja            | 25.682s             | ninja            | 11.327s            |
| cmake(gen+make)  | 5.416s+28.473s      | cmake(gen+make)  | 1.203s+14.030s     |
| cmake(gen+ninja) | 4.458s+24.842s      | cmake(gen+ninja) | 0.988s+11.644s     |

## Single task compilation


| buildsystem      | Termux (-j1)     | buildsystem      | MacOS (-j1)    |
| ------------------ | ------------------ | ------------------ | ---------------- |
| xmake            | 1m57.707s        | xmake            | 39.937s        |
| ninja            | 1m52.845s        | ninja            | 38.995s        |
| cmake(gen+make)  | 5.416s+2m10.539s | cmake(gen+make)  | 1.203s+41.737s |
| cmake(gen+ninja) | 4.458s+1m54.868s | cmake(gen+ninja) | 0.988s+38.022s |

## More Examples

### Debug and release profiles

```lua
add_rules("mode.debug", "mode.release")

target("console")
    set_kind("binary")
    add_files("src/*.c")
    if is_mode("debug") then
        add_defines("DEBUG")
    end
```

### Custom scripts

```lua
target("test")
    set_kind("binary")
    add_files("src/*.c")
    after_build(function (target)
        print("hello: %s", target:name())
        os.exec("echo %s", target:targetfile())
    end)
```

### Automatic integration of dependent packages

Download and use packages in [xmake-repo](https://github.com/xmake-io/xmake-repo) or third-party repositories:

```lua
add_requires("tbox >1.6.1", "libuv master", "vcpkg::ffmpeg", "brew::pcre2/libpcre2-8")
add_requires("conan::openssl/1.1.1g", {alias = "openssl", optional = true, debug = true})
target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("tbox", "libuv", "vcpkg::ffmpeg", "brew::pcre2/libpcre2-8", "openssl")
```

In addition, we can also use the [xrepo](https://github.com/xmake-io/xrepo) command to quickly install dependencies.

### Qt QuickApp Program

```lua
target("test")
    add_rules("qt.quickapp")
    add_files("src/*.cpp")
    add_files("src/qml.qrc")
```

### Cuda Program

```lua
target("test")
    set_kind("binary")
    add_files("src/*.cu")
    add_cugencodes("native")
    add_cugencodes("compute_35")
```

### WDK/UMDF Driver Program

```lua
target("echo")
    add_rules("wdk.driver", "wdk.env.umdf")
    add_files("driver/*.c")
    add_files("driver/*.inx")
    add_includedirs("exe")

target("app")
    add_rules("wdk.binary", "wdk.env.umdf")
    add_files("exe/*.cpp")
```

For more WDK driver examples (UMDF/KMDF/WDM), please visit [WDK Program Examples](https://xmake.io/#/guide/project_examples?id=wdk-driver-program)

### Darwin Applications

```lua
target("test")
    add_rules("xcode.application")
    add_files("src/*.m", "src/**.storyboard", "src/*.xcassets")
    add_files("src/Info.plist")
```

### Framework and Bundle Program (Darwin)

```lua
target("test")
    add_rules("xcode.framework") -- or xcode.bundle
    add_files("src/*.m")
    add_files("src/Info.plist")
```

### OpenMP Program

```lua
add_requires("libomp", {optional = true})
target("loop")
    set_kind("binary")
    add_files("src/*.cpp")
    add_rules("c++.openmp")
    add_packages("libomp")
```

### Zig Program

```lua
target("test")
    set_kind("binary")
    add_files("src/main.zig")
```

### Automatically fetch remote toolchain

#### fetch a special version of LLVM

Require the Clang version packaged with LLM-10 to compile a project.

```lua
add_requires("llvm 10.x", {alias = "llvm-10"})
target("test")
    set_kind("binary")
    add_files("src/*.c")
    set_toolchains("llvm@llvm-10")
```

#### Fetch a cross-compilation toolchain

We can also pull a specified cross-compilation toolchain in to compile the project.

```lua
add_requires("muslcc")
target("test")
    set_kind("binary")
    add_files("src/*.c")
    set_toolchains("@muslcc")
```

#### Fetch toolchain and packages

We can also use the specified `muslcc` cross-compilation toolchain to compile and integrate all dependent packages.

```lua
add_requires("muslcc")
add_requires("zlib", "libogg", {system = false})

set_toolchains("@muslcc")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib", "libogg")
```

## Plugins

#### Generate IDE project file plugin（makefile, vs2002 - vs2022 .. ）

```bash
$ xmake project -k vsxmake -m "debug,release" # New vsproj generator (Recommended)
$ xmake project -k vs -m "debug,release"
$ xmake project -k cmake
$ xmake project -k ninja
$ xmake project -k compile_commands
```

#### Run a custom lua script plugin

```bash
$ xmake l ./test.lua
$ xmake l -c "print('hello xmake!')"
$ xmake l lib.detect.find_tool gcc
$ xmake l
> print("hello xmake!")
> {1, 2, 3}
< {
    1,
    2,
    3
  }
```

To see a list of bultin plugs, please visit [Builtin plugins](https://xmake.io/#/plugin/builtin_plugins).

Please download and install other plugins from the plugins repository [xmake-plugins](https://github.com/xmake-io/xmake-plugins).

## IDE/Editor Integration

* [xmake-vscode](https://github.com/xmake-io/xmake-vscode)

<img src="https://raw.githubusercontent.com/xmake-io/xmake-vscode/master/res/problem.gif" width="650px" />

* [xmake-sublime](https://github.com/xmake-io/xmake-sublime)

<img src="https://raw.githubusercontent.com/xmake-io/xmake-sublime/master/res/problem.gif" width="650px" />

* [xmake-idea](https://github.com/xmake-io/xmake-idea)

<img src="https://raw.githubusercontent.com/xmake-io/xmake-idea/master/res/problem.gif" width="650px" />

* [xmake.vim](https://github.com/luzhlon/xmake.vim) (third-party, thanks [@luzhlon](https://github.com/luzhlon))
* [xmake-visualstudio](https://github.com/HelloWorld886/xmake-visualstudio) (third-party, thanks [@HelloWorld886](https://github.com/HelloWorld886))
* [xmake-qtcreator](https://github.com/Arthapz/xmake-project-manager) (third-party, thanks [@Arthapz](https://github.com/Arthapz))

### Xmake Gradle Plugin (JNI)

We can use the [xmake-gradle](https://github.com/xmake-io/xmake-gradle) plugin to compile JNI libraries via gradle.

```
plugins {
  id 'org.tboox.gradle-xmake-plugin' version '1.1.5'
}

android {
    externalNativeBuild {
        xmake {
            path "jni/xmake.lua"
        }
    }
}
```

The `xmakeBuild` task will be injected into the `assemble` task automatically if the `gradle-xmake-plugin` has been applied.

```console
$ ./gradlew app:assembleDebug
> Task :nativelib:xmakeConfigureForArm64
> Task :nativelib:xmakeBuildForArm64
>> xmake build
[ 50%]: cache compiling.debug nativelib.cc
[ 75%]: linking.debug libnativelib.so
[100%]: build ok!
>> install artifacts to /Users/ruki/projects/personal/xmake-gradle/nativelib/libs/arm64-v8a
> Task :nativelib:xmakeConfigureForArmv7
> Task :nativelib:xmakeBuildForArmv7
>> xmake build
[ 50%]: cache compiling.debug nativelib.cc
[ 75%]: linking.debug libnativelib.so
[100%]: build ok!
>> install artifacts to /Users/ruki/projects/personal/xmake-gradle/nativelib/libs/armeabi-v7a
> Task :nativelib:preBuild
> Task :nativelib:assemble
> Task :app:assembleDebug
```

## CI Integration

### GitHub Action

The [github-action-setup-xmake](https://github.com/xmake-io/github-action-setup-xmake) plugin for GitHub Actions can allow you to use Xmake with minimal efforts if you use GitHub Actions for your CI pipeline.

```yaml
uses: xmake-io/github-action-setup-xmake@v1
with:
  xmake-version: latest
```

## Who is using Xmake?

The list of people and projects who are using Xmake is available [here](https://xmake.io/#/about/who_is_using_xmake).

If you are using Xmake, you are welcome to submit your information to the above list through a PR, so that other users and the developers can gauge interest.  Ihis also let users to use xmake more confidently and give us motivation to continue to maintain it.

This will help the Xmake project and it's community grow stronger and expand!

## Contacts

* Email：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* Homepage：[xmake.io](https://xmake.io)
* Community
  - [Chat on Reddit](https://www.reddit.com/r/xmake/)
  - [Chat on Telegram](https://t.me/tbooxorg)
  - [Chat on Discord](https://discord.gg/xmake)
  - Chat on QQ Group: 343118190, 662147501
* Source Code：[GitHub](https://github.com/xmake-io/xmake), [Gitee](https://gitee.com/tboox/xmake)
* WeChat Public: tboox-os

## Thanks

This project exists thanks to all the people who have [contributed](CONTRIBUTING.md):
<a href="https://github.com/xmake-io/xmake/graphs/contributors"><img src="https://opencollective.com/xmake/contributors.svg?width=890&button=false" /></a>

* [TitanSnow](https://github.com/TitanSnow): Provide the xmake [logo](https://github.com/TitanSnow/ts-xmake-logo) and install scripts
* [uael](https://github.com/uael): Provide the semantic versioning library [sv](https://github.com/uael/sv)
* [OpportunityLiu](https://github.com/OpportunityLiu): Improve cuda, tests and ci
* [xq144](https://github.com/xq114): Improve `xrepo env shell`, and contribute a lot of packages to the [xmake-repo](https://github.com/xmake-io/xmake-repo) repository.
* [star-hengxing](https://github.com/star-hengxing): Contribute a lot of packages to the [xmake-repo](https://github.com/xmake-io/xmake-repo) repository.
* [Arthapz](https://github.com/Arthapz): Contribue new C++ Modules implementation.
* [SirLynix](https://github.com/SirLynix): Contributed many packages and let more people know about xmake.
* `enderger`: Helped smooth out the edges on the English translation of the README
