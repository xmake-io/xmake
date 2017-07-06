---
search: en
---

<p>
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
    <a href="https://codecov.io/gh/tboox/xmake">
      <img src="https://img.shields.io/codecov/c/github/tboox/xmake/master.svg?style=flat-square" alt="Coverage" />
    </a>
    <a href="https://github.com/tboox/xmake/releases">
      <img src="https://img.shields.io/github/release/tboox/xmake.svg?style=flat-square" alt="Github All Releases" />
    </a>
    <a href="https://github.com/tboox/xmake/releases">
      <img src="https://img.shields.io/github/downloads/tboox/xmake/total.svg?style=flat-square" alt="Downloads" />
    </a>
  </div>
  <div>
    <a href="https://github.com/tboox/xmake/blob/master/LICENSE.md">
      <img src="https://img.shields.io/github/license/tboox/xmake.svg?colorB=f48041&style=flat-square" alt="license" />
    </a>
    <a href="https://gitter.im/tboox/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge">
      <img src="https://img.shields.io/gitter/room/tboox/tboox.svg?style=flat-square&colorB=96c312" alt="Gitter" />
    </a>
    <a href="http://xmake.io/pages/donation.html#donate">
      <img src="https://img.shields.io/badge/donate-us-orange.svg?style=flat-square" alt="Donate" />
    </a>
  </div>

  <p>A make-like build utility based on Lua</p>
</div>
</p>

## Introduction 

xmake is a make-like build utility based on lua. 

The project focuses on making development and building easier and provides many features (.e.g package, install, plugin, macro, action, option, task ...), 
so that any developer can quickly pick it up and enjoy the productivity boost when developing and building project.

## Installation

#### Master

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

#### Windows

