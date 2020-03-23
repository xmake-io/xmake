<div align="center">
  <a href="https://xmake.io">
    <img width="200" heigth="200" src="https://tboox.org/static/img/xmake/logo256c.png">
  </a>  

  <h1>xmake</h1>

  <div>
    <a href="https://travis-ci.org/xmake-io/xmake">
      <img src="https://img.shields.io/travis/xmake-io/xmake/master.svg?style=flat-square" alt="travis-ci" />
    </a>
    <a href="https://ci.appveyor.com/project/waruqi/xmake/branch/master">
      <img src="https://img.shields.io/appveyor/ci/waruqi/xmake/master.svg?style=flat-square" alt="appveyor-ci" />
    </a>
    <a href="https://aur.archlinux.org/packages/xmake">
      <img src="https://img.shields.io/aur/votes/xmake.svg?style=flat-square" alt="AUR votes" />
    </a>
    <a href="https://github.com/xmake-io/xmake/releases">
      <img src="https://img.shields.io/github/release/xmake-io/xmake.svg?style=flat-square" alt="Github All Releases" />
    </a>
  </div>
  <div>
    <a href="https://github.com/xmake-io/xmake/blob/master/LICENSE.md">
      <img src="https://img.shields.io/github/license/xmake-io/xmake.svg?colorB=f48041&style=flat-square" alt="license" />
    </a>
    <a href="https://www.reddit.com/r/tboox/">
      <img src="https://img.shields.io/badge/chat-on%20reddit-ff3f34.svg?style=flat-square" alt="Reddit" />
    </a>
    <a href="https://gitter.im/tboox/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge">
      <img src="https://img.shields.io/gitter/room/tboox/tboox.svg?style=flat-square&colorB=96c312" alt="Gitter" />
    </a>
    <a href="https://t.me/tbooxorg">
      <img src="https://img.shields.io/badge/chat-on%20telegram-blue.svg?style=flat-square" alt="Telegram" />
    </a>
    <a href="https://jq.qq.com/?_wv=1027&k=5hpwWFv">
      <img src="https://img.shields.io/badge/chat-on%20QQ-ff69b4.svg?style=flat-square" alt="QQ" />
    </a>
    <a href="http://xmake.io/pages/donation.html#donate">
      <img src="https://img.shields.io/badge/donate-us-orange.svg?style=flat-square" alt="Donate" />
    </a>
  </div>

  <p>A cross-platform build utility based on Lua</p>
</div>

## Introduction ([中文](/README_zh.md))

xmake is a cross-platform build utility based on lua. 

The project focuses on making development and building easier and provides many features (e.g package, install, plugin, macro, action, option, task ...), 
so that any developer can quickly pick it up and enjoy a productivity boost when developing and building projects.

<img src="https://xmake.io/assets/img/index/package_manage.png" width="650px" />

If you want to know more, please refer to:

