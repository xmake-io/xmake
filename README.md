<div align="center">
  <a href="http://xmake.io">
    <img width="200" heigth="200" src="http://tboox.org/static/img/xmake/logo256c.png">
  </a>  

  <h1>xmake</h1>

  <div>
    <a href="https://travis-ci.org/tboox/xmake">
      <img src="https://img.shields.io/travis/tboox/xmake/master.svg?style=flat-square" alt="travis-ci" />
    </a>
    <a href="https://ci.appveyor.com/project/waruqi/xmake/branch/master">
      <img src="https://img.shields.io/appveyor/ci/waruqi/xmake/master.svg?style=flat-square" alt="appveyor-ci" />
    </a>
    <a href="https://aur.archlinux.org/packages/xmake">
      <img src="https://img.shields.io/aur/votes/xmake.svg?style=flat-square" alt="AUR votes" />
    </a>
    <a href="https://github.com/tboox/xmake/releases">
      <img src="https://img.shields.io/github/release/tboox/xmake.svg?style=flat-square" alt="Github All Releases" />
    </a>
  </div>
  <div>
    <a href="https://github.com/tboox/xmake/blob/master/LICENSE.md">
      <img src="https://img.shields.io/github/license/tboox/xmake.svg?colorB=f48041&style=flat-square" alt="license" />
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

The project focuses on making development and building easier and provides many features (.e.g package, install, plugin, macro, action, option, task ...), 
so that any developer can quickly pick it up and enjoy the productivity boost when developing and building project.

If you want to known more, please refer to:

* [Documents](http://xmake.io/#/home)
* [HomePage](http://www.xmake.io)
* [Github](https://github.com/tboox/xmake)
* [Gitee](https://gitee.com/tboox/xmake)

```
                         _        
    __  ___ __  __  __ _| | ______ 
    \ \/ / |  \/  |/ _  | |/ / __ \
     >  <  | \__/ | /_| |   <  ___/
    /_/\_\_|_|  |_|\__ \|_|\_\____| 

                         by ruki, tboox.org
```

## Installation

#### via curl

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tboox/xmake/master/scripts/get.sh)
```

#### via wget

```bash
bash <(wget https://raw.githubusercontent.com/tboox/xmake/master/scripts/get.sh -O -)
```

#### via powershell

```bash
Invoke-Expression (Invoke-Webrequest 'https://raw.githubusercontent.com/tboox/xmake/master/scripts/get.ps1' -UseBasicParsing).Content
```

## Simple description

<img src="https://xmake.io/assets/img/index/showcode1.png" width="40%" />

## Package dependences

<img src="https://xmake.io/assets/img/index/add_require.png" width="70%" />

An official xmake package repository: [xmake-repo](https://github.com/tboox/xmake-repo)

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

<img src="https://xmake.io/assets/img/index/menuconf.png" width="80%" />

## Package management

<img src="https://xmake.io/assets/img/index/package_manage.png" width="80%" />

## Supported platforms

* Windows (x86, x64)
* macOS (i386, x86_64)
* Linux (i386, x86_64, cross-toolchains ...)
* Android (armv5te, armv6, armv7-a, armv8-a, arm64-v8a)
* iOS (armv7, armv7s, arm64, i386, x86_64)
* WatchOS (armv7k, i386)
* MinGW (i386, x86_64)

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

## Builtin Plugins

#### Macros script plugin

```bash
$ xmake m -b                        # start to record
$ xmake f -p iphoneos -m debug
$ xmake
$ xmake f -p android --ndk=~/files/android-ndk-r16b
$ xmake
$ xmake m -e                        # stop to record
$ xmake m .                         # playback commands
```

#### Run the custom lua script plugin

```bash
$ xmake l ./test.lua
$ xmake l -c "print('hello xmake!')"
$ xmake l lib.detect.find_tool gcc
```

#### Generate IDE project file plugin（makefile, vs2002 - vs2017 .. ）

```bash
$ xmake project -k vs2017 -m "debug,release"
```

#### Generate doxygen document plugin

```bash
$ xmake doxygen [srcdir]
```

## More Plugins

Please download and install from the plugins repository [xmake-plugins](https://github.com/tboox/xmake-plugins).

## IDE/Editor Integration

* [xmake-vscode](https://github.com/tboox/xmake-vscode)

<img src="https://raw.githubusercontent.com/tboox/xmake-vscode/master/res/problem.gif" width="60%" />

* [xmake-sublime](https://github.com/tboox/xmake-sublime)

<img src="https://raw.githubusercontent.com/tboox/xmake-sublime/master/res/problem.gif" width="60%" />

* [xmake-idea](https://github.com/tboox/xmake-idea)

<img src="https://raw.githubusercontent.com/tboox/xmake-idea/master/res/problem.gif" width="60%" />

* [xmake.vim](https://github.com/luzhlon/xmake.vim) (third-party, thanks [@luzhlon](https://github.com/luzhlon))

## More Examples

Debug and release modes:

```lua
add_rules("mode.debug", "mode.release")

target("console")
    set_kind("binary")
    add_files("src/*.c") 
    if is_plat("windows", "mingw") then
        add_defines("XXX")
    end
```

Custom script:

```lua
target("test")
    set_kind("static")
    add_files("src/*.cpp")
    after_build(function (target)
        print("build %s ok!", target:targetfile())
    end)
```

Extension Modules:

```lua
target("test")
    set_kind("shared")
    add_files("src/*.c")
    on_load(function (target)
        import("lib.detect.find_package")
        target:add(find_package("zlib"))
    end)
```

## Project Examples

Some projects using xmake:

* [tbox](https://github.com/tboox/tbox)
* [gbox](https://github.com/tboox/gbox)
* [vm86](https://github.com/tboox/vm86)
* [more](https://github.com/tboox/awesome-xmake)

## Example Video

<a href="https://asciinema.org/a/133693">
<img src="https://asciinema.org/a/133693.png" width="60%" />
</a>

## Contacts

* Email：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* Homepage：[tboox.org](http://www.tboox.org)
* Community：[/r/tboox on reddit](https://www.reddit.com/r/tboox/)
* ChatRoom：[Char on telegram](https://t.me/tbooxorg), [Chat on gitter](https://gitter.im/tboox/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
* Source Code：[Github](https://github.com/tboox/xmake), [Gitee](https://gitee.com/tboox/xmake)

## Thanks

This project exists thanks to all the people who have [contributed](CONTRIBUTING.md):
<a href="https://github.com/tboox/xmake/graphs/contributors"><img src="https://opencollective.com/xmake/contributors.svg?width=890&button=false" /></a>

* [TitanSnow](https://github.com/TitanSnow): provide the xmake [logo](https://github.com/TitanSnow/ts-xmake-logo) and install scripts
* [uael](https://github.com/uael): provide the semantic versioning library [sv](https://github.com/uael/sv)

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


