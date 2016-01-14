##The Automatic Cross-platform Build Tool [![Build Status](https://api.travis-ci.org/waruqi/xmake.svg)](https://travis-ci.org/waruqi/xmake) [![donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://github.com/waruqi/xmake/wiki/donate)

## introduction

xmake is a cross-platform automatic build tool.

It is similar to cmake, automake, premake, but more convenient and easy to use.

####features

1. create projects and supports many project templates
2. support c/c++, objc/c++, swift and assembly language
3. automatically probe the host environment and configure project 
4. build and rebuild project 
5. clean generated target files
6. package the project targets automatically
   - *.ipa for ios(feature)
   - *.apk for android(feature)
   - *.pkg for library
   - *.app for macosx(feature)
   - *.exe for windows
   - others

7. install target
8. run a given target
9. describe the project file using lua script, more flexible and simple
	```lua
	
	-- xmake.lua
    add_target("console")

        -- set kind
        set_kind("binary")

        -- add files
        add_files("src/*.c") 
    ```
10. custom platforms and toolchains
11. custom rules for package/compiler/linker

####examples

create a c++ console project：

```bash
    xmake create -l c++ -t 1 console
 or xmake create --language=c++ --template=1 console
```

project makefile：xmake.lua

```lua
add_target("console")
    set_kind("binary")
    add_files("src/*.c") 
```

configure project：

   This is optional, if you compile the targets only for linux, macosx and windows and the default compilation mode is release.

   The configuration arguments will be cached and you need not input all arguments each time.

```bash
   xmake f -p iphoneos -m debug
or xmake f --ldflags="-Lxxx -lxxx"
or xmake f --plat=macosx --arch=x86_64
or xmake config --plat=iphoneos --mode=debug
or xmake config --plat=iphonesimulator
or xmake config --plat=android --arch=armv7-a --ndk=xxxxx
or xmake config --cross=i386-mingw32- --toolchains=/xxx/bin
or xmake config --cxflags="-Dxxx -Ixxx"
or xmake config --help
```

compile project：
 
```bash
   xmake
or xmake -r
or xmake --rebuild
```

run target：

```bash
   xmake r console
or xmake run console
```

package all：

```bash
   xmake p
or xmake p --archs="armv7, arm64"
or xmake package
or xmake package console
or xmake package -o /tmp
or xmake package --output=/tmp
```

install targets：

```bash
   xmake i
or xmake install
or xmake install console
or xmake install -o /tmp
or xmake install --output=/tmp
```

