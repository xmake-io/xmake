# A make-like build utility based on Lua 

[![Build Status](https://api.travis-ci.org/waruqi/xmake.svg)](https://travis-ci.org/waruqi/xmake) [![Build status](https://ci.appveyor.com/api/projects/status/cop0jof7vs6as34r?svg=true)](https://ci.appveyor.com/project/waruqi/xmake) [![Join the chat at https://gitter.im/waruqi/tboox](https://badges.gitter.im/waruqi/tboox.svg)](https://gitter.im/waruqi/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![donate](http://tboox.org/static/img/donate.svg)](http://xmake.io/pages/donation.html#donate)

## Introduction ([中文](/README_zh.md))

xmake is a make-like build utility based on lua. 

The project focuses on making development and building easier and provides many features (.e.g package, install, plugin, macro, action, option, task ...), 
so that any developer can quickly pick it up and enjoy the productivity boost when developing and building project.

If you want to known more, please refer to:

* [Documents](https://github.com/waruqi/xmake/wiki/%E7%9B%AE%E5%BD%95)
* [Github](https://github.com/waruqi/xmake)
* [HomePage](http://www.xmake.io)

#### Features

- Create projects and supports many project templates
- Support c/c++, objc/c++, swift and assembly language
- Automatically probe the host environment and configure project 
- Provide some built-in actions (config, build, package, clean, install, uninstall and run)
- Provide some built-in plugins (doxygen, macro, project) 
- Provide some built-in macros (batch packaging)
- Describe the project file using lua script, more flexible and simple
- Custom packages, platforms, plugins, templates, tasks, macros, options and actions
- Do not generate makefile and build project directly
- Support multitasking with argument: -j 
- Check includes dependence automatically
- Run and debug the target program
- Generate IDE project file

#### Actions

- config: Configure project before building. 
- global: Configure the global options for xmake.
- build: Build project.
- clean: Remove all binary and temporary files.
- create: Create a new project using template.
- package: Package the given target
- install: Install the project binary files.
- uninstall: Uninstall the project binary files.
- run: Run the project target.

#### Plugins

- The doxygen plugin: Make doxygen document from source codes
- The macro plugin: Record and playback commands 
- The hello plugin: A simple plugin demo to show 'hello xmake!'
- The project plugin: Create the project file for IDE (.e.g makefile, vs2002 - vs2017)

#### Languages

- C/C++
- Objc/Objc++
- Swift
- Assembly

#### Platforms

- Windows (x86, x64, amd64, x86_amd64)
- Macosx (i386, x86_64)
- Linux (i386, x86_64, cross-toolchains ...)
- Android (armv5te, armv6, armv7-a, armv8-a, arm64-v8a)
- iPhoneos (armv7, armv7s, arm64, i386, x86_64)
- Watchos (armv7k, i386)
- Mingw (i386, x86_64)

#### Todolist

- Manage package and dependencies
- Download package automatically
- Create package repository for porting other third-party source codes, it's goal is that one people port it and many people shared.
- Implement more plugins(.e.g generate .deb, .rpm package)

#### Examples

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

#### Documents

* [Documents](https://github.com/waruqi/xmake/wiki/documents)
* [Codes](https://github.com/waruqi/xmake)

#### Projects

Some projects using xmake:

* [tbox](https://github.com/waruqi/tbox)
* [gbox](https://github.com/waruqi/gbox)
* [libsvx](https://github.com/caikelun/libsvx)
* [more](https://github.com/waruqi/xmake/wiki/xmake-projects)

#### Contacts

* Email：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* Homepage：[TBOOX Open Source Project](http://www.tboox.org/cn)
* Community：[TBOOX Open Source Community](http://www.tboox.org/forum)

