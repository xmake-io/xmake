---
layout: default
title: {{ site.name }}
---

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

[![usage_demo](http://tboox.org/static/img/xmake/usage_demo.gif)](https://github.com/tboox/xmake)

## Contacts

* Email：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* Homepage：[TBOOX Open Source Project](http://www.tboox.org/cn)
* Community：[TBOOX Open Source Community](http://www.tboox.org/forum)
* ChatRoom：[![Join the chat at https://gitter.im/tboox/tboox](https://badges.gitter.im/tboox/tboox.svg)](https://gitter.im/tboox/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
