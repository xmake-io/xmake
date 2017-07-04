# A make-like build utility based on Lua 

[![Build Status](https://api.travis-ci.org/tboox/xmake.svg?branch=master)](https://travis-ci.org/tboox/xmake) [![Build status](https://ci.appveyor.com/api/projects/status/ry9oa2mxrj8hk613/branch/master?svg=true)](https://ci.appveyor.com/project/waruqi/xmake/branch/master) [![codecov](https://codecov.io/gh/tboox/xmake/branch/master/graph/badge.svg)](https://codecov.io/gh/tboox/xmake) [![Join the chat at https://gitter.im/tboox/tboox](https://badges.gitter.im/tboox/tboox.svg)](https://gitter.im/tboox/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![donate](http://tboox.org/static/img/donate.svg)](http://xmake.io/pages/donation.html#donate) [![Backers on Open Collective](https://opencollective.com/xmake/backers/badge.svg)](#backers) [![Sponsors on Open Collective](https://opencollective.com/xmake/sponsors/badge.svg)](#sponsors)

[![logo](http://tboox.org/static/img/xmake/logo256.png)](http://xmake.io)

## Introduction ([中文](/README_zh.md))

xmake is a make-like build utility based on lua. 

The project focuses on making development and building easier and provides many features (.e.g package, install, plugin, macro, action, option, task ...), 
so that any developer can quickly pick it up and enjoy the productivity boost when developing and building project.

If you want to known more, please refer to:

* [Documents](http://xmake.io/#/home)
* [Github](https://github.com/tboox/xmake)
* [HomePage](http://www.xmake.io)

## Installation

##### via curl

```bash
$ bash <(curl -fsSL http://xmake.io/get.sh)
```

##### via wget

```bash
$ bash <(wget http://xmake.io/get.sh -O -)
```

##### via powershell

```bash
$ Invoke-Expression (Invoke-Webrequest 'http://xmake.io/get.ps1' -UseBasicParsing).Content
```

## Simple description

```lua
target("console")
    set_kind("binary")
    add_files("src/*.c") 
```

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

## Support features

* Tasks
* Macros
* Actions
* Options
* Plugins
* Templates

## Support platforms

* Windows (x86, x64, amd64, x86_amd64)
* Macosx (i386, x86_64)
* Linux (i386, x86_64, cross-toolchains ...)
* Android (armv5te, armv6, armv7-a, armv8-a, arm64-v8a)
* iPhoneOS (armv7, armv7s, arm64, i386, x86_64)
* WatchOS (armv7k, i386)
* Mingw (i386, x86_64)

## Support Languages

* C/C++
* Objc/Objc++
* Swift
* Assembly
* Golang
* Rust
* Dlang

## Builtin Plugins

* Macros script plugin
* Run the custom lua script plugin
* Generate IDE project file plugin（makefile, vs2002 - vs2017 .. ）
* Generate doxygen document plugin
* Convert .app to .ipa plugin

## Examples

[![usage_demo](http://tboox.org/static/img/xmake/build_demo.gif)](http://www.xmake.io)

Create a c++ console project:

```bash
    xmake create -l c++ -t 1 console
 or xmake create --language=c++ --template=1 console
```

Project xmakefile: xmake.lua

```lua
target("console")
    set_kind("binary")
    add_files("src/*.c") 
```

Configure project:

This is optional, if you compile the targets only for linux, macosx and windows and the default compilation mode is release.

```bash
   xmake f -p iphoneos -m debug
or xmake f --plat=macosx --arch=x86_64
or xmake f -p windows
or xmake config --plat=iphoneos --mode=debug
or xmake config --plat=android --arch=armv7-a --ndk=xxxxx
or xmake config -p linux -a i386
or xmake config -p mingw --cross=i386-mingw32- --toolchains=/xxx/bin
or xmake config -p mingw --sdk=/mingwsdk
or xmake config --help
```

Compile project：

```bash
   xmake
or xmake -r
or xmake --rebuild
```

Run target：

```bash
   xmake r console
or xmake run console
```

Debug target：

```bash
   xmake r -d console
or xmake run -d console
```

Package all：

```bash
   xmake p
or xmake package
or xmake package console
or xmake package -o /tmp
or xmake package --output=/tmp
```

Package all archs using macro:
   
```bash
   xmake m package 
or xmake m package -p iphoneos
or xmake m package -p macosx -f "-m debug" -o /tmp/
or xmake m package --help
```

Install targets：

```bash
   xmake i
or xmake install
or xmake install console
or xmake install -o /tmp
or xmake install --output=/tmp
```

If you need known more detailed usage，please refer to [documents](https://github.com/waruqi/xmake/wiki/documents)
or run:

```bash
   xmake -h
or xmake --help
or xmake config --help
or xmake package --help
or xmake macro --help
...
```

The simple xmake.lua file:

```c
-- the debug mode
if is_mode("debug") then
    
    -- enable the debug symbols
    set_symbols("debug")

    -- disable optimization
    set_optimize("none")
end

-- the release mode
if is_mode("release") then

    -- set the symbols visibility: hidden
    set_symbols("hidden")

    -- enable fastest optimization
    set_optimize("fastest")

    -- strip all symbols
    set_strip("all")
end

-- add target
target("test")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/*.c") 
```

If you want to know more, please refer to:

## Documents

* [Documents](https://github.com/waruqi/xmake/wiki/documents)
* [Codes](https://github.com/waruqi/xmake)

## Projects

Some projects using xmake:

* [tbox](https://github.com/waruqi/tbox)
* [gbox](https://github.com/waruqi/gbox)
* [libsvx](https://github.com/caikelun/libsvx)
* [more](https://github.com/waruqi/xmake/wiki/xmake-projects)

## Contacts

* Email：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* Homepage：[tboox.org](http://www.tboox.org)
* Community：[tboox@community](https://github.com/tboox/community/issues)

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


