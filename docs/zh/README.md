---
nav: zh
search: zh
---

# 一个基于Lua的轻量级跨平台自动构建工具

[![Build Status](https://api.travis-ci.org/tboox/xmake.svg?branch=master)](https://travis-ci.org/tboox/xmake) [![Build status](https://ci.appveyor.com/api/projects/status/ry9oa2mxrj8hk613/branch/master?svg=true)](https://ci.appveyor.com/project/waruqi/xmake/branch/master) [![Join the chat at https://gitter.im/tboox/tboox](https://badges.gitter.im/tboox/tboox.svg)](https://gitter.im/tboox/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![donate](http://tboox.org/static/img/donate.svg)](http://xmake.io/cn/pages/donation.html#donate)

[![logo](http://tboox.org/static/img/xmake/logo256.png)](http://xmake.io/cn)

## 简介

XMake是一个基于Lua的轻量级跨平台自动构建工具，支持在各种主流平台上构建项目

xmake的目标是开发者更加关注于项目本身开发，简化项目的描述和构建，并且提供平台无关性，使得一次编写，随处构建

它跟cmake、automake、premake有点类似，但是机制不同，它默认不会去生成IDE相关的工程文件，采用直接编译，并且更加的方便易用
采用lua的工程描述语法更简洁直观，支持在大部分常用平台上进行构建，以及交叉编译

并且xmake提供了创建、配置、编译、打包、安装、卸载、运行等一些actions，使得开发和构建更加的方便和流程化。

不仅如此，它还提供了许多更加高级的特性，例如插件扩展、脚本宏记录、批量打包、自动文档生成等等。。

## 安装

#### Master版本

##### 使用curl

```bash
$ bash <(curl -fsSL https://github.com/tboox/xmake/raw/master/scripts/get.sh)
```

##### 使用wget

```bash
$ bash <(wget https://github.com/tboox/xmake/raw/master/scripts/get.sh -O -)
```

##### 使用powershell

```bash
$ Invoke-Expression (Invoke-Webrequest 'https://github.com/tboox/xmake/raw/master/scripts/get.ps1' -UseBasicParsing).Content
```

#### Windows

1. 从 [Releases](https://github.com/tboox/xmake/releases) 上下载windows安装包
2. 运行安装程序 xmake-[version].exe

#### MacOS

```bash
$ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
$ brew install xmake
```

或者：

1. 从 [Releases](https://github.com/tboox/xmake/releases) 上下载pkg安装包
2. 双击运行

或者安装master版本:

```bash
# 使用homebrew安装master版本
$ brew install xmake --HEAD

# 或者直接调用shell下载安装
$ bash <(curl -fsSL https://raw.githubusercontent.com/tboox/xmake/master/scripts/get.sh)
```

#### Linux

在archlinux上安装：

```bash
$ yaourt xmake
```

在ubuntu上安装：

```bash
$ sudo add-apt-repository ppa:tboox/xmake
$ sudo apt-get update
$ sudo apt-get install xmake
```

或者手动添加包源：

```
deb http://ppa.launchpad.net/tboox/xmake/ubuntu yakkety main 
deb-src http://ppa.launchpad.net/tboox/xmake/ubuntu yakkety main 
```

然后执行：

```bash
$ sudo apt-get update
$ sudo apt-get install xmake
```

或者下载deb包来安装：

1. 从 [Releases](https://github.com/tboox/xmake/releases) 上下载deb安装包
2. 运行: `dpkg -i xmake-xxxx.deb`

在`redhat/centos`上安装：

1. 从 [Releases](https://github.com/tboox/xmake/releases) 上下载rpm安装包
2. 运行: `yum install xmake-xxx.rpm --nogpgcheck`

#### 编译安装

```bash
$ git clone git@github.com:waruqi/xmake.git
$ cd ./xmake
$ ./scripts/get.sh __local__
```

## 快速开始

![UsageDemo](http://tboox.org/static/img/xmake/build_demo.gif)

#### 创建工程

创建一个名叫`hello`的`c`控制台工程：

```bash
$ xmake create -l c -P ./hello
```

执行完后，将会生成一个简单工程结构：

```
hello
├── src
│   └── main.c
└── xmake.lua
```

其中`xmake.lua`是工程描述文件，内容非常简单，告诉xmake添加`src`目录下的所有`.c`源文件：

```lua
target("hello")
    set_kind("binary")
    add_files("src/*.c") 
```

目前支持的语言如下：

* c/c++
* objc/c++
* asm
* swift
* dlang
* golang
* rust

<p class="tip">
    如果你想了解更多参数选项，请运行: `xmake create --help`
</p>

#### 构建工程

```bash
$ xmake
```

#### 运行程序

```bash
$ xmake run hello
```

#### 调试程序

```bash
$ xmake run -d hello 
```

xmake将会使用系统自带的调试器去加载程序运行，目前支持：lldb, gdb, windbg, vsjitdebugger, ollydbg 等各种调试器。

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
    你也可以使用简写的命令行选项，例如: `xmake r` 或者 `xmake run`
</p>

## 配置

通过`xmake f|config`配置命令，设置构建前的相关配置信息，详细参数选项，请运行: `xmake f --help`。

<p class="tip">
    你可以使用命令行缩写来简化输入，也可以使用全名，例如: <br>
    `xmake f` 或者 `xmake config`.<br>
    `xmake f -p linux` 或者 `xmake config --plat=linux`.
</p>

#### 目标平台

##### 主机平台

```bash
$ xmake
```

<p class="tip">
    xmake将会自动探测当前主机平台，默认自动生成对应的目标程序。
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

如果要手动指定ndk中具体某个工具链，而不是使用默认检测的配置，可以通过[--toolchains](#-toolchains)来设置，例如：

```bash
$ xmake f -p android --ndk=~/files/android-ndk-r10e/ -a arm64-v8a --toolchains=~/files/android-ndk-r10e/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64/bin
```

[--toolchains](#-toolchains)主要用于设置选择编译工具的具体bin目录，这个的使用跟[交叉编译](#交叉编译)中的[--toolchains](#-toolchains)的行为是一致的。

<p class="tip">
如果手动设置了`toolchains`的bin目录，没有通过检测，可以看下是否`--arch=`参数没有匹配对。
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

##### 交叉编译

```bash
$ xmake f -p linux --sdk=/usr/local/arm-linux-gcc/ [--toolchains=/sdk/bin] [--cross=arm-linux-]
$ xmake
``` 

其中：

| 参数名                       | 描述                             |
| ---------------------------- | -------------------------------- |
| [--sdk](#-sdk)               | 设置交叉工具链的sdk根目录        |
| [--toolchains](#-toolchains) | 设置工具链bin目录                |
| [--cross](#-cross)           | 设置交叉工具链工具前缀           |
| [--as](#-as)                 | 设置`asm`汇编器                  |
| [--cc](#-cc)                 | 设置`c`编译器                    |
| [--cxx](#-cxx)               | 设置`c++`编译器                  |
| [--mm](#-mm)                 | 设置`objc`编译器                 |
| [--mxx](#-mxx)               | 设置`objc++`编译器               |
| [--sc](#-sc)                 | 设置`swift`编译器                |
| [--gc](#-gc)                 | 设置`golang`编译器               |
| [--dc](#-dc)                 | 设置`dlang`编译器                |
| [--rc](#-rc)                 | 设置`rust`编译器                 |
| [--ld](#-ld)                 | 设置`c/c++/objc/asm`链接器       |
| [--sh](#-sh)                 | 设置`c/c++/objc/asm`共享库链接器 |
| [--ar](#-ar)                 | 设置`c/c++/objc/asm`静态库归档器 |
| [--sc-ld](#-sc-ld)           | 设置`swift`链接器                |
| [--sc-sh](#-sc-sh)           | 设置`swift`共享库链接器          |
| [--gc-ld](#-gc-ld)           | 设置`golang`链接器               |
| [--gc-ar](#-gc-ar)           | 设置`golang`静态库归档器         |
| [--dc-ld](#-dc-ld)           | 设置`dlang`链接器                |
| [--dc-sh](#-dc-sh)           | 设置`dlang`共享库链接器          |
| [--dc-ar](#-dc-ar)           | 设置`dlang`静态库归档器          |
| [--rc-ld](#-rc-ld)           | 设置`rust`链接器                 |
| [--rc-sh](#-rc-sh)           | 设置`rust`共享库链接器           |
| [--rc-ar](#-rc-ar)           | 设置`rust`静态库归档器           |
| [--asflags](#-asflags)       | 设置`asm`汇编编译选项            |
| [--cflags](#-cflags)         | 设置`c`编译选项                  |
| [--cxflags](#-cxflags)       | 设置`c/c++`编译选项              |
| [--cxxflags](#-cxxflags)     | 设置`c++`编译选项                |
| [--mflags](#-mflags)         | 设置`objc`编译选项               |
| [--mxflags](#-mxflags)       | 设置`objc/c++`编译选项           |
| [--mxxflags](#-mxxflags)     | 设置`objc++`编译选项             |
| [--scflags](#-scflags)       | 设置`swift`编译选项              |
| [--gcflags](#-gcflags)       | 设置`golang`编译选项             |
| [--dcflags](#-dcflags)       | 设置`dlang`编译选项              |
| [--rcflags](#-rcflags)       | 设置`rust`编译选项               |
| [--ldflags](#-ldflags)       | 设置链接选项                     |
| [--shflags](#-shflags)       | 设置共享库链接选项               |
| [--arflags](#-arflags)       | 设置静态库归档选项               |

<p class="tip">
如果你想要了解更多参数选项，请运行: `xmake f --help`。
</p>

###### --sdk

- 设置交叉工具链的sdk根目录

大部分情况下，都不需要配置很复杂的toolchains前缀，例如：`arm-linux-` 什么的

只要这个工具链的sdk目录满足如下结构（大部分的交叉工具链都是这个结构）：

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

那么，使用xmake进行交叉编译的时候，只需要进行如下配置和编译：

```bash
$ xmake f -p linux --sdk=/home/toolchains_sdkdir
$ xmake
```

这个时候，xmake会去自动探测，gcc等编译器的前缀名：`arm-linux-`，并且编译的时候，也会自动加上`链接库`和`头文件`的搜索选项，例如：

```
-I/home/toolchains_sdkdir/include -L/home/toolchains_sdkdir/lib
```

这些都是xmake自动处理的，不需要手动配置他们。。

###### --toolchains

- 设置工具链bin目录

对于不规则工具链目录结构，靠单纯地[--sdk](#-sdk)选项设置，没法完全检测通过的情况下，可以通过这个选项继续附加设置工具链的bin目录位置。

例如：一些特殊的交叉工具链的，编译器bin目录，并不在 `/home/toolchains_sdkdir/bin` 这个位置，而是独立到了 `/usr/opt/bin` 

```bash
$ xmake f -p linux --sdk=/home/toolchains_sdkdir --toolchains=/usr/opt/bin
$ xmake
```

###### --cross

- 设置交叉工具链工具前缀

像`aarch64-linux-android-`这种，通常如果你配置了[--sdk](-sdk)或者[--toolchains](-toolchains)的情况下，xmake会去自动检测的，不需要自己手动设置。

但是对于一些极特殊的工具链，一个目录下同时有多个cross前缀的工具bin混在一起的情况，你需要手动设置这个配置，来区分到底需要选用哪个bin。

例如，toolchains的bin目录下同时存在两个不同的编译器：

```
/opt/bin
 - armv7-linux-gcc
 - aarch64-linux-gcc
```

我们现在想要选用armv7的版本，则配置如下：

```bash
$ xmake f -p linux --sdk=/usr/toolsdk --toolchains=/opt/bin --cross=armv7-linux-
```

###### --as

- 设置`asm`汇编器

如果还要继续细分选择编译器，则继续追加相关编译器选项，例如：

```bash
$ xmake f -p linux --sdk=/user/toolsdk --as=armv7-linux-as
```

如果存在`AS`环境变量的话，会优先使用当前环境变量中指定的值。

###### --cc

- 设置c编译器

如果还要继续细分选择编译器，则继续追加相关编译器选项，例如：

```bash
$ xmake f -p linux --sdk=/user/toolsdk --cc=armv7-linux-clang
```

如果存在`CC`环境变量的话，会优先使用当前环境变量中指定的值。

###### --cxx

- 设置`c++`编译器

如果还要继续细分选择编译器，则继续追加相关编译器选项，例如：

```bash
$ xmake f -p linux --sdk=/user/toolsdk --cxx=armv7-linux-clang++
```

如果存在`CXX`环境变量的话，会优先使用当前环境变量中指定的值。

###### --ld

- 设置`c/c++/objc/asm`链接器

如果还要继续细分选择链接器，则继续追加相关编译器选项，例如：

```bash
$ xmake f -p linux --sdk=/user/toolsdk --ld=armv7-linux-clang++
```

如果存在`LD`环境变量的话，会优先使用当前环境变量中指定的值。

###### --sh

- 设置`c/c++/objc/asm`共享库链接器

```bash
$ xmake f -p linux --sdk=/user/toolsdk --sh=armv7-linux-clang++
```

如果存在`SH`环境变量的话，会优先使用当前环境变量中指定的值。

###### --ar

- 设置`c/c++/objc/asm`静态库归档器

```bash
$ xmake f -p linux --sdk=/user/toolsdk --ar=armv7-linux-ar
```

如果存在`AR`环境变量的话，会优先使用当前环境变量中指定的值。

#### 全局配置

我们也可以将一些常用配置保存到全局配置中，来简化频繁地输入：

例如:

```bash
$ xmake g --ndk=~/files/android-ndk-r10e/
```

现在，我们重新配置和编译`android`程序：

```bash
$ xmake f -p android
$ xmake
```

以后，就不需要每次重复配置`--ndk=`参数了。

<p class="tip">
    每个命令都有其简写，例如: `xmake g` 或者 `xmake global`.<br>
</p>

#### 清除配置

有时候，配置出了问题编译不过，或者需要重新检测各种依赖库和接口，可以加上`-c`参数，清除缓存的配置，强制重新检测和配置

```bash
$ xmake f -c
$ xmake
```

或者：

```bash
$ xmake f -p iphoneos -c
$ xmake
```

## 问答

#### 怎样获取更多参数选项信息？

获取主菜单的帮助信息，里面有所有action和plugin的列表描述。

```bash
$ xmake [-h|--help]
``` 

获取配置菜单的帮助信息，里面有所有配置选项的描述信息，以及支持平台、架构列表。

```bash
$ xmake f [-h|--help]
``` 

获取action和plugin命令菜单的帮助信息，里面有所有内置命令和插件任务的参数使用信息。

```bash
$ xmake [action|plugin] [-h|--help]
``` 

例如，获取`run`命令的参数信息:

```bash
$ xmake run --help
``` 

#### 怎样实现静默构建，不输出任何信息？

```bash
$ xmake [-q|--quiet]
```

#### 如果xmake运行失败了怎么办？

可以先尝试清除下配置，重新构建下：

```bash
$ xmake f -c
$ xmake
```

如果还是失败了，请加上 `-v` 或者 `--verbose` 选项重新执行xmake后，获取更加详细的输出信息

例如：

```hash
$ xmake -v 
$ xmake --verbose
```

并且可以加上 `--backtrace` 选项获取出错时的xmake的调试栈信息, 然后你可以提交这些信息到[issues](https://github.com/tboox/xmake/issues).

```bash
$ xmake -v --backtrace
```
