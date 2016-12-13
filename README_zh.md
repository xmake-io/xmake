## 一个基于Lua的轻量级跨平台自动构建工具

[![Build Status](https://api.travis-ci.org/waruqi/xmake.svg)](https://travis-ci.org/waruqi/xmake) [![Build status](https://ci.appveyor.com/api/projects/status/cop0jof7vs6as34r?svg=true)](https://ci.appveyor.com/project/waruqi/xmake) [![Join the chat at https://gitter.im/waruqi/tboox](https://badges.gitter.im/waruqi/tboox.svg)](https://gitter.im/waruqi/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![donate](http://tboox.org/static/img/donate.svg)](http://xmake.io/pages/donation.html#donate)

## 简介

XMake是一个基于Lua的轻量级跨平台自动构建工具，支持在各种主流平台上构建项目

xmake的目标是开发者更加关注于项目本身开发，简化项目的描述和构建，并且提供平台无关性，使得一次编写，随处构建

它跟cmake、automake、premake有点类似，但是机制不同，它默认不会去生成IDE相关的工程文件，采用直接编译，并且更加的方便易用
采用lua的工程描述语法更简洁直观，支持在大部分常用平台上进行构建，以及交叉编译

并且xmake提供了创建、配置、编译、打包、安装、卸载、运行等一些actions，使得开发和构建更加的方便和流程化。

不仅如此，它还提供了许多更加高级的特性，例如插件扩展、脚本宏记录、批量打包、自动文档生成等等。。

如果你想要了解更多，请参考：

* [在线文档](https://github.com/waruqi/xmake/wiki/%E7%9B%AE%E5%BD%95)
* [在线源码](https://github.com/waruqi/xmake)
* [项目主页](http://www.xmake.io/cn)

#### 支持特性

- 支持windows、mac、linux、ios、android等平台，自动检测不同平台上的编译工具链（也可手动配置）
   编译windows项目采用原生vs的工具链，不需要使用cygwin、mingw（当然这些也支持）

- 支持自定义平台编译配置，可以很方便的扩展第三方平台支持

- 采用lua脚本语法描述项目，描述规则简单高效，逻辑规则可灵活修改，并且不会生成相关平台的工程文件，是工程更加简单明了

- 支持创建模板工程、配置项目、编译项目、运行、打包、安装和卸载等常用功能（后续还会增加：自动生成文档、调试等模块）

- 支持编译c/c++/objc/swift成静态库、动态库、命令行可执行程序

- 提供丰富的工程描述api，使用简单灵活，例如添加编译文件只需（还支持过滤排除）：

   `add_files("src/*.c", "src/asm/**.S", "src/*.m")`

- 支持头文件、接口、链接库依赖、类型的自动检测，并可自动生成配置头文件config.h

- 支持自定义编译配置开关，例如如果在工程描述文件中增加了`enable_xxx`的开关，那么配置编译的时候就可以手动进行配置来启用它：

   `xmake config --enable_xxx=y`

- 提供一键打包功能，不管在哪个平台上进行打包，都只需要执行一条相同的命令，非常的方便

- 支持全局配置，一些常用的项目配置，例如工具链、规则描述等等，都可以进行全局配置，这样就不需要每次编译不同工程，都去配置一遍

- 除了可以自动检测依赖模块，也支持手动强制配置模块，还有各种编译flags。

- 支持插件扩展、平台扩展、模板扩展、选项自定义等高级功能

- 提供一些内置的常用插件（例如：自动生成doxygen文档插件，宏脚本记录和运行插件）

- 宏记录插件里面提供了一些内置的宏脚本（例如：批量打包一个平台的所有archs等），也可以在命令行中手动记录宏并回放执行

- 提供强大的task任务机制

- 不依赖makefile和make，实现直接编译，内置自动多任务加速编译, xmake是一个真正的构架工具，而不仅仅是一个工程文件生成器

- 自动检测ccache，进行自动缓存提升构建速度

- 自动检测头文件依赖，并且快速自动构建修改的文件

- 调试器支持，实现直接加载运行调试

- 提供产生IDE工程文件的插件（支持vs2002 - vs2017）

#### 常用Actions

- config: 构建之前的编译参数配置
- global: 配置一些全局参数
- build: 构建项目
- clean: 清理一些二进制文件、临时文件
- create: 使用模板创建新工程
- package: 打包指定目标
- install: 安装编译后的目标文件
- uninstall: 卸载安装的所有文件
- run: 运行可执行的项目目标

#### 一些内置插件

- doxygen文档生成插件: 从指定源码目录生成doxygen文档
- 宏记录脚本插件: 记录和回放宏脚本，简化重复的命令操作（例如：批量打包。。）
- hello插件: 插件开发demo
- 工程文件生成插件: 创建IDE的工程文件 (目前支持：makefile, vs2002 - vs2017，后续支持：xcode等等)
- iOS app2ipa插件

#### 支持编译语言

- C/C++
- Objc/Objc++
- Swift
- Assembly

#### 支持的构建平台

- Windows (x86, x64, amd64, x86_amd64)
- Macosx (i386, x86_64)
- Linux (i386, x86_64, cross-toolchains ...)
- Android (armv5te, armv6, armv7-a, armv8-a, arm64-v8a)
- iPhoneos (armv7, armv7s, arm64, i386, x86_64)
- Watchos (armv7k, i386)
- Mingw (i386, x86_64)

#### 后续任务

- 自动包依赖管理和下载
- 创建移植仓库，实现`一人移植，多人共享`
- 更多的插件开发(例如：Xcode工程生成，生成.deb, .rpm的安装包)

#### 简单例子

创建一个c++ console项目：

```bash
    xmake create -l c++ -t 1 console
or  xmake create --language=c++ --template=1 console
```

工程描述文件：xmake.lua

```lua
target("console")
    set_kind("binary")
    add_files("src/*.c") 
```

配置工程：

   这个是可选的步骤，如果只想编译当前主机平台的项目，是可以不用配置的，默认编译release版本。

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

编译工程：
     
```bash
   xmake
or xmake -r
or xmake --rebuild
```

运行目标：

```bash
   xmake r console
or xmake run console
```

调试目标：

```bash
   xmake r -d console
or xmake run -d console
```

打包所有：

```bash
   xmake p
or xmake package
or xmake package console
or xmake package -o /tmp
or xmake package --output=/tmp
```

通过宏脚本打包所有架构:
   
```bash
   xmake m package 
or xmake m package -p iphoneos
or xmake m package -p macosx -f "-m debug" -o /tmp/
or xmake m package --help
```

安装目标：

```bash
   xmake i
or xmake install
or xmake install console
or xmake install -o /tmp
or xmake install --output=/tmp
```

详细使用方式和参数说明，请参考[文档](https://github.com/waruqi/xmake/wiki/%E7%9B%AE%E5%BD%95)
或者运行：

```bash
   xmake -h
or xmake --help
or xmake config --help
or xmake package --help
or xmake macro --help
...
```

#### 一些使用xmake的项目：

* [tbox](https://github.com/waruqi/tbox)
* [gbox](https://github.com/waruqi/gbox)
* [libsvx](https://github.com/caikelun/libsvx)
* [更多项目](https://github.com/waruqi/xmake/wiki/%E4%BD%BF%E7%94%A8xmake%E7%9A%84%E5%BC%80%E6%BA%90%E5%BA%93)

#### 简单例子

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

#### 联系方式

* 邮箱：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* 主页：[TBOOX开源工程](http://www.tboox.org/cn)
* 社区：[TBOOX开源社区](http://www.tboox.org/forum)
* QQ群：343118190
* 微信公众号：tboox-os

