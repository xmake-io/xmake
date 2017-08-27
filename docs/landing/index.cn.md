---
layout: default.cn
title: {{ site.name }}
---

## 安装

#### 使用curl

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tboox/xmake/master/scripts/get.sh)
```

#### 使用wget

```bash
bash <(wget https://raw.githubusercontent.com/tboox/xmake/master/scripts/get.sh -O -)
```

#### 使用powershell

```bash
Invoke-Expression (Invoke-Webrequest 'https://raw.githubusercontent.com/tboox/xmake/master/scripts/get.ps1' -UseBasicParsing).Content
```

## 简单的工程描述

```lua
target("console")
    set_kind("binary")
    add_files("src/*.c") 
```

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

## 支持特性

* Tasks
* Macros
* Actions
* Options
* Plugins
* Modules
* Templates

## 支持平台

* Windows (x86, x64)
* Macosx (i386, x86_64)
* Linux (i386, x86_64, cross-toolchains ...)
* Android (armv5te, armv6, armv7-a, armv8-a, arm64-v8a)
* iPhoneOS (armv7, armv7s, arm64, i386, x86_64)
* WatchOS (armv7k, i386)
* Mingw (i386, x86_64)

## 支持语言

* C/C++
* Objc/Objc++
* Swift
* Assembly
* Golang
* Rust
* Dlang

## 内置插件

* 宏记录脚本和回放插件
* 加载自定义lua脚本插件
* 生成IDE工程文件插件（makefile, vs2002 - vs2017, ...）
* 生成doxygen文档插件

## 更多插件

请到插件仓库进行下载安装: [xmake-plugins](https://github.com/tboox/xmake-plugins).

## 更多例子

Debug和Release模式：

```lua
if is_mode("debug") then
    set_symbols("debug")
    set_optimize("none")
end

if is_mode("release") then
    set_symbols("hidden")
    set_optimize("fastest")
    set_strip("all")
end

target("console")
    set_kind("binary")
    add_files("src/*.c") 
```

自定义脚本：

```lua
target("test")
    set_kind("static")
    add_files("src/*.cpp")
    after_build(function (target)
        print("build %s ok!", target:targetfile())
    end)
```

使用扩展模块：

```lua
target("test")
    set_kind("shared")
    add_files("src/*.c")
    on_load(function (target)
        import("lib.detect.find_package")
        target:add(find_package("zlib"))
    end)
```

## 项目例子

一些使用xmake的项目：

* [tbox](https://github.com/tboox/tbox)
* [gbox](https://github.com/tboox/gbox)
* [vm86](https://github.com/tboox/vm86)
* [更多](https://github.com/vm86/xmake/wiki/%E4%BD%BF%E7%94%A8xmake%E7%9A%84%E5%BC%80%E6%BA%90%E5%BA%93)

## 演示视频

[![asciicast](https://asciinema.org/a/133693.png)](https://asciinema.org/a/133693)

## 联系方式

* 邮箱：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* 主页：[tboox.org](http://www.tboox.org/cn)
* 社区：[TBOOX开源社区](https://github.com/tboox/community/issues)
* 聊天：[![Join the chat at https://gitter.im/tboox/tboox](https://badges.gitter.im/tboox/tboox.svg)](https://gitter.im/tboox/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
* 源码：[Github](https://github.com/tboox/xmake), [Gitee](https://gitee.com/tboox/xmake)
* QQ群：343118190
* 微信公众号：tboox-os