If you need known more detailed usage，please refer to [documents](https://github.com/waruqi/xmake/wiki/documents)
or run：
```bash
   xmake -h
or xmake --help
or xmake config --help
or xmake package --help
...
```

The simple xmake.lua file:

```lua
-- the debug mode
if modes("debug") then
    
    -- enable the debug symbols
    set_symbols("debug")

    -- disable optimization
    set_optimize("none")
end

-- the release mode
if modes("release") then

    -- set the symbols visibility: hidden
    set_symbols("hidden")

    -- enable fastest optimization
    set_optimize("fastest")

    -- strip all symbols
    set_strip("all")
end

-- add target
add_target("test")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/*.c") 

```

####documents

* [documents](https://github.com/waruqi/xmake/wiki/documents)
* [codes](https://github.com/waruqi/xmake)

####projects

some projects using xmake:

* [tbox](https://github.com/waruqi/tbox)
* [gbox](https://github.com/waruqi/gbox)
* [libsvx](https://github.com/caikelun/libsvx)
* [more](https://github.com/waruqi/xmake/wiki/xmake-projects)

#### contacts

- email:   	    
	- waruqi@gmail.com
- website: 	    
	- http://www.tboox.org
	- http://www.tboox.net

####donate

xmake is a personal open source project, its development needs your help.
If you would like to support the development of xmake, welcome to donate to us.

Thanks!

#####paypal
<a href="http://tboox.net/%E6%8D%90%E5%8A%A9/">
<img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif" alt="paypal">
</a>

## 简介

XMake是一个跨平台自动构建工具，支持在各种主流平台上构建项目，类似cmake、automake、premake，但是更加的方便易用，工程描述语法更简洁直观，支持平台更多，并且集创建、配置、编译、打包、安装、卸载、运行于一体。

* [在线文档](https://github.com/waruqi/xmake/wiki/%E7%9B%AE%E5%BD%95)
* [在线源码](https://github.com/waruqi/xmake)

#### 支持特性

1. 支持windows、mac、linux、ios、android等平台，自动检测不同平台上的编译工具链（也可手动配置）
   编译windows项目采用原生vs的工具链，不需要使用cygwin、mingw（当然这些也支持）

2. 支持自定义平台编译配置，可以很方便的扩展第三方平台支持

3. 采用lua脚本语法描述项目，描述规则简单高效，逻辑规则可灵活修改，并且不会生成相关平台的工程文件，是工程更加简单明了

4. 支持创建模板工程、配置项目、编译项目、运行、打包、安装和卸载等常用功能（后续还会增加：自动生成文档、调试等模块）

5. 支持编译c/c++/objc/swift成静态库、动态库、命令行可执行程序（后续还会增加：mac、ios、android的app的生成规则）

6. 提供丰富的工程描述api，使用简单灵活，例如添加编译文件只需（还支持过滤排除）：

   `add_files("src/*.c", "src/asm/**.S", "src/*.m")`

7. 支持头文件、接口、链接库依赖、类型的自动检测，并可自动生成配置头文件config.h

8. 支持自定义编译配置开关，例如如果在工程描述文件中增加了enable_xxx的开关，那么配置编译的时候就可以手动进行配置来启用它：

   `xmake config --enable_xxx=true`

9. 提供一键打包功能，不管在哪个平台上进行打包，都只需要执行一条相同的命令，非常的方便

10. 支持自定义编译工具和规则，例如想要增加对masm/yasm的编译规则，只需将自己写的masm.lua/yasm.lua规则文件，放到当前项目目录下即可。。

11. 支持全局配置，一些常用的项目配置，例如工具链、规则描述等等，都可以进行全局配置，这样就不需要每次编译不同工程，都去配置一遍

12. 除了可以自动检测依赖模块，也支持手动强制配置模块，还有各种编译flags。

####简单例子

创建一个c++ console项目：

```bash
    xmake create -l c++ -t 1 console
 or xmake create --language=c++ --template=1 console
```

工程描述文件：xmake.lua

```lua
add_target("console")
    set_kind("binary")
    add_files("src/*.c") 
```

配置工程：

   这个是可选的步骤，如果只想编译当前主机平台的项目，是可以不用配置的，默认编译release版本。
   当然每次配置都会被缓存，不需要每次全部重新配置。

```bash
   xmake f -p iphoneos -m debug
or xmake f --ldflags="-Lxxx -lxxx"
or xmake f --plat=macosx --arch=x86_64
or xmake config --plat=iphoneos --mode=debug
or xmake config --plat=iphonesimulator
or xmake config --plat=android --arch=armv7-a --ndk=xxxxx
or xmake config --cross=i386-mingw32- --toolchains=/xxx/bin
or xmake config --cxflags="-Dxxx -Ixxx"
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

打包所有：

```bash
   xmake p
or xmake p --archs="armv7, arm64"
or xmake package
or xmake package console
or xmake package -o /tmp
or xmake package --output=/tmp
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
...
```

也可以参考一些使用xmake的项目：

* [tbox](https://github.com/waruqi/tbox)
* [gbox](https://github.com/waruqi/gbox)
* [libsvx](https://github.com/caikelun/libsvx)
* [更多项目](https://github.com/waruqi/xmake/wiki/%E4%BD%BF%E7%94%A8xmake%E7%9A%84%E5%BC%80%E6%BA%90%E5%BA%93)

####后续工作

1. 完善打包模块，支持对ios、mac、android的app进行一键打包和签名，生成.ipa、.apk、.app、.deb、.rmp的应用和安装包文件
2. 完善安装功能，支持对ios、android的app进行安装到设备
3. 实现调试功能，实现在pc、ios、android等设备进行真机调试
4. 实现自动生成doxygen文档功能
5. 增加一些实用的工程描述api，例如：下载api，可以自动下载缺少的依赖库等等。。
6. 解析automake、cmake的工程，并自动生成xmake的描述文件，实现无缝编译（如果这个实现成功的话，以后移植编译一些开源代码就更方便了）
7. 实现插件化管理，可以扩展自己的命令、脚本、api、编译平台和工具链

####简单例子

```lua
-- the debug mode
if modes("debug") then
    
    -- enable the debug symbols
    set_symbols("debug")

    -- disable optimization
    set_optimize("none")
end

-- the release mode
if modes("release") then

    -- set the symbols visibility: hidden
    set_symbols("hidden")

    -- enable fastest optimization
    set_optimize("fastest")

    -- strip all symbols
    set_strip("all")
end

-- add target
add_target("test")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/*.c") 

```

#### 联系方式

- email:   	    
	- waruqi@gmail.com
	- waruqi@126.com
- website: 	    
	- http://www.tboox.org
	- http://www.tboox.net
- qq(group):    
	- 343118190

####捐助

xmake是个人开源，它的发展需要您的帮助，如果您愿意支持xmake的开发，欢迎为其捐赠，支持xmake的发展。

#####alipay
<img src="http://www.tboox.net/ruki/alipay.png" alt="alipay" width="128" height="128">

#####paypal
<a href="http://tboox.net/%E6%8D%90%E5%8A%A9/">
<img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif" alt="paypal">
</a>
