<div align="center">
  <a href="https://xmake.io/cn">
    <img width="160" heigth="160" src="https://tboox.org/static/img/xmake/logo256c.png">
  </a>

  <h1>xmake</h1>

  <div>
    <a href="https://github.com/xmake-io/xmake/actions?query=workflow%3AWindows">
      <img src="https://img.shields.io/github/workflow/status/xmake-io/xmake/Windows/dev.svg?style=flat-square&logo=windows" alt="github-ci" />
    </a>
    <a href="https://github.com/xmake-io/xmake/actions?query=workflow%3ALinux">
      <img src="https://img.shields.io/github/workflow/status/xmake-io/xmake/Linux/dev.svg?style=flat-square&logo=linux" alt="github-ci" />
    </a>
    <a href="https://github.com/xmake-io/xmake/actions?query=workflow%3AmacOS">
      <img src="https://img.shields.io/github/workflow/status/xmake-io/xmake/macOS/dev.svg?style=flat-square&logo=apple" alt="github-ci" />
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
    <a href="https://xmake.io/#/zh-cn/about/sponsor">
      <img src="https://img.shields.io/badge/donate-us-orange.svg?style=flat-square" alt="Donate" />
    </a>
  </div>

  <b>A cross-platform build utility based on Lua</b><br/>
  <i>Modern C/C++ build tools, Simple, Fast, Powerful dependency package integration</i><br/>
</div>

## 项目支持