* [Documents](https://xmake.io/#/home)
* [HomePage](https://xmake.io)
* [Github](https://github.com/xmake-io/xmake)
* [Gitee](https://gitee.com/tboox/xmake)

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

### Termux/Android cpu/8core (-j12)

| buildsystem     | spend time     |
|-----            | ----           |
|xmake            | 24.890s        |
|ninja            | 25.682s        |
|cmake(gen+make)  | 5.416s+28.473s |
|cmake(gen+ninja) | 4.458s+24.842s |

### MacOS cpu/8core (-j12)

| buildsystem     | spend time     |
|-----            | ----           |
|xmake            | 12.264s        |
|ninja            | 11.327s        |
|cmake(gen+make)  | 1.203s+14.030s |
|cmake(gen+ninja) | 0.988s+11.644s |

## Package management

### Download and build

<img src="https://xmake.io/assets/img/index/package_manage.png" width="650px" />

### Processing architecture

<img src="https://xmake.io/assets/img/index/package_arch.png" width="650px" />

## Supported platforms

* Windows (x86, x64)
* macOS (i386, x86_64)
* Linux (i386, x86_64, cross-toolchains ..)
* Android (i386, x86_64, armv5te, armv7-a, armv8-a, arm64-v8a, mips)
* iOS (armv7, armv7s, arm64, i386, x86_64)
* WatchOS (armv7k, i386)
* MSYS (i386, x86_64)
* MinGW (i386, x86_64)
* Cygwin (i386, x86_64)
* SDCC (stm8, mcs51, ..)
* Cross (cross-toolchains ..)

## Supported Languages

* C
* C++
* Objective-C and Objective-C++
* Swift
* Assembly
* Golang
* Rust
* Dlang
* Cuda

## Supported Projects

* Static Library
* Shared Library
* Console
* Cuda Program
* Qt Application
* WDK Driver (umdf/kmdf/wdm)
* WinSDK Application
* MFC Application

## More Examples

Debug and release modes:

```lua
add_rules("mode.debug", "mode.release")

target("console")
    set_kind("binary")
    add_files("src/*.c")
    if is_mode("debug") then
        add_defines("DEBUG")
    end
```

Custom scripts:

```lua
target("test")
    set_kind("binary")
    add_files("src/*.c")
    after_build(function (target)
        print("hello: %s", target:name())
        os.exec("echo %s", target:targetfile())
    end)
```

Download and use packages in [xmake-repo](https://github.com/xmake-io/xmake-repo) or third-party repositories:

```lua
add_requires("tbox >1.6.1", "libuv master", "vcpkg::ffmpeg", "brew::pcre2/libpcre2-8")
add_requires("conan::OpenSSL/1.0.2n@conan/stable", {alias = "openssl", optional = true, debug = true}) 
target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("tbox", "libuv", "vcpkg::ffmpeg", "brew::pcre2/libpcre2-8", "openssl")
```

Qt QuickApp Program:

```lua
target("test")
    add_rules("qt.quickapp")
    add_files("src/*.cpp")
    add_files("src/qml.qrc")
```

Cuda Program:

```lua
target("test")
    set_kind("binary")
    add_files("src/*.cu")
    add_cugencodes("native")
    add_cugencodes("compute_30")
```

WDK/UMDF Driver Program:

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

## Plugins

#### Generate IDE project file plugin（makefile, vs2002 - vs2019 .. ）

```bash
$ xmake project -k vsxmake -m "debug;release" # New vsproj generator (Recommended)
$ xmake project -k vs -m "debug;release"
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

## Project Examples

Some projects using xmake:

* [tbox](https://github.com/tboox/tbox)
* [gbox](https://github.com/tboox/gbox)
* [vm86](https://github.com/tboox/vm86)
* [more](https://github.com/xmake-io/awesome-xmake)

## Example Video

<a href="https://asciinema.org/a/133693">
<img src="https://asciinema.org/a/133693.png" width="650px" />
</a>

## Contacts

* Email：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* Homepage：[tboox.org](https://tboox.org)
* Community：[/r/tboox on reddit](https://www.reddit.com/r/tboox/)
* ChatRoom：[Char on telegram](https://t.me/tbooxorg), [Chat on gitter](https://gitter.im/tboox/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
* Source Code：[Github](https://github.com/xmake-io/xmake), [Gitee](https://gitee.com/tboox/xmake)
* QQ Group: 343118190(full), 662147501
* Wechat Public: tboox-os

## Thanks

This project exists thanks to all the people who have [contributed](CONTRIBUTING.md):
<a href="https://github.com/xmake-io/xmake/graphs/contributors"><img src="https://opencollective.com/xmake/contributors.svg?width=890&button=false" /></a>

* [TitanSnow](https://github.com/TitanSnow): provide the xmake [logo](https://github.com/TitanSnow/ts-xmake-logo) and install scripts
* [uael](https://github.com/uael): provide the semantic versioning library [sv](https://github.com/uael/sv)
* [OpportunityLiu](https://github.com/OpportunityLiu): improve cuda, tests and ci

## Backers

Thank you to all our backers! 🙏 [[Become a backer](https://opencollective.com/xmake#backer)]

<a href="https://opencollective.com/xmake#backers" target="_blank"><img src="https://opencollective.com/xmake/backers.svg?width=890"></a>

## Sponsors

Support this project by becoming a sponsor. Your logo will show up here with a link to your website. [[Become a sponsor](https://opencollective.com/xmake#sponsor)]

<a href="https://opencollective.com/xmake/sponsor/0/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/0/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/1/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/1/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/2/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/2/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/3/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/3/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/4/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/4/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/5/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/5/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/6/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/6/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/7/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/7/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/8/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/8/avatar.svg"></a>
<a href="https://opencollective.com/xmake/sponsor/9/website" target="_blank"><img src="https://opencollective.com/xmake/sponsor/9/avatar.svg"></a>


