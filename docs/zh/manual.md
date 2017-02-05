---
nav: zh
search: zh
---

## 接口规范

#### 命名规范

接口的命名，是有按照预定义的一些规范来命名的，这样更加方便理解和易于使用，目前命名按照如下一些规则：

| 接口规则              | 描述                                                         |
| --------------------- | ------------------------------------------------------------ |
| `is_`前缀的接口       | 表示为条件判断                                               |
| `set_`前缀的接口      | 表示为覆盖设置                                               |
| `add_`前缀的接口      | 表示为追加设置                                               |
| `s`后缀的接口         | 表示支持多值传入，例如：`add_files("*.c", "test.cpp")`       |
| `on_`前缀的接口       | 表示为覆盖内置脚本                                           |
| `before_`前缀的接口   | 表示为在内置脚本运行前，执行此脚本                           |
| `after_`前缀的接口    | 表示为在内置脚本运行后，执行此脚本                           |
| `scope("name")`的接口 | 表示为定义一个描述域，例如：`target("xxx")`, `option("xxx")` |
| 描述域/描述设置       | 建议缩进表示                                                 |


## 接口文档

#### 条件判断 

条件判断的api，一般用于必须要处理特定平台的编译逻辑的场合。。通常跟lua的if语句配合使用。

| 接口                      | 描述                          |
| ------------------------- | ----------------------------- |
| [is_os](#is_os)           | 判断当前编译架构              |
| [is_arch](#is_arch)       | 判断当前构建的操作系统        |
| [is_plat](#is_plat)       | 判断当前编译平台              |
| [is_mode](#is_mode)       | 判断当前编译模式              |
| [is_kind](#is_kind)       | 判断当前编译类型              |
| [is_option](#is_option)   | 判断选项是否启用              |

##### is_os 

###### 判断当前构建的操作系统

```lua
-- 如果当前操作系统是ios
if is_os("ios") then
    add_files("src/xxx/*.m")
end
```

目前支持的操作系统有：

* windows
* linux
* android
* macosx
* ios

##### is_arch

###### 判断当前编译架构

用于检测编译配置：`xmake f -a armv7`

```lua
-- 如果当前架构是x86_64或者i386
if is_arch("x86_64", "i386") then
    add_files("src/xxx/*.c")
end

-- 如果当前平台是armv7, arm64, armv7s, armv7-a
if is_arch("armv7", "arm64", "armv7s", "armv7-a") then
    -- ...
end
```

如果像上面那样一个个去判断所有arm架构，也许会很繁琐，毕竟每个平台的架构类型很多，xmake提供了类似add_files中的通配符匹配模式，来更加简洁的进行判断：

```lua
--如果当前平台是arm平台
if is_arch("arm*") then
    -- ...
end
```

用*就可以匹配所有了。。

##### is_plat

###### 判断当前编译平台

用于检测编译配置：`xmake f -p iphoneos`

```lua
-- 如果当前平台是android
if is_plat("android") then
    add_files("src/xxx/*.c")
end

-- 如果当前平台是macosx或者iphoneos
if is_plat("macosx", "iphoneos") then
    add_mxflags("-framework Foundation")
    add_ldflags("-framework Foundation")
end
```

目前支持的平台有：

* windows
* linux
* macosx
* android
* iphoneos
* watchos

当然你也可以自己扩展添加自己的平台。。。

##### is_mode

###### 判断当前编译模式

用于检测编译配置：`xmake f -m debug`

编译模式的类型并不是内置的，可以自由指定，一般指定：`debug`, `release`, `profile` 这些就够用了，当然你也可以在xmake.lua使用其他模式名来判断。

```lua
-- 如果当前编译模式是debug
if is_mode("debug") then

    -- 添加DEBUG编译宏
    add_defines("DEBUG")

    -- 启用调试符号
    set_symbols("debug")

    -- 禁用优化
    set_optimize("none")

end

-- 如果是release或者profile模式
if is_mode("release", "profile") then

    -- 如果是release模式
    if is_mode("release") then

        -- 隐藏符号
        set_symbols("hidden")

        -- strip所有符号
        set_strip("all")

        -- 忽略帧指针
        add_cxflags("-fomit-frame-pointer")
        add_mxflags("-fomit-frame-pointer")

    -- 如果是profile模式
    else

        -- 启用调试符号
        set_symbols("debug")

    end

    -- 添加扩展指令集
    add_vectorexts("sse2", "sse3", "ssse3", "mmx")
end
```

##### is_kind

###### 判断当前编译类型

判断当前是否编译的是动态库还是静态库，用于检测编译配置：`xmake f -k [static|shared]`

一般用于如下场景：

```lua
target("test")

    -- 通过配置设置目标的kind
    set_kind("$(kind)")
    add_files("src/*c")

    -- 如果当前编译的是静态库，那么添加指定文件
    if is_kind("static") then
        add_files("src/xxx.c")
    end
```

编译配置的时候，可手动切换，编译类型：

```bash
# 编译静态库
$ xmake f -k static
$ xmake
```

```bash
# 编译动态库
$ xmake f -k shared
$ xmake
```

##### is_option

###### 判断选项是否启用

用于检测自定义的编译配置选型：`xmake f --xxxx=y`

如果某个自动检测选项、手动设置选项被启用，那么可以通过`is_option`接口来判断，例如：

```lua
-- 如果手动启用了xmake f --demo=y 选项
if is_option("demo") then

    -- 编译demo目录下的代码
    add_subdirs("src/demo")
end
```

#### 全局接口

全局接口影响整个工程描述，被调用后，后面被包含进来的所有子`xmake.lua`都会受影响。

| 接口                                  | 描述                          |
| ------------------------------------- | ----------------------------- |
| [set_project](#set_project)           | 设置工程名                    |
| [set_version](#set_version)           | 设置工程版本                  |
| [add_subdirs](#add_subdirs)           | 添加子工程目录                |
| [add_subfiles](#add_subfiles)         | 添加子工程文件                |
| [add_plugindirs](#add_plugindirs)     | 添加插件目录                  |
| [add_packagedirs](#add_packagedirs)   | 添加包目录                    |

##### set_project

###### 设置工程名

设置工程名，在doxygen自动文档生成插件、工程文件生成插件中会用到，一般设置在xmake.lua的最开头，当然放在其他地方也是可以的

```lua
-- 设置工程名
set_project("tbox")

-- 设置工程版本
set_version("1.5.1")
```

##### set_version

###### 设置工程版本

设置项目版本，可以放在xmake.lua任何地方，一般放在最开头，例如：

```lua
set_version("1.5.1")
```

以tbox为例，如果调用`set_config_h`设置了`config.h`，那么会自动生成如下宏：

```c
// version
#define TB_CONFIG_VERSION "1.5.1"
#define TB_CONFIG_VERSION_MAJOR 1
#define TB_CONFIG_VERSION_MINOR 5
#define TB_CONFIG_VERSION_ALTER 1
#define TB_CONFIG_VERSION_BUILD 201510220917
```

##### add_subdirs

###### 添加子工程目录

每个子工程对应一个`xmake.lua`的工程描述文件。

虽然一个`xmake.lua`也可以描述多个子工程模块，但是如果工程越来越大，越来越复杂，适当的模块化是很有必要的。。

这就需要`add_subdirs`了，将每个子模块放到不同目录中，并为其建立一个新的`xmake.lua`独立去维护它，例如：

```
./tbox
├── src
│   ├── demo
│   │   └── xmake.lua (用来描述测试模块)
│   └── tbox
│       └── xmake.lua（用来描述libtbox库模块）
└── xmake.lua（用该描述通用配置信息，以及对子模块的维护）
````

在`tbox/xmake.lua`中通过`add_subdirs`将拥有`xmale.lua`的子模块的目录，添加进来，就可以了，例如：

```lua
-- 添加libtbox库模块目录
add_subdirs("src/tbox") 

-- 如果xmake f --demo=y，启用了demo模块，那么包含demo目录
if is_option("demo") then 
    add_subdirs("src/demo") 
end
```

默认情况下，xmake会去编译在所有xmake.lua中描述的所有target目标，如果只想编译指定目标，可以执行：

```bash
# 仅仅编译tbox库模块
$ xmake tbox

# 仅仅重新编译demo模块
$ xmake -r demo
```

需要注意的是，每个子`xmake.lua`中所有的路径设置都是相对于当前这个子`xmake.lua`所在的目录的，都是相对路径，这样方便维护

##### add_subfiles

###### 添加子工程文件

`add_subfiles`的作用与[add_subdirs](#add_subdirs)类似，唯一的区别就是：这个接口直接指定`xmake.lua`文件所在的路径，而不是目录，例如：

```lua
add_subfiles("src/tbox/xmake.lua")
```

##### add_plugindirs

###### 添加插件目录

xmake内置的插件都是放在`xmake/plugins`目录下，但是对于用户自定义的一些特定工程的插件，如果不想放置在xmake安装目录下，那么可以在`xmake.lua`中进行配置指定的其他插件路径。

```lua
-- 将当前工程下的plugins目录设置为自定义插件目录
add_plugindirs("$(projectdir)/plugins")
```

这样，xmake在编译此工程的时候，也就加载这些插件。

##### add_packagedirs

###### 添加包目录

通过设置依赖包目录，可以方便的集成一些第三方的依赖库，以tbox工程为例，其包目录如下：

```
tbox/pkg
- base.pkg
- zlib.pkg
- polarssl.pkg
- openssl.pkg
- mysql.pkg
- pcre.pkg
- ...
```

如果要让当前工程识别加载这些包，首先要指定包目录路径，例如：

```lua
add_packagedirs("pkg")
```

指定好后，就可以在target作用域中，通过[add_packages](#add_packages)接口，来添加集成包依赖了，例如：

```lua
target("tbox")
    add_packages("zlib", "polarssl", "pcre", "mysql")
```

#### 工程目标

定义和设置子工程模块，每个`target`对应一个子工程，最后会生成一个目标程序，有可能是可执行程序，也有可能是库模块。


| 接口                                  | 描述                                 |
| ------------------------------------- | ------------------------------------ |
| [target](#target)                     | 定义工程目标                         |
| [set_kind](#set_kind)                 | 设置目标编译类型                     |
| [set_strip](#set_strip)               | 设置是否strip信息                    |
| [set_options](#set_options)           | 设置关联选项                         |
| [set_symbols](#set_symbols)           | 设置符号信息                         |
| [set_warnings](#set_warnings)         | 设置警告级别                         |
| [set_optimize](#set_optimize)         | 设置优化级别                         |
| [set_languages](#set_languages)       | 设置代码语言标准                     |
| [set_headerdir](#set_headerdir)       | 设置头文件安装目录                   |
| [set_targetdir](#set_targetdir)       | 设置生成目标文件目录                 |
| [set_objectdir](#set_objectdir)       | 设置对象文件生成目录                 |
| [on_build](#on_build)                 | 自定义编译脚本                       |
| [on_clean](#on_clean)                 | 自定义清理脚本                       |
| [on_package](#on_package)             | 自定义打包脚本                       |
| [on_install](#on_install)             | 自定义安装脚本                       |
| [on_uninstall](#on_uninstall)         | 自定义卸载脚本                       |
| [on_run](#on_run)                     | 自定义运行脚本                       |
| [before_build](#before_build)         | 在构建之前执行一些自定义脚本         |
| [before_clean](#before_clean)         | 在清除之前执行一些自定义脚本         |
| [before_package](#before_package)     | 在打包之前执行一些自定义脚本         |
| [before_install](#before_install)     | 在安装之前执行一些自定义脚本         |
| [before_uninstall](#before_uninstall) | 在卸载之前执行一些自定义脚本         |
| [before_run](#before_run)             | 在运行之前执行一些自定义脚本         |
| [after_build](#after_build)           | 在构建之后执行一些自定义脚本         |
| [after_clean](#after_clean)           | 在清除之后执行一些自定义脚本         |
| [after_package](#after_package)       | 在打包之后执行一些自定义脚本         |
| [after_install](#after_install)       | 在安装之后执行一些自定义脚本         |
| [after_uninstall](#after_uninstall)   | 在卸载之后执行一些自定义脚本         |
| [after_run](#after_run)               | 在运行之后执行一些自定义脚本         |
| [set_config_h](#set_config_h)         | 设置自动生成的配置头文件路径         |
| [set_config_h_prefix](#set_config_h)  | 设置自动生成的头文件中宏定义命名前缀 |
| [add_deps](#add_deps)                 | 添加子工程目标依赖                   |
| [add_links](#add_links)               | 添加链接库名                         |
| [add_files](#add_files)               | 添加源代码文件                       |
| [add_headers](#add_headers)           | 添加安装的头文件                     |
| [add_linkdirs](#add_linkdirs)         | 添加链接库搜索目录                   |
| [add_includedirs](#add_includedirs)   | 添加头文件搜索目录                   |
| [add_defines](#add_defines)           | 添加宏定义                           |
| [add_undefines](#add_undefines)       | 取消宏定义                           |
| [add_defines_h](#add_defines_h)       | 添加宏定义到头文件                   |
| [add_undefines_h](#add_undefines_h)   | 取消宏定义到头文件                   |
| [add_cflags](#add_cflags)             | 添加c编译选项                        |
| [add_cxflags](#add_cxflags)           | 添加c/c++编译选项                    |
| [add_cxxflags](#add_cxxflags)         | 添加c++编译选项                      |
| [add_mflags](#add_mflags)             | 添加objc编译选项                     |
| [add_mxflags](#add_mxflags)           | 添加objc/objc++编译选项              |
| [add_mxxflags](#add_mxxflags)         | 添加objc++编译选项                   |
| [add_ldflags](#add_ldflags)           | 添加链接选项                         |
| [add_arflags](#add_arflags)           | 添加静态库归档选项                   |
| [add_shflags](#add_shflags)           | 添加动态库链接选项                   |
| [add_cfuncs](#add_cfuncs)             | 添加c库函数检测                      |
| [add_cxxfuncs](#add_cxxfuncs)         | 添加c++库函数接口                    |
| [add_packages](#add_packages)         | 添加包依赖                           |
| [add_options](#add_options)           | 添加关联选项                         |
| [add_languages](#add_languages)       | 添加语言标准                         |
| [add_vectorexts](#add_vectorexts)     | 添加向量扩展指令                     |

##### target

###### 定义工程目标

定义一个新的控制台工程目标，工程名为`test`，最后生成的目标名也是`test`。

```lua
target("test")
    set_kind("binary")
    add_files("src/*.c")
```

可以重复调用这个api，进入target域修改设置

```lua
-- 定义目标demo，并进入demo设置模式
target("demo")
    set_kind("binary")
    add_files("src/demo.c")

-- 定义和设置其他目标
target("other")
    ...

-- 重新进入demo目标域，添加test.c文件
target("demo")
    add_files("src/test.c")
```

<p class="tip">
所有根域的设置，会全局影响所有target目标，但是不会影响option的定义。
</p>

```lua
-- 在根域对所有target添加-DDEBUG的宏定义，影响所有target（demo和test都会加上此宏定义）
add_defines("DEBUG")

target("demo")
    set_kind("binary")
    add_files("src/demo.c")

target("test")
    set_kind("binary")
    add_files("src/test.c")
```

##### set_kind

###### 设置目标编译类型

设置目标类型，目前支持的类型有：

| 值     | 描述       |
| ------ | -----------|
| binary | 二进制程序 |
| static | 静态库程序 |
| shared | 动态库程序 |

```lua
target("demo")
    set_kind("binary")
```

##### set_strip

###### 设置是否strip信息

设置当前目标的strip模式，目前支持一下模式：

| 值     | 描述                                      |
| ------ | ----------------------------------------- |
| debug  | 链接的时候，strip掉调试符号               |
| all    | 链接的时候，strip掉所有符号，包括调试符号 |

这个api一般在release模式下使用，可以生成更小的二进制程序。。

```lua
target("xxxx")
    set_strip("all")
```

<p class="tip">
这个api不一定非得在target之后使用，如果没有target指定，那么将会设置到全局模式。。
</p>

##### set_options

###### 设置关联选项

添加选项依赖，如果通过[option](#option)接口自定义了一些选项，那么只有在指定`target`目标域下，添加此选项，才能进行关联生效。

```lua
-- 定义一个hello选项
option("hello")
    set_default(false)
    set_showmenu(true)
    add_defines_if_ok("HELLO_ENABLE")

target("test")
    -- 如果hello选项被启用了，这个时候就会将-DHELLO_ENABLE宏应用到test目标上去
    set_options("hello")
```

<p class="warning">
只有调用`set_options`进行关联生效后，[option](#option) 中定义的一些设置才会影响到此`target`目标，例如：宏定义、链接库、编译选项等等
</p>

##### set_symbols

###### 设置符号信息

设置目标的符号模式，如果当前没有定义target，那么将会设置到全局状态中，影响所有后续的目标。

目前主要支持一下几个级别：

| 值     | 描述                   |
| ------ | ---------------------- |
| debug  | 添加调试符号           |
| hidden | 设置符号不可见         |

这两个值也可以同时被设置，例如：

```lua
-- 添加调试符号, 设置符号不可见
set_symbols("debug", "hidden")
```

如果没有调用这个api，默认是禁用调试符号的。。

##### set_warnings

###### 设置警告级别

设置当前目标的编译的警告级别，一般支持一下几个级别：

| 值    | 描述                   |
| ----- | ---------------------- |
| none  | 禁用所有警告           |
| less  | 启用较少的警告         |
| more  | 启用较多的警告         |
| all   | 启用所有警告           |
| error | 将所有警告作为编译错误 |

这个api的参数是可以混合添加的，例如：

```lua
-- 启用所有警告，并且作为编译错误处理
set_warnings("all", "error")
```

如果当前没有目标，调用这个api将会设置到全局模式。。

##### set_optimize

###### 设置优化级别

设置目标的编译优化等级，如果当前没有设置目标，那么将会设置到全局状态中，影响所有后续的目标。

目前主要支持一下几个级别：

| 值         | 描述                   |
| ---------- | ---------------------- |
| none       | 禁用优化               |
| fast       | 快速优化               |
| faster     | 更快的优化             |
| fastest    | 最快运行速度的优化     |
| smallest   | 最小化代码优化         |
| aggressive | 过度优化               |

例如：

```lua
-- 最快运行速度的优化
set_optimize("fastest")
```

##### set_languages

###### 设置代码语言标准

设置目标代码编译的语言标准，如果当前没有目标存在，将会设置到全局模式中。。。

支持的语言标准目前主要有以下几个：

| 值         | 描述                   |
| ---------- | ---------------------- |
| ansi       | c语言标准              |
| c89        | c语言标准              |
| gnu89      | c语言标准              |
| c99        | c语言标准              |
| gnu99      | c语言标准              |
| cxx98      | c++语言标准: `c++98`   |
| gnuxx98    | c++语言标准: `gnu++98` |
| cxx11      | c++语言标准: `c++11`   |
| gnuxx11    | c++语言标准: `gnu++11` |
| cxx14      | c++语言标准: `c++14`   |
| gnuxx14    | c++语言标准: `gnu++14` |

c标准和c++标准可同时进行设置，例如：

```lua
-- 设置c代码标准：c99， c++代码标准：c++11
set_languages("c99", "cxx11")
```

<p class="warning">
并不是设置了指定的标准，编译器就一定会按这个标准来编译，毕竟每个编译器支持的力度不一样，但是xmake会尽最大可能的去适配当前编译工具的支持标准。。。
<br><br>
例如：
<br>
windows下vs的编译器并不支持按c99的标准来编译c代码，只能支持到c89，但是xmake为了尽可能的支持它，所以在设置c99的标准后，xmake会强制按c++代码模式去编译c代码，从一定程度上解决了windows下编译c99的c代码问题。。
用户不需要去额外做任何修改。。
</p>

##### set_headerdir
##### set_targetdir
##### set_objectdir
##### on_build
##### on_clean
##### on_package
##### on_install
##### on_uninstall
##### on_run
##### before_build
##### before_clean
##### before_package
##### before_install
##### before_uninstall
##### before_run
##### after_build
##### after_clean
##### after_package
##### after_install
##### after_uninstall
##### after_run
##### set_config_h
##### set_config_h_prefix
##### add_deps
##### add_links
##### add_files
##### add_headers
##### add_linkdirs
##### add_includedirs
##### add_defines
##### add_undefines
##### add_defines_h
##### add_undefines_h
##### add_cflags
##### add_cxflags
##### add_cxxflags
##### add_mflags
##### add_mxflags
##### add_mxxflags
##### add_ldflags
##### add_arflags
##### add_shflags
##### add_cfuncs
##### add_cxxfuncs
##### add_options

###### 添加关联选项

这个接口跟[set_options](#set_options)类似，唯一的区别就是，此处是追加选项，而[set_options](#set_options)每次设置会覆盖先前的设置。

##### add_packages
##### add_languages
##### add_vectorexts

#### 选项定义

##### option
##### set_enable
##### set_showmenu
##### set_category
##### set_warnings
##### set_optimize
##### set_languages
##### set_description
##### add_bindings
##### add_rbindings
##### add_links
##### add_linkdirs
##### add_includedirs
##### add_cincludes
##### add_cxxincludes
##### add_cfuncs
##### add_cxxfuncs
##### add_ctypes
##### add_cxxtypes
##### add_cflags
##### add_cxflags
##### add_cxxflags
##### add_ldflags
##### add_vectorexts
##### add_defines
##### add_defines_if_ok
##### add_defines_h_if_ok
##### add_undefines
##### add_undefines_if_ok
##### add_undefines_h_if_ok

#### 插件任务

##### task
##### set_menu
##### set_category
##### on_run

#### 平台扩展

##### platform
##### set_os
##### set_menu
##### set_hosts
##### set_archs
##### set_checker
##### set_tooldirs
##### on_load

#### 工程模板

##### template
##### set_description
##### set_projectdir
##### add_macros
##### add_macrofiles