通过[成为赞助者](https://xmake.io/#/about/sponsor)来支持该项目。您的logo将显示在此处，并带有指向您网站的链接。🙏

<a href="https://opencollective.com/xmake#sponsors" target="_blank"><img src="https://opencollective.com/xmake/sponsors.svg?width=890"></a>
<a href="https://opencollective.com/xmake#backers" target="_blank"><img src="https://opencollective.com/xmake/backers.svg?width=600"></a>

## 技术支持

你也可以考虑通过 [Github 的赞助计划](https://github.com/sponsors/waruqi) 赞助我们来获取额外的技术支持服务，然后你就能获取 [xmake-io/technical-support](https://github.com/xmake-io/technical-support) 仓库的访问权限，获取更多技术咨询相关的信息。

- [x] 更高优先级的 Issues 问题处理
- [x] 一对一技术咨询服务
- [x] Review xmake.lua 并提供改进建议

## 简介

Xmake 是一个基于 Lua 的轻量级跨平台构建工具。

它非常的轻量，没有任何依赖，因为它内置了 Lua 运行时。

它使用 xmake.lua 维护项目构建，相比 makefile/CMakeLists.txt，配置语法更加简洁直观，对新手非常友好，短时间内就能快速入门，能够让用户把更多的精力集中在实际的项目开发上。

我们能够使用它像 Make/Ninja 那样可以直接编译项目，也可以像 CMake/Meson 那样生成工程文件，另外它还有内置的包管理系统来帮助用户解决 C/C++ 依赖库的集成使用问题。

目前，Xmake 主要用于 C/C++ 项目的构建，但是同时也支持其他 native 语言的构建，可以实现跟 C/C++ 进行混合编译，同时编译速度也是非常的快，可以跟 Ninja 持平。

```
Xmake = Build backend + Project Generator + Package Manager + [Remote|Distributed] Compilation
```

如果你想要了解更多，请参考：[在线文档](https://xmake.io/#/zh-cn/getting_started), [Github](https://github.com/xmake-io/xmake)以及[Gitee](https://gitee.com/tboox/xmake)，同时也欢迎加入我们的 [社区](https://xmake.io/#/zh-ch/about/contact).

![](https://xmake.io/assets/img/index/xmake-basic-render.gif)

## 课程

xmake 官方也推出了一些入门课程，带你一步步快速上手 xmake，课程列表如下：

* [Xmake 带你轻松构建 C/C++ 项目](https://xmake.io/#/zh-cn/about/course)

## 安装

#### 使用curl

```bash
bash <(curl -fsSL https://xmake.io/shget.text)
```

#### 使用wget

```bash
bash <(wget https://xmake.io/shget.text -O -)
```

#### 使用powershell

```powershell
Invoke-Expression (Invoke-Webrequest 'https://xmake.io/psget.text' -UseBasicParsing).Content
```

#### 其他安装方式

如果不想使用脚本安装，也可以点击查看 [安装文档](https://xmake.io/#/zh-cn/guide/installation)，了解其他安装方法。

## 简单的工程描述

<img src="https://xmake.io/assets/img/index/showcode1.png" width="340px" />

## 包依赖描述

<img src="https://xmake.io/assets/img/index/add_require.png" width="600px" />

官方的xmake包管理仓库: [xmake-repo](https://github.com/xmake-io/xmake-repo)

## 构建工程

```bash
$ xmake
```

## 运行目标

```bash
$ xmake run console
```

## 调试程序

```bash
$ xmake run -d console
```

## 配置平台

```bash
$ xmake f -p [windows|linux|macosx|android|iphoneos ..] -a [x86|arm64 ..] -m [debug|release]
$ xmake
```

## 图形化菜单配置

```bash
$ xmake f --menu
```

<img src="https://xmake.io/assets/img/index/menuconf.png" width="650px" />

## 跟ninja一样快的构建速度

测试工程: [xmake-core](https://github.com/xmake-io/xmake/tree/master/core)

### 多任务并行编译测试

| 构建系统        | Termux (8core/-j12) | 构建系统         | MacOS (8core/-j12) |
|-----            | ----                | ---              | ---                |
|xmake            | 24.890s             | xmake            | 12.264s            |
|ninja            | 25.682s             | ninja            | 11.327s            |
|cmake(gen+make)  | 5.416s+28.473s      | cmake(gen+make)  | 1.203s+14.030s     |
|cmake(gen+ninja) | 4.458s+24.842s      | cmake(gen+ninja) | 0.988s+11.644s     |

### 单任务编译测试

| 构建系统        | Termux (-j1)     | 构建系统         | MacOS (-j1)    |
|-----            | ----             | ---              | ---            |
|xmake            | 1m57.707s        | xmake            | 39.937s        |
|ninja            | 1m52.845s        | ninja            | 38.995s        |
|cmake(gen+make)  | 5.416s+2m10.539s | cmake(gen+make)  | 1.203s+41.737s |
|cmake(gen+ninja) | 4.458s+1m54.868s | cmake(gen+ninja) | 0.988s+38.022s |


## 包依赖管理

### 下载和编译

<img src="https://xmake.io/assets/img/index/package_manage.png" width="650px" />

### 架构和流程

<img src="https://xmake.io/assets/img/index/package_arch.png" width="650px" />

### 支持的包管理仓库

* 官方自建仓库 [xmake-repo](https://github.com/xmake-io/xmake-repo) (tbox >1.6.1)
* 官方包管理器 [Xrepo](https://github.com/xmake-io/xrepo)
* [用户自建仓库](https://xmake.io/#/zh-cn/package/remote_package?id=%e4%bd%bf%e7%94%a8%e8%87%aa%e5%bb%ba%e7%a7%81%e6%9c%89%e5%8c%85%e4%bb%93%e5%ba%93)
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

### 包管理特性

* 官方仓库提供近 500+ 常用包，真正做到全平台一键下载集成编译
* 全平台包支持，支持交叉编译的依赖包集成
* 支持包虚拟环境管理和加载，`xrepo env shell`
* Windows 云端预编译包加速
* 支持自建包仓库，私有仓库部署
* 第三方包仓库支持，提供更加丰富的包源，例如：vcpkg, conan, conda 等等
* 支持自动拉取使用云端工具链
* 支持包依赖锁定

## 支持平台

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

## 支持工具链

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
muslcc        The musl-based cross-compilation toolchain
fpc           Free Pascal Programming Language Compiler
wasi          WASI-enabled WebAssembly C/C++ toolchain
nim           Nim Programming Language Compiler
circle        A new C++20 compiler
armcc         ARM Compiler Version 5 of Keil MDK
armclang      ARM Compiler Version 6 of Keil MDK
c51           Keil development tools for the 8051 Microcontroller Architecture
```

## 支持语言

* C/C++
* Objc/Objc++
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

## 支持特性

* 语法简单易上手
* 快速安装，无任何依赖
* 全平台一键编译
* 支持交叉编译，智能分析交叉工具链信息
* 极速，多任务并行编译支持
* C++20 Module 支持
* 支持跨平台的 C/C++ 依赖包快速集成，内置包管理器
* 多语言混合编译支持
* 丰富的插件支持，提供各种工程生成器，例如：vs/makefile/cmakelists/compile_commands 生成插件
* REPL 交互式执行支持
* 增量编译支持，头文件依赖自动分析
* 工具链的快速切换、定制化支持
* 丰富的扩展模块支持
* 远程编译支持
* 分布式编译支持

## 工程类型

* 静态库程序
* 动态库类型
* 控制台程序
* Cuda 程序
* Qt 应用程序
* WDK Windows 驱动程序
* WinSDK 应用程序
* MFC 应用程序
* iOS/MacOS 应用程序（支持.metal）
* Framework和Bundle程序（iOS/MacOS）
* SWIG 模块 (Lua, python, ...)
* Luarocks 模块
* Protobuf 程序
* Lex/yacc 程序
* C++20 模块
* Linux 内核驱动模块

## 分布式编译

- [x] 跨平台支持
- [x] 支持 msvc, clang, gcc 和交叉编译工具链
- [x] 支持构建 android, ios, linux, win, macOS 程序
- [x] 除了编译工具链，无任何其他依赖
- [x] 支持编译服务器负载均衡调度
- [x] 支持大文件实时压缩传输 (lz4)
- [x] 几乎零配置成本，无需共享文件系统，更加方便和安全

更多详情见：[#274](https://github.com/xmake-io/xmake/issues/274)

## 远程编译

更多详情见：[#622](https://github.com/xmake-io/xmake/issues/622)

## 更多例子

#### Debug 和 Release模式

```lua
add_rules("mode.debug", "mode.release")

target("console")
    set_kind("binary")
    add_files("src/*.c")
    if is_mode("debug") then
        add_defines("DEBUG")
    end
```

#### 自定义脚本

```lua
target("test")
    set_kind("binary")
    add_files("src/*.c")
    after_build(function (target)
        print("hello: %s", target:name())
        os.exec("echo %s", target:targetfile())
    end)
```

#### 依赖包自动集成

下载和使用在 [xmake-repo](https://github.com/xmake-io/xmake-repo) 和第三方包仓库的依赖包：

```lua
add_requires("tbox >1.6.1", "libuv master", "vcpkg::ffmpeg", "brew::pcre2/libpcre2-8")
add_requires("conan::openssl/1.1.1g", {alias = "openssl", optional = true, debug = true})
target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("tbox", "libuv", "vcpkg::ffmpeg", "brew::pcre2/libpcre2-8", "openssl")
```

另外，我们也可以使用 [xrepo](https://github.com/xmake-io/xrepo) 命令来快速安装依赖包。

#### Qt QuickApp 应用程序

```lua
target("test")
    add_rules("qt.quickapp")
    add_files("src/*.cpp")
    add_files("src/qml.qrc")
```

#### Cuda 程序

```lua
target("test")
    set_kind("binary")
    add_files("src/*.cu")
    add_cugencodes("native")
    add_cugencodes("compute_35")
```

#### WDK/UMDF 驱动程序

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

更多WDK驱动程序例子(umdf/kmdf/wdm)，见：[WDK工程例子](https://xmake.io/#/zh-cn/guide/project_examples?id=wdk%e9%a9%b1%e5%8a%a8%e7%a8%8b%e5%ba%8f)

#### iOS/MacOS 应用程序

```lua
target("test")
    add_rules("xcode.application")
    add_files("src/*.m", "src/**.storyboard", "src/*.xcassets")
    add_files("src/Info.plist")
```

#### Framework 和 Bundle 程序（iOS/MacOS）

```lua
target("test")
    add_rules("xcode.framework") -- 或者 xcode.bundle
    add_files("src/*.m")
    add_files("src/Info.plist")
```

#### OpenMP 程序

```lua
add_requires("libomp", {optional = true})
target("loop")
    set_kind("binary")
    add_files("src/*.cpp")
    add_rules("c++.openmp")
    add_packages("libomp")
```

#### Zig 程序

```lua
target("test")
    set_kind("binary")
    add_files("src/main.zig")
```

### 自动拉取远程工具链

#### 拉取指定版本的 llvm 工具链

我们使用 llvm-10 中的 clang 来编译项目。

```lua
add_requires("llvm 10.x", {alias = "llvm-10"})
target("test")
    set_kind("binary")
    add_files("src/*.c)
    set_toolchains("llvm@llvm-10")
````

#### 拉取交叉编译工具链

我们也可以拉取指定的交叉编译工具链来编译项目。

```lua
add_requires("muslcc")
target("test")
    set_kind("binary")
    add_files("src/*.c)
    set_toolchains("@muslcc")
```

#### 拉取工具链并且集成对应工具链编译的依赖包

我们也可以使用指定的muslcc交叉编译工具链去编译和集成所有的依赖包。

```lua
add_requires("muslcc")
add_requires("zlib", "libogg", {system = false})

set_toolchains("@muslcc")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib", "libogg")
```

## 插件

#### 生成IDE工程文件插件（makefile, vs2002 - vs2022, ...）

```bash
$ xmake project -k vsxmake -m "debug,release" # 新版vs工程生成插件（推荐）
$ xmake project -k vs -m "debug,release"
$ xmake project -k cmake
$ xmake project -k ninja
$ xmake project -k compile_commands
```

#### 加载自定义lua脚本插件

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

更多内置插件见相关文档：[内置插件文档](https://xmake.io/#/zh-cn/plugin/builtin_plugins)

其他扩展插件，请到插件仓库进行下载安装: [xmake-plugins](https://github.com/xmake-io/xmake-plugins).

## IDE和编辑器插件

* [xmake-vscode](https://github.com/xmake-io/xmake-vscode)

<img src="https://raw.githubusercontent.com/xmake-io/xmake-vscode/master/res/problem.gif" width="650px" />

* [xmake-sublime](https://github.com/xmake-io/xmake-sublime)

<img src="https://raw.githubusercontent.com/xmake-io/xmake-sublime/master/res/problem.gif" width="650px" />

* [xmake-idea](https://github.com/xmake-io/xmake-idea)

<img src="https://raw.githubusercontent.com/xmake-io/xmake-idea/master/res/problem.gif" width="650px" />

* [xmake.vim](https://github.com/luzhlon/xmake.vim) (third-party, thanks [@luzhlon](https://github.com/luzhlon))

* [xmake-visualstudio](https://github.com/HelloWorld886/xmake-visualstudio) (third-party, thanks [@HelloWorld886](https://github.com/HelloWorld886))

* [xmake-qtcreator](https://github.com/Arthapz/xmake-project-manager) (third-party, thanks [@Arthapz](https://github.com/Arthapz))

### XMake Gradle插件 (JNI)

我们也可以在Gradle中使用[xmake-gradle](https://github.com/xmake-io/xmake-gradle)插件来集成编译JNI库

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

当`gradle-xmake-plugin`插件被应用生效后，`xmakeBuild`任务会自动注入到现有的`assemble`任务中去，自动执行jni库编译和集成。

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

## CI 集成

### GitHub Action

我们可以使用 [github-action-setup-xmake](https://github.com/xmake-io/github-action-setup-xmake) 在 Github Action 上实现跨平台安装集成 Xmake。

```
uses: xmake-io/github-action-setup-xmake@v1
with:
  xmake-version: latest
```

## 谁在使用 Xmake?

请点击 [用户列表](https://xmake.io/#/zh-cn/about/who_is_using_xmake) 查看完整用户使用列表。

如果您在使用 xmake，也欢迎通过 PR 将信息提交至上面的列表，让更多的用户了解有多少用户在使用 xmake，也能让用户更加安心使用 xmake。

我们也会有更多的动力去持续投入，让 xmake 项目和社区更加繁荣。

## 联系方式

* 邮箱：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* 主页：[xmake.io](https://xmake.io/#/zh-cn/)
* 社区
  - [Reddit论坛](https://www.reddit.com/r/xmake/)
  - [Telegram群组](https://t.me/tbooxorg)
  - [Gitter聊天室](https://gitter.im/xmake-io/xmake?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
  - [Discord聊天室](https://discord.gg/xmake)
  - QQ群：343118190, 662147501
* 源码：[Github](https://github.com/xmake-io/xmake), [Gitee](https://gitee.com/tboox/xmake)
* 微信公众号：tboox-os

## 感谢

感谢所有对xmake有所[贡献](CONTRIBUTING.md)的人:
<a href="https://github.com/xmake-io/xmake/graphs/contributors"><img src="https://opencollective.com/xmake/contributors.svg?width=890&button=false" /></a>

* [TitanSnow](https://github.com/TitanSnow): 提供xmake [logo](https://github.com/TitanSnow/ts-xmake-logo) 和安装脚本。
* [uael](https://github.com/uael): 提供语义版本跨平台c库 [sv](https://github.com/uael/sv)。
* [OpportunityLiu](https://github.com/OpportunityLiu): 改进cuda构建, tests框架和ci。
* [xq144](https://github.com/xq114): 改进 `xrepo env shell`，并贡献大量包到 [xmake-repo](https://github.com/xmake-io/xmake-repo) 仓库。

