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
    <a href="https://aur.archlinux.org/packages/xmake">
      <img src="https://img.shields.io/aur/votes/xmake.svg?style=flat-square" alt="AUR votes" />
    </a>
    <a href="https://xmake.io/#/zh-cn/about/sponsor">
      <img src="https://img.shields.io/badge/donate-us-orange.svg?style=flat-square" alt="Donate" />
    </a>
  </div>

  <p>A cross-platform build utility based on Lua</p>
</div>

## 项目支持

通过成为赞助者来支持该项目。您的logo将显示在此处，并带有指向您网站的链接。🙏 [[成为赞助商](https://xmake.io/#/zh-cn/about/sponsor)]

<a href="https://opencollective.com/xmake#backers" target="_blank"><img src="https://opencollective.com/xmake/backers.svg?width=890"></a>

## 简介

xmake 是一个基于 Lua 的轻量级跨平台构建工具，使用 xmake.lua 维护项目构建，相比 makefile/CMakeLists.txt，配置语法更加简洁直观，对新手非常友好，短时间内就能快速入门，能够让用户把更多的精力集中在实际的项目开发上。

虽然，简单易用是 xmake 的一大特色，但 xmake 的功能也是非常强大的，既能够像 Make/Ninja 那样可以直接编译项目，也可以像 CMake/Meson 那样生成工程文件，还有内置的包管理系统来帮助用户解决 C/C++依赖库的集成使用问题。

目前，xmake主要用于C/C++项目的构建，但是同时也支持其他native语言的构建，可以实现跟C/C++进行混合编译，同时编译速度也是非常的快，可以跟Ninja持平。

如果你想要了解更多，请参考：[在线文档](https://xmake.io/#/zh-cn/getting_started), [Github](https://github.com/xmake-io/xmake)以及[Gitee](https://gitee.com/tboox/xmake)

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

## 支持平台

* Windows (x86, x64)
* macOS (i386, x86_64)
* Linux (i386, x86_64, cross-toolchains ..)
* *BSD (i386, x86_64)
* Android (x86, x86_64, armeabi, armeabi-v7a, arm64-v8a)
* iOS (armv7, armv7s, arm64, i386, x86_64)
* WatchOS (armv7k, i386)
* MSYS (i386, x86_64)
* MinGW (i386, x86_64)
* Cygwin (i386, x86_64)
* Wasm (wasm32)
* Cross (cross-toolchains ..)

## 支持工具链

```bash
$ xmake show -l toolchains
xcode         Xcode IDE
vs            VisualStudio IDE
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
llvm          A collection of modular and reusable compiler and toolchain technologies
cross         Common cross compilation toolchain
nasm          NASM Assembler
gcc           GNU Compiler Collection
mingw         Minimalist GNU for Windows
gnu-rm        GNU Arm Embedded Toolchain
envs          Environment variables toolchain
fasm          Flat Assembler
tinyc         Tiny C Compiler
emcc          A toolchain for compiling to asm.js and WebAssembly
icc           Intel C/C++ Compiler
ifort         Intel Fortran Compiler
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
* Zig (Experimental)

## 工程类型

* 静态库程序
* 动态库类型
* 控制台程序
* Cuda程序
* Qt应用程序
* WDK驱动程序
* WinSDK应用程序
* MFC应用程序
* iOS/MacOS应用程序
* Framework和Bundle程序（iOS/MacOS）

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

下载和使用在[xmake-repo](https://github.com/xmake-io/xmake-repo)和第三方包仓库的依赖包：

```lua
add_requires("tbox >1.6.1", "libuv master", "vcpkg::ffmpeg", "brew::pcre2/libpcre2-8")
add_requires("conan::openssl/1.1.1g", {alias = "openssl", optional = true, debug = true}) 
target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("tbox", "libuv", "vcpkg::ffmpeg", "brew::pcre2/libpcre2-8", "openssl")
```

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

## 插件

#### 生成IDE工程文件插件（makefile, vs2002 - vs2019, ...）

```bash
$ xmake project -k vsxmake -m "debug;release" # 新版vs工程生成插件（推荐）
$ xmake project -k vs -m "debug;release"
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

### XMake Gradle插件 (JNI)

我们也可以在Gradle中使用[xmake-gradle](https://github.com/xmake-io/xmake-gradle)插件来集成编译JNI库

```
plugins {
  id 'org.tboox.gradle-xmake-plugin' version '1.0.6'
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

## 技术支持

我们也提供付费的技术支持来为帮助用户快速解决相关问题，具体详情请点击下面的图片链接：

<a href="https://xscode.com/waruqi/xmake">
<img src="https://tboox.org/assets/img/xmake-xscode.png" width="650px" />
</a>

或者你也可以考虑赞助我们也获取技术支持服务，[[成为赞助商](https://xmake.io/#/zh-cn/about/sponsor)]

## 项目例子

一些使用xmake的项目：

* [tbox](https://github.com/tboox/tbox)
* [gbox](https://github.com/tboox/gbox)
* [vm86](https://github.com/tboox/vm86)
* [更多](https://github.com/xmake-io/awesome-xmake)

## 联系方式

* 邮箱：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* 主页：[xmake.io](https://xmake.io/#/zh-cn/)
* 社区：[Reddit论坛](https://www.reddit.com/r/xmake/)
* 聊天：[Telegram群组](https://t.me/tbooxorg), [Gitter聊天室](https://gitter.im/xmake-io/xmake?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
* 源码：[Github](https://github.com/xmake-io/xmake), [Gitee](https://gitee.com/tboox/xmake)
* QQ群：343118190(技术支持), 662147501
* 微信公众号：tboox-os
 
## 感谢

感谢所有对xmake有所[贡献](CONTRIBUTING.md)的人:
<a href="https://github.com/xmake-io/xmake/graphs/contributors"><img src="https://opencollective.com/xmake/contributors.svg?width=890&button=false" /></a>

* [TitanSnow](https://github.com/TitanSnow): 提供xmake [logo](https://github.com/TitanSnow/ts-xmake-logo) 和安装脚本
* [uael](https://github.com/uael): 提供语义版本跨平台c库 [sv](https://github.com/uael/sv)
* [OpportunityLiu](https://github.com/OpportunityLiu): 改进cuda构建, tests框架和ci

