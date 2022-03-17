<div align="center">
  <a href="https://xmake.io">
    <img width="160" heigth="160" src="https://tboox.org/static/img/xmake/logo256c.png">
  </a>

  <h1>xmake</h1>

  <div>
    <a href="https://github.com/xmake-io/xmake/actions?query=workflow%3AWindows">
      <img src="https://img.shields.io/github/workflow/status/xmake-io/xmake/Windows/master.svg?style=flat-square&logo=windows" alt="github-ci" />
    </a>
    <a href="https://github.com/xmake-io/xmake/actions?query=workflow%3ALinux">
      <img src="https://img.shields.io/github/workflow/status/xmake-io/xmake/Linux/master.svg?style=flat-square&logo=linux" alt="github-ci" />
    </a>
    <a href="https://github.com/xmake-io/xmake/actions?query=workflow%3AmacOS">
      <img src="https://img.shields.io/github/workflow/status/xmake-io/xmake/macOS/master.svg?style=flat-square&logo=apple" alt="github-ci" />
    </a>
    <a href="https://github.com/xmake-io/xmake/releases">
      <img src="https://img.shields.io/github/release/xmake-io/xmake.svg?style=flat-square" alt="Github All Releases" />
    </a>
    <a href="https://aur.archlinux.org/packages/xmake">
      <img src="https://img.shields.io/aur/votes/xmake.svg?style=flat-square" alt="AUR votes" />
    </a>
  </div>
  <div>
    <a href="https://github.com/xmake-io/xmake/blob/master/LICENSE.md">
      <img src="https://img.shields.io/github/license/xmake-io/xmake.svg?colorB=f48041&style=flat-square" alt="license" />
    </a>
    <a href="https://www.reddit.com/r/xmake/">
      <img src="https://img.shields.io/badge/chat-on%20reddit-ff3f34.svg?style=flat-square" alt="Reddit" />
    </a>
    <a href="https://gitter.im/xmake-io/xmake?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge">
      <img src="https://img.shields.io/gitter/room/xmake-io/xmake.svg?style=flat-square&colorB=96c312" alt="Gitter" />
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
  <i>Modern C/C++ build tools, Simple, Fast, Powerful dependency package integration</i><br/>
</div>

## Support this project

