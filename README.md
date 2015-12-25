The Automatic Cross-platform Build Tool
========================

Xmake is an automatic cross-platform build tool.


features
--------

1. create c/c++ projects 
2. automatically probe the host environment and configure project 
3. build and rebuild project 
4. clean generated target files
5. package the project targets automatically
   - *.ipa for ios
   - *.apk for android
   - *.pkg for library
   - *.app for macosx
   - *.exe for windows
   - others
   

6. install target to pc or the mobile device
7. run a given target
8. describe the project file using lua script, more flexible and simple
	```lua
	
	-- xmake.lua
    add_target("console")

        -- set kind
        set_kind("binary")

        -- add files
        add_files("src/*.c") 
    ```
9. custom platforms and toolchains
10. custom rules for package/compiler/linker

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

也可以参考一些使用xmake的项目：

* [tbox](https://github.com/waruqi/tbox)
* [gbox](https://github.com/waruqi/gbox)
* [more](https://github.com/waruqi/xmake/wiki/%E4%BD%BF%E7%94%A8xmake%E7%9A%84%E5%BC%80%E6%BA%90%E5%BA%93)

####后续工作

1. 完善打包模块，支持对ios、mac、android的app进行一键打包和签名，生成.ipa、.apk、.app的应用程序文件
2. 完善安装功能，支持对ios、android的app进行安装到设备
3. 实现调试功能
4. 实现自动生成doxygen文档功能
5. 增加一些实用的工程描述api，例如：下载api，可以自动下载缺少的依赖库等等。。
6. 解析automake、cmake的工程，并自动生成xmake的描述文件，实现无缝编译（如果这个实现成功的话，以后移植编译一些开源代码就更方便了）


contact
-------

- email:   	    
	- waruqi@gmail.com
	- waruqi@126.com
- source:  	    
	- [github](https://github.com/waruqi/xmake)
	- [coding](https://coding.net/u/waruqi/p/xmake/git)
	- [oschina](http://git.oschina.net/tboox/xmake)
- website: 	    
	- http://www.tboox.org
	- http://www.tboox.net
- download:
 	- [github](https://github.com/waruqi/xmake/archive/master.zip)
 	- [coding](https://coding.net/u/waruqi/p/xmake/git/archive/master)
 	- [oschina](http://git.oschina.net/tboox/xmake/repository/archive?ref=master)
- document:
	- [github](https://github.com/waruqi/xmake/wiki/)
	- [oschina](http://git.oschina.net/tboox/xmake/wikis/home)
- qq(group):    
	- 343118190

donate
------

####alipay
<img src="http://www.tboox.net/ruki/alipay.png" alt="alipay" width="128" height="128">

####paypal
<a href="http://tboox.net/%E6%8D%90%E5%8A%A9/">
<img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif" alt="paypal">
</a>

install
-------

####windows
1. download xmake source codes
2. enter the xmake directory
3. run install.bat 
4. select the install directory 

####linux/macosx
1. git clone git@github.com:waruqi/xmake.git
2. cd ./xmake
3. ./install

usage
-----

Please see [wiki](https://github.com/waruqi/xmake/wiki) if you want to known more usage or run xmake --help command.


```bash
	// create a c++ console project 
	xmake create -l c++ -t 1 console
 or xmake create --language=c++ --template=1 console
	
	// enter the project directory
    cd ./console
	
	// build for the host platform
    xmake
    
	// only build for the given target
	xmake target
    
	// config and build for the host platform for debug
    xmake f -m debug 
 or xmake config --mode=debug
    xmake

	// config and build for the iphoneos platform
	xmake f -p iphoneos 
 or xmake config --plat=iphoneos 
    xmake
    
	// config and build for the iphoneos platform with arm64 
    xmake f -p iphoneos -a arm64
 or xmake config --plat=iphoneos --arch=arm64
    xmake
    
	// config and build for the android platform
    xmake f -p android --ndk=xxxxx
    xmake
    
	// build and package project
	xmake package 
	xmake package -a "i386, x86_64"
	xmake package --arch="armv7, arm64"
	xmake package --output=/tmp
	
    // rebuild project
    xmake -r
 or xmake --rebuild
 
    // clean all project targets
    xmake c
 or xmake clean
    
    // clean the given project target
    xmake c target
 or xmake clean target
    
    // run the given project target
    xmake r target
 or xmake run target
    
    // install all targets
    xmake i
 or xmake install
    

```

example
-------

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
