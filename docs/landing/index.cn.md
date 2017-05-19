---
layout: default.cn
title: {{ site.name }}
---

## 安装

#### 使用curl

```bash
$ bash <(curl -fsSL https://github.com/tboox/xmake/raw/master/scripts/get.sh)
```

#### 使用wget

```bash
$ bash <(wget https://github.com/tboox/xmake/raw/master/scripts/get.sh -O -)
```

#### 使用powershell

```bash
$ Invoke-Expression (Invoke-Webrequest 'https://github.com/tboox/xmake/raw/master/scripts/get.ps1' -UseBasicParsing).Content
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
* iOS app2ipa插件

## 使用演示

[![usage_demo](http://tboox.org/static/img/xmake/build_demo.gif)](https://github.com/tboox/xmake)

## 联系方式

* 邮箱：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* 主页：[TBOOX开源工程](http://www.tboox.org/cn)
* 社区：[TBOOX开源社区](http://www.tboox.org/forum)
* 聊天：[![Join the chat at https://gitter.im/tboox/tboox](https://badges.gitter.im/tboox/tboox.svg)](https://gitter.im/tboox/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
* QQ群：343118190
* 微信公众号：tboox-os