Support this project by [becoming a sponsor](https://xmake.io/#/about/sponsor). Your logo will show up here with a link to your website. 🙏

<a href="https://opencollective.com/xmake#sponsors" target="_blank"><img src="https://opencollective.com/xmake/sponsors.svg?width=890"></a>
<a href="https://opencollective.com/xmake#backers" target="_blank"><img src="https://opencollective.com/xmake/backers.svg?width=890"></a>

## Technical Support

You can also consider sponsoring us to get extra technical support services via [Github sponsor program](https://github.com/sponsors/waruqi),
then you can get access to [xmake-io/technical-support](https://github.com/xmake-io/technical-support) repository to get more consulting related information.

- [x] Handling Issues with higher priority
- [x] One-to-one technical consulting service
- [x] Review your xmake.lua and provide suggestions for improvement

## Introduction ([中文](/README_zh.md))

Xmake is a lightweight cross-platform build utility based on Lua.

It is very lightweight and has no dependencies because it has a built-in Lua runtime.

It uses xmake.lua to maintain project builds and its configuration syntax is very simple and readable.

We can use it to build project directly like Make/Ninja, or generate project files like CMake/Meson, and it also has a built-in package management system to help users solve the integrated use of C/C++ dependent libraries.

```
Xmake = Build backend + Project Generator + Package Manager
```

If you want to know more, please refer to: [Documents](https://xmake.io/#/getting_started), [Github](https://github.com/xmake-io/xmake) and [Gitee](https://gitee.com/tboox/xmake) and also welcome to join our [community](https://xmake.io/#/about/contact).

![](https://xmake.io/assets/img/index/xmake-basic-render.gif)

## Installation

#### via curl

```bash
bash <(curl -fsSL https://xmake.io/shget.text)
```

#### via wget

```bash
bash <(wget https://xmake.io/shget.text -O -)
```

#### via powershell

```powershell
Invoke-Expression (Invoke-Webrequest 'https://xmake.io/psget.text' -UseBasicParsing).Content
```

#### Other installation ways

If you don't want to use script to install xmake, you can also click [Installation Guide] (https://xmake.io/#/guide/installation) to get other installation ways.

## Simple description

<img src="https://xmake.io/assets/img/index/showcode1.png" width="340px" />

## Package dependences

<img src="https://xmake.io/assets/img/index/add_require.png" width="600px" />

An official xmake package repository: [xmake-repo](https://github.com/xmake-io/xmake-repo)

## Build project

```bash
$ xmake
```

## Run target

```bash
$ xmake run console
```

## Debug target

```bash
$ xmake run -d console
```

## Configure platform

```bash
$ xmake f -p [windows|linux|macosx|android|iphoneos ..] -a [x86|arm64 ..] -m [debug|release]
$ xmake
```

## Menu configuration

```bash
$ xmake f --menu
```

<img src="https://xmake.io/assets/img/index/menuconf.png" width="650px" />

## Build as fast as ninja

The test project: [xmake-core](https://github.com/xmake-io/xmake/tree/master/core)

### Multi-task parallel compilation

| buildsystem     | Termux (8core/-j12) | buildsystem      | MacOS (8core/-j12) |
|-----            | ----                | ---              | ---                |
|xmake            | 24.890s             | xmake            | 12.264s            |
|ninja            | 25.682s             | ninja            | 11.327s            |
|cmake(gen+make)  | 5.416s+28.473s      | cmake(gen+make)  | 1.203s+14.030s     |
|cmake(gen+ninja) | 4.458s+24.842s      | cmake(gen+ninja) | 0.988s+11.644s     |

### Single task compilation

| buildsystem     | Termux (-j1)     | buildsystem      | MacOS (-j1)    |
|-----            | ----             | ---              | ---            |
|xmake            | 1m57.707s        | xmake            | 39.937s        |
|ninja            | 1m52.845s        | ninja            | 38.995s        |
|cmake(gen+make)  | 5.416s+2m10.539s | cmake(gen+make)  | 1.203s+41.737s |
|cmake(gen+ninja) | 4.458s+1m54.868s | cmake(gen+ninja) | 0.988s+38.022s |

## Package management

### Download and build

<img src="https://xmake.io/assets/img/index/package_manage.png" width="650px" />

### Processing architecture

<img src="https://xmake.io/assets/img/index/package_arch.png" width="650px" />

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

### Package management features

* The official repository provides nearly 500+ packages, one-click compilation on all platforms
* Full platform package support, support for cross-compiled dependent package integration
* Support package virtual environment, `xrepo env shell`
* Precompiled package acceleration for windows
* Support self-built package repositories, private repository deployment
* Third-party package repository support, such as: vcpkg, conan, conda, etc.
* Support to pull using remote toolchain automatically
* Support to lock package dependency

## Supported platforms

* Windows (x86, x64)
* macOS (i386, x86_64, arm64)
* Linux (i386, x86_64, cross-toolchains ..)
* *BSD (i386, x86_64)
* Android (x86, x86_64, armeabi, armeabi-v7a, arm64-v8a)
* iOS (armv7, armv7s, arm64, i386, x86_64)
* WatchOS (armv7k, i386)
* AppleTVOS (armv7, arm64, i386, x86_64)
* MSYS (i386, x86_64)
* MinGW (i386, x86_64, arm, arm64)
* Cygwin (i386, x86_64)
* Wasm (wasm32)
* Cross (cross-toolchains ..)

## Supported toolchains

```bash
$ xmake show -l toolchains
xcode         Xcode IDE
msvc          Microsoft Visual C/C++ Compiler
yasm          The Yasm Modular Assembler
clang         A C language family frontend for LLVM
go            Go Programming Language Compiler
dlang         D Programming Language Compiler
gfortran      GNU Fortran Programming Language Compiler
zig           Zig Programming Language Compiler
sdcc          Small Device C Compiler
cuda          CUDA Toolkit
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
muslcc        The musl-based cross-compilation toolchain
fpc           Free Pascal Programming Language Compiler
wasi          WASI-enabled WebAssembly C/C++ toolchain
nim           Nim Programming Language Compiler
circle        A new C++20 compiler
armcc         ARM Compiler Version 5 of Keil MDK
armclang      ARM Compiler Version 6 of Keil MDK
```

## Supported Languages

* C
* C++
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

## Supported Features

* The configuration grammar is simple and easy to use
* Quick installation, without any dependencies
* One-click compilation for all platforms
* Support cross compilation, intelligent analysis of cross tool chain information
* Extremely fast, multi-task parallel compilation support
* C++20 Module support
* Support cross-platform C/C++ dependency package quick integration, built-in package manager
* Multi-language mixed compilation support
* Rich plug-in support, providing various project generators, such as: vs/makefile/cmakelists/compile_commands to generate plugins
* REPL interactive execution support
* Incremental compilation support, automatic analysis of header files
* Quick switching and customization support of tool chain
* A large number of expansion modules support

## Supported Projects

* Static Library
* Shared Library
* Console
* Cuda Program
* Qt Application
* WDK Driver (umdf/kmdf/wdm)
* WinSDK Application
* MFC Application
* iOS/MacOS Application (Support .metal)
* Framework and Bundle Program (iOS/MacOS)
* SWIG Modules (Lua, python, ...)
* Luarocks Modules
* Protobuf Program
* Lex/yacc program
* C++20 Modules
* Linux Kernel Driver Modules

## More Examples

#### Debug and release modes

```lua
add_rules("mode.debug", "mode.release")

target("console")
    set_kind("binary")
    add_files("src/*.c")
    if is_mode("debug") then
        add_defines("DEBUG")
    end
```

#### Custom scripts

```lua
target("test")
    set_kind("binary")
    add_files("src/*.c")
    after_build(function (target)
        print("hello: %s", target:name())
        os.exec("echo %s", target:targetfile())
    end)
```

#### Automatic integration of dependent packages

Download and use packages in [xmake-repo](https://github.com/xmake-io/xmake-repo) or third-party repositories:

```lua
add_requires("tbox >1.6.1", "libuv master", "vcpkg::ffmpeg", "brew::pcre2/libpcre2-8")
add_requires("conan::openssl/1.1.1g", {alias = "openssl", optional = true, debug = true})
target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("tbox", "libuv", "vcpkg::ffmpeg", "brew::pcre2/libpcre2-8", "openssl")
```

In addition, we can also use the [xrepo](https://github.com/xmake-io/xrepo) command to quickly install dependent packages.

#### Qt QuickApp Program

```lua
target("test")
    add_rules("qt.quickapp")
    add_files("src/*.cpp")
    add_files("src/qml.qrc")
```

#### Cuda Program

```lua
target("test")
    set_kind("binary")
    add_files("src/*.cu")
    add_cugencodes("native")
    add_cugencodes("compute_35")
```

#### WDK/UMDF Driver Program

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

More wdk driver program examples (umdf/kmdf/wdm), please see [WDK Program Examples](https://xmake.io/#/guide/project_examples?id=wdk-driver-program)

#### iOS/MacOS Application

```lua
target("test")
    add_rules("xcode.application")
    add_files("src/*.m", "src/**.storyboard", "src/*.xcassets")
    add_files("src/Info.plist")
```

#### Framework and Bundle Program (iOS/MacOS)

```lua
target("test")
    add_rules("xcode.framework") -- or xcode.bundle
    add_files("src/*.m")
    add_files("src/Info.plist")
```

#### OpenMP Program

```lua
add_requires("libomp", {optional = true})
target("loop")
    set_kind("binary")
    add_files("src/*.cpp")
    add_rules("c++.openmp")
    add_packages("libomp")
```

#### Zig Program

```lua
target("test")
    set_kind("binary")
    add_files("src/main.zig")
```

### Automatically fetch remote toolchain

#### fetch the special version of llvm

We use clang in llvm-10 to compile the project.

```lua
add_requires("llvm 10.x", {alias = "llvm-10"})
target("test")
    set_kind("binary")
    add_files("src/*.c)
    set_toolchains("llvm@llvm-10")
````

#### Fetch cross-compilation toolchain

We can also pull the specified cross-compilation tool chain to compile the project.

```lua
add_requires("muslcc")
target("test")
    set_kind("binary")
    add_files("src/*.c)
    set_toolchains("@muslcc")
```

#### Fetch toolchain and packages

We can also use the specified muslcc cross-compilation toolchain to compile and integrate all dependent packages

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

#### Run the custom lua script plugin

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

More builtin plugins, please see: [Builtin plugins](https://xmake.io/#/plugin/builtin_plugins)

Please download and install more other plugins from the plugins repository [xmake-plugins](https://github.com/xmake-io/xmake-plugins).

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

### XMake Gradle Plugin (JNI)

We can uses [xmake-gradle](https://github.com/xmake-io/xmake-gradle) plugin to compile JNI library in gradle.

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

The `xmakeBuild` will be injected to `assemble` task automatically if the gradle-xmake-plugin has been applied.

```console
$ ./gradlew app:assembleDebug
> Task :nativelib:xmakeConfigureForArm64
> Task :nativelib:xmakeBuildForArm64
>> xmake build
[ 50%]: ccache compiling.debug nativelib.cc
[ 75%]: linking.debug libnativelib.so
[100%]: build ok!
>> install artifacts to /Users/ruki/projects/personal/xmake-gradle/nativelib/libs/arm64-v8a
> Task :nativelib:xmakeConfigureForArmv7
> Task :nativelib:xmakeBuildForArmv7
>> xmake build
[ 50%]: ccache compiling.debug nativelib.cc
[ 75%]: linking.debug libnativelib.so
[100%]: build ok!
>> install artifacts to /Users/ruki/projects/personal/xmake-gradle/nativelib/libs/armeabi-v7a
> Task :nativelib:preBuild
> Task :nativelib:assemble
> Task :app:assembleDebug
```

## CI Integration

### GitHub Action

We can use [github-action-setup-xmake](https://github.com/xmake-io/github-action-setup-xmake) to setup Xmake in Github Action.

```
uses: xmake-io/github-action-setup-xmake@v1
with:
  xmake-version: latest
```

## Who is using Xmake?

Please click [User List](https://xmake.io/#/about/who_is_using_xmake) to view the complete user list.

If you are using xmake, welcome to submit the information to the above list through PR, so that let more users can known how many users are using xmake.

Ihis also let users to use xmake more confidently, and we will also have more motivation to maintain it continuously,
so that the xmake project and the community will grow stronger.

## Contacts

* Email：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* Homepage：[xmake.io](https://xmake.io)
* Community
  - [Chat on reddit](https://www.reddit.com/r/xmake/)
  - [Chat on telegram](https://t.me/tbooxorg)
  - [Chat on gitter](https://gitter.im/xmake-io/xmake?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
  - [Chat on discord](https://discord.gg/xmake)
  - Chat on QQ Group: 343118190, 662147501
* Source Code：[Github](https://github.com/xmake-io/xmake), [Gitee](https://gitee.com/tboox/xmake)
* Wechat Public: tboox-os

## Thanks

This project exists thanks to all the people who have [contributed](CONTRIBUTING.md):
<a href="https://github.com/xmake-io/xmake/graphs/contributors"><img src="https://opencollective.com/xmake/contributors.svg?width=890&button=false" /></a>

* [TitanSnow](https://github.com/TitanSnow): provide the xmake [logo](https://github.com/TitanSnow/ts-xmake-logo) and install scripts
* [uael](https://github.com/uael): provide the semantic versioning library [sv](https://github.com/uael/sv)
* [OpportunityLiu](https://github.com/OpportunityLiu): improve cuda, tests and ci
* [xq144](https://github.com/xq114): Improve `xrepo env shell`, and contribute a lot of packages to the [xmake-repo](https://github.com/xmake-io/xmake-repo) repository.
