# Changelog ([中文](#中文))

## master (unreleased)

### New features

* Add `--links`, `--linkdirs` and `--includedirs` configure arguments
* Add app2ipa plugin
* Add dictionary syntax style for xmake.lua
* Provide smart scanning and building mode without xmake.lua

### Changes

* Support vs2017 for the project plugin
* Improve gcc error and warning tips
* Improve lanuage module
* Improve print interface, support lua print and format output
* Automatically scan project files and generate it for building if xmake.lua not exists
* Modify license to Apache License 2.0
* Remove some binary tools
* Remove install.bat script and provide nsis install package

### Bugs fixed

* [#41](https://github.com/waruqi/xmake/issues/41): Fix checker bug for windows 
* [#43](https://github.com/waruqi/xmake/issues/43): Avoid to generate unnecessary .xmake directory  
* Add c++ stl search directories for android
* Fix compile error for rhel 5.10

## v2.0.5

### New features

* Add some interpreter builtin-modules
* Support ml64 assembler for windows x64

### Changes

* Improve ipairs and pairs interfaces and support filter
* Add filters for generating vs201x project
* Remove `core/tools` (msys toolchains) and uses xmake to compile core sources on windows
* Remove `xmake/packages` for templates

### Bugs fixed

* Fix `-def:xxx.def` flags failed for msvc
* Fix ml.exe assembler script
* Fix options linking order bug

## v2.0.4

### New features

* Add native shell support for `xmake.lua`. .e.g `add_ldflags("$(shell pkg-config --libs sqlite3)")`
* Enable pdb symbol files for windows
* Add debugger support on windows (vsjitdebugger, ollydbg, windbg ... )
* Add `getenv` interface for the global scope of `xmake.lua`
* Add plugin for generating vstudio project file (vs2002 - vs2015)
* Add `set_default` api for option

### Changes

* Improve builtin-variable format
* Support option for string type

### Bugs fixed

* Fix check ld failed without g++ on linux 
* Fix compile `*.cxx` files failed

## v2.0.3

### New features 

* Add check includes dependence automatically
* Add print colors 
* Add debugger support, .e.g `xmake run -d program ...`

### Changes

* Improve the interfaces of run shell
* Upgrade luajit to v2.0.4
* Improve to generate makefile plugin
* Optimizate the multitasking compiling speed

### Bugs fixed

* Fix install directory bug
* Fix the root directory error for `import` interface
* Fix check visual stdio error on windows

## v2.0.2

### Changes

* Change install and uninstall actions
* Update templates
* Improve to check function 

### Bugs fixed

* [#7](https://github.com/waruqi/xmake/issues/7): Fix create project bug with '[targetname]'
* [#9](https://github.com/waruqi/xmake/issues/9): Support clang with c++11
* Fix api scope leaks bug
* Fix path bug for windows
* Fix check function bug
* Fix check toolchains failed
* Fix compile failed for android on windows 

## v2.0.1

### New features

* Add task api for running custom tasks
* Add plugin expansion and provide some builtin plugins
* Add export ide project plugin(.e.g makefile and will support to export other projects for vs, xcode in feature)
* Add demo plugin for printing 'hello xmake'
* Add make doxygen documents plugin
* Add macro script plugin
* Add more modules for developing plugin
* Add exception using try/catch and simplify grammar for plugin script
* Add option bindings
* Show progress when building

### Changes

* Rewrite interpreter for xmake.lua
* More strict syntax detection mechanism
* More strict api scope for xmake.lua 
* Simplify template development
* Extend platforms, tools, templates and actions fastly
* Simplify api and support import modules
* Remove dependence for gnu make/nmake, no longer need makefile
* Optimize speed for building and faster x4 than v1.0.4
* Optimize automatic detection 
* Modify some api name, but be compatible with the old version
* Optimize merging static library
* Simplify cross compilation using argument `--sdk=xxx`
* Simplify boolean option for command line, .e.g `xmake config --xxx=[y|n|yes|no|true|false]`
* Merge iphoneos and iphonesimulator platforms
* Merge watchos and watchsimulator platformss

### Bugs fixed

* [#3](https://github.com/waruqi/xmake/issues/3): ArchLinux compilation failed
* [#4](https://github.com/waruqi/xmake/issues/4): Install failed for windows
* Fix envirnoment variable bug for windows

## v1.0.4

### New features

* Support windows assembler
* Add some project templates
* Support swift codes
* Add -v argument for outputing more verbose info
* Add apple platforms：watchos, watchsimulator
* Add architecture x64, amd64, x86_amd64 for windows
* Support switch static and share library
* Add -j/--jobs argument for supporting multi-jobs 

### Changes

* Improve `add_files` api and support to add *.o/obj/a/lib files for merging static library and object files
* Optimize installation and remove some binary files

### Bugs fixed

* [#1](https://github.com/waruqi/xmake/issues/4): Install failed for win7
* Fix checking toolchains bug
* Fix install script bug
* Fix install bug for linux x86_64

## v1.0.3

### New features

* Add set_runscript api and support custom action
* Add import api and support import modules in xmake.lua, .e.g os, path, utils ...
* Add new architecture: arm64-v8a for android

### Bugs fixed

* Fix api bug for set_installscript
* Fix install bug for windows x86_64
* Fix relative path bug

<h1 id="中文"></h1>

# 更新日志

## master (开发中)

### 新特性

* 添加`--links`, `--linkdirs` and `--includedirs` 配置参数
* 添加app2ipa插件
* 为xmake.lua工程描述增加dictionay语法风格
* 提供智能扫描编译模式，在无任何xmake.lua等工程描述文件的情况下，也能直接快速编译

### 改进

* 工程生成插件支持vs2017
* 改进gcc/clang编译器警告和错误提示
* 重构代码架构，改进多语言支持，更加方便灵活的扩展语言支持
* 改进print接口，同时支持原生lua print以及格式化打印
* 如果xmake.lua不存在，自动扫描工程代码文件，并且生成xmake.lua进行编译
* 修改license，使用更加宽松的Apache License 2.0
* 移除一些二进制工具文件
* 移除install.bat脚本，提供windows nsis安装包支持

### Bugs修复

* [#41](https://github.com/waruqi/xmake/issues/41): 修复在windows下自动检测x64失败问题
* [#43](https://github.com/waruqi/xmake/issues/43): 避免创建不必要的.xmake工程缓存目录
* 针对android版本添加c++ stl搜索目录，解决编译c++失败问题
* 修复在rhel 5.10上编译失败问题

## v2.0.5

### 新特性

* 为解释器作用域增加一些内建模块支持
* 针对windows x64平台，支持ml64汇编器

### 改进

* 增强ipairs和pairs接口，支持过滤器模式，简化脚本代码
* 为vs201x工程生成增加文件filter
* 移除`core/tools`目录以及msys工具链，在windows上使用xmake自编译core源码进行安装，优化xmake源码磁盘空间
* 移除`xmake/packages`，默认模板安装不再内置二进制packages，暂时需要手动放置，以后再做成自动包依赖下载编译

### Bugs修复

* 修复msvc的编译选项不支持问题：`-def:xxx.def`
* 修复ml.exe汇编器脚本
* 修复选项链接顺序问题

## v2.0.4

### 新特性

* 在`xmake.lua`中添加原生shell支持，例如：`add_ldflags("$(shell pkg-config --libs sqlite3)")`
* 编译windows目标程序，默认默认启用pdb符号文件
* 在windows上添加调试器支持（vsjitdebugger, ollydbg, windbg ... ）
* 添加`getenv`接口到`xmake.lua`的全局作用域中
* 添加生成vstudio工程插件(支持：vs2002 - vs2015)
* 为option添加`set_default`接口

### 改进

* 增强内建变量的处理
* 支持字符串类型的选项option设置

### Bugs修复

* 修复在linux下检测ld连接器失败，如果没装g++的话
* 修复`*.cxx`编译失败问题

## v2.0.3

### 新特性

* 增加头文件依赖自动检测和增量编译，提高编译速度
* 在终端中进行颜色高亮提示
* 添加调试器支持，`xmake run -d program ...`

### 改进

* 增强运行shell的系列接口
* 更新luajit到v2.0.4版本
* 改进makefile生成插件，移除对xmake的依赖，并且支持`windows/linux/macosx`等大部分pc平台
* 优化多任务编译速度，在windows下编译提升较为明显

### Bugs修复

* 修复安装目录错误问题
* 修复`import`根目录错误问题
* 修复在多版本vs同时存在的情况下，检测vs环境失败问题

## v2.0.2

### 改进

* 修改安装和卸载的action处理
* 更新工程模板
* 增强函数检测

### Bugs修复

* [#7](https://github.com/waruqi/xmake/issues/7): 修复用模板创建工程后，target名不对问题：'[targetname]'
* [#9](https://github.com/waruqi/xmake/issues/9): 修复clang不支持c++11的问题
* 修复api作用域泄露问题
* 修复在windows上的一些路径问题
* 修复检测宏函数失败问题
* 修复检测工具链失败问题
* 修复windows上编译android版本失败

## v2.0.1

### 新特性

* 增加task任务机制，可运行自定义任务脚本
* 实现plugin扩展机制，可以很方便扩展实现自定义插件，目前已实现的一些内置插件
* 增加project文件导出插件(目前已支持makefile的生成，后续会支持：vs, xcode等工程的生成)
* 增加hello xmake插件（插件demo）
* 增加doxygen文档生成插件
* 增加自定义宏脚本插件（支持动态宏记录、宏回放、匿名宏、批量导入、导出等功能）
* 增加更多的类库用于插件化开发
* 实现异常捕获机制，简化上层调用逻辑
* 增加多个option进行宏绑定，实现配置一个参数，就可以同时对多个配置进行生效
* 增加显示全局构建进度

### 改进

* 重构整个xmake.lua描述文件的解释器，更加的灵活可扩展
* 更加严格的语法检测机制
* 更加严格的作用域管理，实现沙盒引擎，对xmake.lua中脚本进行沙盒化处理，使得xmake.lua更加的安全
* 简化模板的开发，简单几行描述就可以扩展一个新的自定义工程模板
* 完全模块化platforms、tools、templates、actions，以及通过自注册机制，只需把自定义的脚本放入对应目录，就可实现快速扩展
* 针对所有可扩展脚本所需api进行大量简化，并实现大量类库，通过import机制进行导入使用
* 移除对gnu make/nmake等make工具的依赖，不再需要makefile，实现自己的make算法，
* 优化构建速度，支持多任务编译(支持vs编译器)（实测：比v1.0.4提升x4倍的构建性能）
* 优化自动检测机制，更加的稳定和准确
* 修改部分工程描述api，增强扩展性，减少一些命名歧义（对低版本向下兼容）
* 优化静态库合并：`add_files("*.a")`，修复一些bug
* 优化交叉编译，通过`--sdk=xxx`参数实现更加方便智能的进行交叉编译配置，简化mingw平台的编译配置
* 简化命令行配置开关, 支持`xmake config --xxx=[y|n|yes|no|true|false]`等开关值
* 合并iphoneos和iphonesimulator平台，以及watchos和watchsimulator平台，通过arch来区分，使得打包更加方便，能够支持一次性打包iphoneos的所有arch到一个包中

### Bugs修复

* [#3](https://github.com/waruqi/xmake/issues/3): 修复ArchLinux 编译失败问题
* [#4](https://github.com/waruqi/xmake/issues/4): 修复windows上安装失败问题
* 修复windows上环境变量设置问题

## v1.0.4

### 新特性

* 增加对windows汇编器的支持
* 为xmake create增加一些新的工程模板，支持tbox版本
* 支持swift代码
* 针对-v参数，增加错误输出信息
* 增加apple编译平台：watchos, watchsimulator的编译支持
* 增加对windows: x64, amd64, x86_amd64架构的编译支持
* 实现动态库和静态库的快速切换
* 添加-j/--jobs参数，手动指定是否多任务编译，默认改为单任务编译

### 改进

* 增强add_files接口，支持直接添加*.o/obj/a/lib文件，并且支持静态库的合并
* 裁剪xmake的安装过程，移除一些预编译的二进制程序

### Bugs修复

* [#1](https://github.com/waruqi/xmake/issues/4): 修复win7上安装失败问题
* 修复和增强工具链检测
* 修复一些安装脚本的bug, 改成外置sudo进行安装
* 修复linux x86_64下安装失败问题

## v1.0.3

### 新特性

* 添加set_runscript接口，支持自定义运行脚本扩展
* 添加import接口，使得在xmake.lua中可以导入一些扩展模块，例如：os，path，utils等等，使得脚本更灵活
* 添加android平台arm64-v8a支持

### Bugs修复

* 修复set_installscript接口的一些bug
* 修复在windows x86_64下，安装失败的问题
* 修复相对路径的一些bug