1. Download xmake windows installer from [Releases](https://github.com/tboox/xmake/releases)
2. Run xmake-[version].exe

#### MacOS

```bash
$ brew install xmake
```

#### Linux

On Archlinux:

```bash
$ yaourt xmake
```

On Ubuntu:

```bash
$ sudo add-apt-repository ppa:tboox/xmake
$ sudo apt-get update
$ sudo apt-get install xmake
```

Or add xmake package source manually:

```
deb http://ppa.launchpad.net/tboox/xmake/ubuntu yakkety main 
deb-src http://ppa.launchpad.net/tboox/xmake/ubuntu yakkety main 
```

Then we run:

```bash
$ sudo apt-get update
$ sudo apt-get install xmake
```

Or download deb package to install it:

1. Download xmake `.deb` install package from [Releases](https://github.com/tboox/xmake/releases) 
2. Run `dpkg -i xmake-xxxx.deb`

#### Compilation

```bash
$ git clone git@github.com:waruqi/xmake.git
$ cd ./xmake
$ ./scripts/get.sh __local__
```

## Quick Start

![UsageDemo](http://tboox.org/static/img/xmake/build_demo.gif)

#### Create Project

```bash
$ xmake create -l c -P ./hello
```

And xmake will generate some files for c language project:

```
hello
├── src
│   └── main.c
└── xmake.lua
```

It is a simple console program only for printing `hello xmake!`

The content of `xmake.lua` is very simple:

```lua
target("hello")
    set_kind("binary")
    add_files("src/*.c") 
```

Support languages:

* c/c++
* objc/c++
* asm
* swift
* dlang
* golang
* rust

<p class="tip">
    If you want to known more options, please run: `xmake create --help`
</p>

#### Build Project

```bash
$ xmake
```

#### Run Program

```bash
$ xmake run hello
```

#### Debug Program

```bash
$ xmake run -d hello 
```

It will start the debugger (.e.g lldb, gdb, windbg, vsjitdebugger, ollydbg ..) to load our program.

```bash
[lldb]$target create "build/hello"
Current executable set to 'build/hello' (x86_64).
[lldb]$b main
Breakpoint 1: where = hello`main, address = 0x0000000100000f50
[lldb]$r
Process 7509 launched: '/private/tmp/hello/build/hello' (x86_64)
Process 7509 stopped
* thread #1: tid = 0x435a2, 0x0000000100000f50 hello`main, queue = 'com.apple.main-thread', stop reason = breakpoint 1.1
    frame #0: 0x0000000100000f50 hello`main
hello`main:
->  0x100000f50 <+0>:  pushq  %rbp
    0x100000f51 <+1>:  movq   %rsp, %rbp
    0x100000f54 <+4>:  leaq   0x2b(%rip), %rdi          ; "hello world!"
    0x100000f5b <+11>: callq  0x100000f64               ; symbol stub for: puts
[lldb]$
```

<p class="tip">
    You can also use short command option, for exmaple: `xmake r` or `xmake run`
</p>

## Configuration

Set compilation configuration before building project with command `xmake f|config`.

And if you want to known more options, please run: `xmake f --help`。

<p class="tip">
    You can use short or long command option, for exmaple: <br>
    `xmake f` or `xmake config`.<br>
    `xmake f -p linux` or `xmake config --plat=linux`.
</p>

#### Target Platforms

##### Current Host

```bash
$ xmake
```

<p class="tip">
    XMake will detect the current host platform automatically and build project.
</p>

##### Linux

```bash
$ xmake f -p linux [-a i386|x86_64]
$ xmake
```

##### Android

```bash
$ xmake f -p android --ndk=~/files/android-ndk-r10e/ [-a armv5te|armv6|armv7-a|armv8-a|arm64-v8a]
$ xmake
```

If you want to set the other android toolchains, you can use [--toolchains](#-toolchains) option.

For example:

```bash
$ xmake f -p android --ndk=~/files/android-ndk-r10e/ -a arm64-v8a --toolchains=~/files/android-ndk-r10e/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64/bin
```

The [--toolchains](#-toolchains) option is used to set `bin` directory of toolchains.
    
<p class="tip">
Please attempt to set `--arch=` option if it had failed to check compiler.
</p>

##### iPhoneOS

```bash
$ xmake f -p iphoneos [-a armv7|armv7s|arm64|i386|x86_64]
$ xmake
```

##### Windows

```bash
$ xmake f -p windows [-a x86|x64]
$ xmake
```

##### Mingw

```bash
$ xmake f -p mingw --sdk=/usr/local/i386-mingw32-4.3.0/ [-a i386|x86_64]
$ xmake
``` 

##### Apple WatchOS

```bash
$ xmake f -p watchos [-a i386|armv7k]
$ xmake
```

##### Cross Compilation

```bash
$ xmake f -p linux --sdk=/usr/local/arm-linux-gcc/ [--toolchains=/sdk/bin] [--cross=arm-linux-]
$ xmake
``` 

| Configuration Option         | Description                                  |
| ---------------------------- | -------------------------------------------- |
| [--sdk](#-sdk)               | Set the sdk root directory of toolchains     |
| [--toolchains](#-toolchains) | Set the `bin` directory of toolchains        |
| [--cross](#-cross)           | Set the prefix of compilation tools          |
| [--as](#-as)                 | Set `asm` assembler                          |
| [--cc](#-cc)                 | Set `c` compiler                             |
| [--cxx](#-cxx)               | Set `c++` compiler                           |
| [--mm](#-mm)                 | Set `objc` compiler                          |
| [--mxx](#-mxx)               | Set `objc++` compiler                        |
| [--sc](#-sc)                 | Set `swift` compiler                         |
| [--gc](#-gc)                 | Set `golang` compiler                        |
| [--dc](#-dc)                 | Set `dlang` compiler                         |
| [--rc](#-rc)                 | Set `rust` compiler                          |
| [--ld](#-ld)                 | Set `c/c++/objc/asm` linker                  |
| [--sh](#-sh)                 | Set `c/c++/objc/asm` shared library linker   |
| [--ar](#-ar)                 | Set `c/c++/objc/asm` static library archiver |
| [--sc-ld](#-sc-ld)           | Set `swift` linker                           |
| [--sc-sh](#-sc-sh)           | Set `swift` shared library linker            |
| [--gc-ld](#-gc-ld)           | Set `golang` linker                          |
| [--gc-ar](#-gc-ar)           | Set `golang` static library archiver         |
| [--dc-ld](#-dc-ld)           | Set `dlang` linker                           |
| [--dc-sh](#-dc-sh)           | Set `dlang` shared library linker            |
| [--dc-ar](#-dc-ar)           | Set `dlang` static library archiver          |
| [--rc-ld](#-rc-ld)           | Set `rust` linker                            |
| [--rc-sh](#-rc-sh)           | Set `rust` shared library linker             |
| [--rc-ar](#-rc-ar)           | Set `rust` static library archiver           |
| [--asflags](#-asflags)       | Set `asm` assembler option                   |
| [--cflags](#-cflags)         | Set `c` compiler option                      |
| [--cxflags](#-cxflags)       | Set `c/c++` compiler option                  |
| [--cxxflags](#-cxxflags)     | Set `c++` compiler option                    |
| [--mflags](#-mflags)         | Set `objc` compiler option                   |
| [--mxflags](#-mxflags)       | Set `objc/c++` compiler option               |
| [--mxxflags](#-mxxflags)     | Set `objc++` compiler option                 |
| [--scflags](#-scflags)       | Set `swift` compiler option                  |
| [--gcflags](#-gcflags)       | Set `golang` compiler option                 |
| [--dcflags](#-dcflags)       | Set `dlang` compiler option                  |
| [--rcflags](#-rcflags)       | Set `rust` compiler option                   |
| [--ldflags](#-ldflags)       | Set  linker option                           |
| [--shflags](#-shflags)       | Set  shared library linker option            |
| [--arflags](#-arflags)       | Set  static library archiver option          |

<p class="tip">
if you want to known more options, please run: `xmake f --help`。
</p>

###### --sdk

- Set the sdk root directory of toolchains

xmake provides a convenient and flexible cross-compiling support.
In most cases, we need not to configure complex toolchains prefix, for example: `arm-linux-`

As long as this toolchains meet the following directory structure:

```
/home/toolchains_sdkdir
   - bin
       - arm-linux-gcc
       - arm-linux-ld
       - ...
   - lib
       - libxxx.a
   - include
       - xxx.h
```

Then，we can only configure the sdk directory and build it.

```bash
$ xmake f -p linux --sdk=/home/toolchains_sdkdir
$ xmake
```

xmake will detect the prefix: arm-linux- and add the include and library search directory automatically.

```
-I/home/toolchains_sdkdir/include -L/home/toolchains_sdkdir/lib
```

###### --toolchains

- Set the `bin` directory of toolchains

We need set it manually if the toolchains /bin directory is in other places, for example:

```bash
$ xmake f -p linux --sdk=/home/toolchains_sdkdir --toolchains=/usr/opt/bin
$ xmake
```

###### --cross

- Set the prefix of compilation tools

For example, under the same toolchains directory at the same time, there are two different compilers:

```
/opt/bin
 - armv7-linux-gcc
 - aarch64-linux-gcc
```

If we want to use the `armv7-linux-gcc` compiler, we can run the following command:

```bash
$ xmake f -p linux --sdk=/usr/toolsdk --toolchains=/opt/bin --cross=armv7-linux-
```

###### --as

- Set `asm` assembler

```bash
$ xmake f -p linux --sdk=/user/toolsdk --as=armv7-linux-as
```

If the 'AS' environment variable exists, it will use the values specified in the current environment variables.

###### --cc

- Set c compiler

```bash
$ xmake f -p linux --sdk=/user/toolsdk --cc=armv7-linux-clang
```

If the 'CC' environment variable exists, it will use the values specified in the current environment variables.

###### --cxx

- Set `c++` compiler

```bash
$ xmake f -p linux --sdk=/user/toolsdk --cxx=armv7-linux-clang++
```

If the 'CXX' environment variable exists, it will use the values specified in the current environment variables.

###### --ld

- Set `c/c++/objc/asm` linker

```bash
$ xmake f -p linux --sdk=/user/toolsdk --ld=armv7-linux-clang++
```

If the 'LD' environment variable exists, it will use the values specified in the current environment variables.

###### --sh

- Set `c/c++/objc/asm` shared library linker

```bash
$ xmake f -p linux --sdk=/user/toolsdk --sh=armv7-linux-clang++
```

If the 'SH' environment variable exists, it will use the values specified in the current environment variables.

###### --ar

- Set `c/c++/objc/asm` static library archiver

```bash
$ xmake f -p linux --sdk=/user/toolsdk --ar=armv7-linux-ar
```

If the 'AR' environment variable exists, it will use the values specified in the current environment variables.

#### Global Configuration

You can save to the global configuration for simplfying operation.

For example:

```bash
$ xmake g --ndk=~/files/android-ndk-r10e/
```

Now, we config and build project for android again.

```bash
$ xmake f -p android
$ xmake
```

<p class="tip">
    You can use short or long command option, for exmaple: `xmake g` or `xmake global`.<br>
</p>

#### Clean Configuration

We can clean all cached configuration and re-configure projecct.

```bash
$ xmake f -c
$ xmake
```

or 

```bash
$ xmake f -p iphoneos -c
$ xmake
```

## FAQ

#### How to get verbose command-line arguments info?

Get the help info of the main command.

```bash
$ xmake [-h|--help]
``` 

Get the help info of the configuration command.

```bash
$ xmake f [-h|--help]
``` 

Get the help info of the givent action or plugin command.

```bash
$ xmake [action|plugin] [-h|--help]
``` 

For example:

```bash
$ xmake run --help
``` 

#### How to suppress all output info?

```bash
$ xmake [-q|--quiet]
```

#### How to do if xmake fails?

Please attempt to clean configuration and rebuild it first.

```bash
$ xmake f -c
$ xmake
```

If it fails again, please add `-v` or `--verbose` options to get more verbose info.

For exmaple: 

```hash
$ xmake -v 
$ xmake --verbose
```

And add `--backtrace` to get the verbose backtrace info, then you can submit these infos to [issues](https://github.com/tboox/xmake/issues).

```bash
$ xmake -v --backtrace
```

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


