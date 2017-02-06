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
| [add_scflags](#add_scflags)           | 添加swift编译选项                    |
| [add_asflags](#add_asflags)           | 添加汇编编译选项                     |
| [add_goflags](#add_goflags)           | 添加go编译选项                       |
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
| ansi       | c语言标准: ansi        |
| c89        | c语言标准: c89         |
| gnu89      | c语言标准: gnu89       |
| c99        | c语言标准: c99         |
| gnu99      | c语言标准: gnu99       |
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

###### 设置头文件安装目录

设置头文件的输出目录，默认输出到build目录中。

```lua
target("test")
    set_headerdir("$(buildir)/include")
```

对于需要安装哪些头文件，可参考[add_headers](#add_headers)接口。

##### set_targetdir

###### 设置生成目标文件目录

设置目标程序文件的输出目录，一般情况下，不需要设置，默认会输出在build目录下

而build的目录可以在工程配置的时候，手动修改：

```bash
xmake f -o /tmp/build
```

修改成`/tmp/build`后，目标文件默认输出到`/tmp/build`下面。

而如果用这个接口去设置，就不需要每次敲命令修改了，例如：

```lua
target("test")
    set_targetdir("/tmp/build")
```

<p class="tip">
如果显示设置了`set_targetdir`， 那么优先选择`set_targetdir`指定的目录为目标文件的输出目录。
</p>

##### set_objectdir

###### 设置对象文件生成目录

设置目标target的对象文件(`*.o/obj`)的输出目录，例如:

```lua
target("test")
    set_objectdir("$(buildir)/.objs")
```

##### on_build

###### 自定义编译脚本

覆盖target目标默认的构建行为，实现自定义的编译过程，一般情况下，并不需要这么做，除非确实需要做一些xmake默认没有提供的编译操作。

你可以通过下面的方式覆盖它，来自定义编译操作：

```lua
target("test")

    -- 设置自定义编译脚本
    on_build(function (target) 
        print("build it")
    end)
```

<p class="warning">
一旦对这个target目标设置了自己的build过程，那么xmake默认的构建过程将不再被执行。
</p>

##### on_clean

###### 自定义清理脚本

覆盖target目标的`xmake [c|clean}`的清理操作，实现自定义清理过程。

```lua
target("test")

    -- 设置自定义清理脚本
    on_clean(function (target) 

        -- 仅删掉目标文件
        os.rm(target:targetfile())
    end)
```

一些target接口描述如下：

| target接口            | 描述                                                             |
| --------------------- | ---------------------------------------------------------------- |
| target:name()         | 获取目标名                                                       |
| target:targetfile()   | 获取目标文件路径                                                 |
| target:get("kind")    | 获取目标的构建类型                                               |
| target:get("defines") | 获取目标的宏定义                                                 |
| target:get("xxx")     | 其他通过 `set_/add_`接口设置的target信息，都可以通过此接口来获取 |

##### on_package

###### 自定义打包脚本

覆盖target目标的`xmake [p|package}`的打包操作，实现自定义打包过程，如果你想对指定target打包成自己想要的格式，可以通过这个接口自定义它。

这个接口还是挺实用的，例如，编译玩jni后，将生成的so，打包进apk包中。

```lua
-- 定义一个android app的测试demo
target("demo")

    -- 生成动态库：libdemo.so
    set_kind("shared")

    -- 设置对象的输出目录，可选
    set_objectdir("$(buildir)/.objs")

    -- 每次编译完的libdemo.so的生成目录，设置为app/libs/armeabi
    set_targetdir("libs/armeabi")

    -- 添加jni的代码文件
    add_files("jni/*.c")

    -- 设置自定义打包脚本，在使用xmake编译完libdemo.so后，执行xmake p进行打包
    -- 会自动使用ant将app编译成apk文件
    --
    on_package(function (target) 

        -- 使用ant编译app成apk文件，输出信息重定向到日志文件
        os.run("ant debug") 
    end)
```

##### on_install

###### 自定义安装脚本

覆盖target目标的`xmake [i|install}`的安装操作，实现自定义安装过程。

例如，将生成的apk包，进行安装。

```lua
target("test")

    -- 设置自定义安装脚本，自动安装apk文件
    on_install(function (target) 

        -- 使用adb安装打包生成的apk文件
        os.run("adb install -r ./bin/Demo-debug.apk")
    end)
```

##### on_uninstall

###### 自定义卸载脚本

覆盖target目标的`xmake [u|uninstall}`的卸载操作，实现自定义卸载过程。

```lua
target("test")
    on_uninstall(function (target) 
        ...
    end)
```

##### on_run

###### 自定义运行脚本

覆盖target目标的`xmake [r|run}`的运行操作，实现自定义运行过程。

例如，运行安装好的apk程序：

```lua
target("test")

    -- 设置自定义运行脚本，自动运行安装好的app程序，并且自动获取设备输出信息
    on_run(function (target) 

        os.run("adb shell am start -n com.demo/com.demo.DemoTest")
        os.run("adb logcat")
    end)
```

##### before_build

###### 在构建之前执行一些自定义脚本

并不会覆盖默认的构建操作，只是在构建之前增加一些自定义的操作。

```lua
target("test")
    before_build(function (target))
        print("")
    end
```

##### before_clean

###### 在清理之前执行一些自定义脚本

并不会覆盖默认的清理操作，只是在清理之前增加一些自定义的操作。

```lua
target("test")
    before_clean(function (target))
        print("")
    end
```

##### before_package

###### 在打包之前执行一些自定义脚本

并不会覆盖默认的打包操作，只是在打包之前增加一些自定义的操作。

```lua
target("test")
    before_package(function (target))
        print("")
    end
```

##### before_install

###### 在安装之前执行一些自定义脚本

并不会覆盖默认的安装操作，只是在安装之前增加一些自定义的操作。

```lua
target("test")
    before_install(function (target))
        print("")
    end
```

##### before_uninstall

###### 在卸载之前执行一些自定义脚本

并不会覆盖默认的卸载操作，只是在卸载之前增加一些自定义的操作。

```lua
target("test")
    before_uninstall(function (target))
        print("")
    end
```

##### before_run

###### 在运行之前执行一些自定义脚本

并不会覆盖默认的运行操作，只是在运行之前增加一些自定义的操作。

```lua
target("test")
    before_run(function (target))
        print("")
    end
```

##### after_build

###### 在构建之后执行一些自定义脚本

并不会覆盖默认的构建操作，只是在构建之后增加一些自定义的操作。

例如，对于ios的越狱开发，构建完程序后，需要用`ldid`进行签名操作

```lua
target("test")
    after_build(function (target))
        os.run("ldid -S %s", target:targetfile())
    end
```

##### after_clean

###### 在清理之后执行一些自定义脚本

并不会覆盖默认的清理操作，只是在清理之后增加一些自定义的操作。

一般可用于清理编译某target自动生成的一些额外的临时文件，这些文件xmake默认的清理规则可能没有清理到，例如：

```lua
target("test")
    after_clean(function (target))
        os.rm("$(buildir)/otherfiles")
    end
```

##### after_package

###### 在打包之后执行一些自定义脚本

并不会覆盖默认的打包操作，只是在打包之后增加一些自定义的操作。

```lua
target("test")
    after_package(function (target))
        print("")
    end
```

##### after_install

###### 在安装之后执行一些自定义脚本

并不会覆盖默认的安装操作，只是在安装之后增加一些自定义的操作。

```lua
target("test")
    after_install(function (target))
        print("")
    end
```
##### after_uninstall

###### 在卸载之后执行一些自定义脚本

并不会覆盖默认的卸载操作，只是在卸载之后增加一些自定义的操作。

```lua
target("test")
    after_uninstall(function (target))
        print("")
    end
```

##### after_run

###### 在运行之后执行一些自定义脚本

并不会覆盖默认的运行操作，只是在运行之后增加一些自定义的操作。

```lua
target("test")
    after_run(function (target))
        print("")
    end
```

##### set_config_h

###### 设置自动生成的配置头文件路径

如果你想在xmake配置项目成功后，或者自动检测某个选项通过后，把检测的结果写入配置头文件，那么需要调用这个接口来启用自动生成`config.h`文件。

使用方式例如：

```lua
target("test")

    -- 启用并设置需要自动生成的config.h文件路径
    set_config_h("$(buildir)/config.h")

    -- 设置自动检测生成的宏开关的名字前缀
    set_config_h_prefix("TB_CONFIG")
```

当这个target中通过下面的这些接口，对这个target添加了相关的选项依赖、包依赖、接口依赖后，如果某依赖被启用，那么对应的一些宏定义配置，会自动写入被设置的`config.h`文件中去。

* [add_options](#add_options)
* [add_packages](#add_packages)
* [add_cfuncs](#add_cfuncs)
* [add_cxxfuncs](#add_cxxfuncs) 

这些接口，其实底层都用到了[option](#option)选项中的一些检测设置，例如：

```lua
option("wchar")

    -- 添加对wchar_t类型的检测
    add_ctypes("wchar_t")

    -- 如果检测通过，自动生成 TB_CONFIG_TYPE_HAVE_WCHAR的宏开关到config.h
    add_defines_h_if_ok("$(prefix)_TYPE_HAVE_WCHAR")

target("test")

    -- 启用头文件自动生成
    set_config_h("$(buildir)/config.h")
    set_config_h_prefix("TB_CONFIG")

    -- 添加对wchar选项的依赖关联，只有加上这个关联，wchar选项的检测结果才会写入指定的config.h中去
    add_options("wchar")
```

##### set_config_h_prefix

###### 设置自动生成的头文件中宏定义命名前缀

具体使用见：[set_config_h](#set_config_h)

如果设置了：

```lua
target("test")
    set_config_h_prefix("TB_CONFIG")
```

那么，选项中`add_defines_h_if_ok("$(prefix)_TYPE_HAVE_WCHAR")`的$(prefix)会自动被替换成新的前缀值。

##### add_deps

###### 添加子工程目标依赖

添加当前目标的依赖目标，编译的时候，会去优先编译依赖的目标，然后再编译当前目标。。。

```lua
target("test1")
    set_kind("static")
    set_files("*.c")

target("test2")
    set_kind("static")
    set_files("*.c")

target("demo")

    -- 添加依赖目标：test1, test2
    add_deps("test1", "test2")

    -- 链接libtest1.a，libtest2.a
    add_links("test1", "test2")
```

上面的例子，在编译目标demo的时候，需要先编译test1, test2目标，因为demo会去用到他们

##### add_links

###### 添加链接库名

为当前目标添加链接库，一般这个要与[add_linkdirs](#add_linkdirs)配对使用。

```lua
target("demo")

    -- 添加对libtest.a的链接，相当于 -ltest 
    add_links("test")

    -- 添加链接搜索目录
    add_linkdirs("$(buildir)/lib")
```

##### add_files

###### 添加源代码文件

用于添加目标工程的源文件，甚至库文件，目前支持的一些文件类型：

| 支持的源文件类型   | 描述                               |
| ------------------ | ---------------------------------- |
| .c/.cpp/.cc/.cxx   | c++文件                            |
| .s/.S/.asm         | 汇编文件                           |
| .m/.mm             | objc文件                           |
| .swift             | swift文件                          |
| .go                | golang文件                         |
| .o/.obj            | 对象文件                           |
| .a/.lib            | 静态库文件，会自动合并库到目标程序 |

其中通配符`*`表示匹配当前目录下文件，而`**`则匹配多级目录下的文件。

例如：

```lua
add_files("src/test_*.c")
add_files("src/xxx/**.cpp")
add_files("src/asm/*.S", "src/objc/**/hello.m")
```

`add_files`的使用其实是相当灵活方便的，其匹配模式借鉴了premake的风格，但是又对其进行了改善和增强。

使得不仅可以匹配文件，还有可以在添加文件同时，过滤排除指定模式的一批文件。

例如：

```lua
-- 递归添加src下的所有c文件，但是不包括src/impl/下的所有c文件
add_files("src/**.c|impl/*.c")

-- 添加src下的所有cpp文件，但是不包括src/test.cpp、src/hello.cpp以及src下所有带xx_前缀的cpp文件
add_files("src/*.cpp|test.cpp|hello.cpp|xx_*.cpp")
```

其中分隔符`|`之后的都是需要排除的文件，这些文件也同样支持匹配模式，并且可以同时添加多个过滤模式，只要中间用`|`分割就行了。。

添加文件的时候支持过滤一些文件的一个好处就是，可以为后续根据不同开关逻辑添加文件提供基础。

<p class="tip">
为了使得描述上更加的精简，`|`之后的过滤描述都是基于起一个模式：`src/*.cpp` 中`*`之前的目录为基础的。
所以上面的例子后面过滤的都是在src下的文件，这个是要注意的。
</p>

##### add_headers

###### 添加安装的头文件

安装指定的头文件到build目录，如果设置了[set_headerdir](#set_headerdir)， 则输出到指定目录。

安装规则的语法跟[add_files](#add_files)类似，例如：

```lua
    -- 安装tbox目录下所有的头文件（忽略impl目录下的文件），并且按()指定部分作为相对路径，进行安装
    add_headers("../(tbox/**.h)|**/impl/**.h")
```

##### add_linkdirs

###### 添加链接库搜索目录

设置链接库的搜索目录，这个接口的使用方式如下：

```lua
target("test")
    add_linkdirs("$(buildir)/lib")
```

一般他是与[add_links](#add_links)配合使用的，当然也可以直接通过[add_ldflags](#add_ldflags)或者[add_shflags](#add_shflags)接口来添加，也是可以的。

<p class="tip">
如果不想在工程中写死，可以通过：`xmake f --linkdirs=xxx`或者`xmake f --ldflags="-L/xxx"`的方式来设置，当然这种手动设置的目录搜索优先级更高。
</p>

##### add_includedirs

###### 添加头文件搜索目录

设置头文件的搜索目录，这个接口的使用方式如下：

```lua
target("test")
    add_includedirs("$(buildir)/include")
```

当然也可以直接通过[add_cxflags](#add_cxflags)或者[add_mxflags](#add_mxflags)等接口来设置，也是可以的。

<p class="tip">
如果不想在工程中写死，可以通过：`xmake f --includedirs=xxx`或者`xmake f --cxflags="-I/xxx"`的方式来设置，当然这种手动设置的目录搜索优先级更高。
</p>

##### add_defines

###### 添加宏定义

```lua
add_defines("DEBUG", "TEST=0", "TEST2=\"hello\"")
```

相当于设置了编译选项：

```
-DDEBUG -DTEST=0 -DTEST2=\"hello\"
```

##### add_undefines

###### 取消宏定义

```lua
add_undefines("DEBUG")
```

相当于设置了编译选项：`-UDEBUG`

在代码中相当于：`#undef DEBUG`

##### add_defines_h

###### 添加宏定义到头文件

添加宏定义到`config.h`配置文件，`config.h`的设置，可参考[set_config_h](#set_config_h)接口。

##### add_undefines_h

###### 取消宏定义到头文件

在`config.h`配置文件中通过`undef`禁用宏定义，`config.h`的设置，可参考[set_config_h](#set_config_h)接口。

##### add_cflags

###### 添加c编译选项 

仅对c代码添加编译选项

```lua
add_cflags("-g", "-O2", "-DDEBUG")
```

<p class="warning">
所有选项值都基于gcc的定义为标准，如果其他编译器不兼容（例如：vc），xmake会自动内部将其转换成对应编译器支持的选项值。
用户无需操心其兼容性，如果其他编译器没有对应的匹配值，那么xmake会自动忽略器设置。
</p>

##### add_cxflags

###### 添加c/c++编译选项

同时对c/c++代码添加编译选项

##### add_cxxflags

###### 添加c++编译选项

仅对c++代码添加编译选项

##### add_mflags

###### 添加objcc编译选项 

仅对objc代码添加编译选项

```lua
add_mflags("-g", "-O2", "-DDEBUG")
```

##### add_mxflags

###### 添加objc/objc++编译选项

同时对objc/objc++代码添加编译选项

```lua
add_mxflags("-framework CoreFoundation")
```

##### add_mxxflags

###### 添加objc++编译选项

仅对objc++代码添加编译选项

```lua
add_mxxflags("-framework CoreFoundation")
```

##### add_scflags

###### 添加swift编译选项

对swift代码添加编译选项

```lua
add_scflags("xxx")
```

##### add_asflags

###### 添加汇编编译选项

对汇编代码添加编译选项

```lua
add_asflags("xxx")
```

##### add_goflags

###### 添加go编译选项

对golang代码添加编译选项

```lua
add_goflags("xxx")
```

##### add_ldflags

###### 添加链接选项

添加静态链接库选项

```lua
add_ldflags("-L/xxx", "-lxxx")
```

##### add_arflags

###### 添加静态库归档选项

影响对静态库的生成

```lua
add_arflags("xxx")
```
##### add_shflags

###### 添加动态库链接选项

影响对动态库的生成

```lua
add_shflags("xxx")
```

##### add_cfuncs
##### add_cxxfuncs
##### add_options

###### 添加关联选项

这个接口跟[set_options](#set_options)类似，唯一的区别就是，此处是追加选项，而[set_options](#set_options)每次设置会覆盖先前的设置。

##### add_packages

###### 添加包依赖

在target作用域中，添加集成包依赖，例如：

```lua
target("test")
    add_packages("zlib", "polarssl", "pcre", "mysql")
```

这样，在编译test目标时，如果这个包存在的，将会自动追加包里面的宏定义、头文件搜索路径、链接库目录，也会自动链接包中所有库。

用户不再需要自己单独调用[add_links](#add_links)，[add_includedirs](#add_includedirs), [add_ldflags](#add_ldflags)等接口，来配置依赖库链接了。

对于如何设置包搜索目录，可参考：[add_packagedirs](#add_packagedirs) 接口

##### add_languages

###### 添加语言标准

与[set_languages](#set_languages)类似，唯一区别是这个接口不会覆盖掉之前的设置，而是追加设置。

##### add_vectorexts

###### 添加向量扩展指令

添加扩展指令优化选项，目前支持以下几种扩展指令集：

```lua
add_vectorexts("mmx")
add_vectorexts("neon")
add_vectorexts("avx", "avx2")
add_vectorexts("sse", "sse2", "sse3", "ssse3")
```

<p class="tip">
如果当前设置的指令集编译器不支持，xmake会自动忽略掉，所以不需要用户手动去判断维护，只需要将你需要的指令集全部设置上就行了。
</p>

#### 选项定义

定义和设置选项开关，每个`option`对应一个选项，可用于自定义编译配置选项、开关设置。


| 接口                                            | 描述                                         |
| ----------------------------------------------- | -------------------------------------------- |
| [option](#option)                               | 定义选项                                     |
| [set_default](#set_default)                     | 设置默认值                                   |
| [set_showmenu](#set_showmenu)                   | 设置是否启用菜单显示                         |
| [set_category](#set_category)                   | 设置选项分类，仅用于菜单显示                 |
| [set_description](#set_description)             | 设置菜单显示描述                             |
| [add_bindings](#add_bindings)                   | 添加关联选项，同步启用和禁用                 |
| [add_rbindings](#add_rbindings)                 | 添加逆向关联选项，同步启用和禁用             |
| [add_cincludes](#add_cincludes)                 | 添加c头文件检测                              |
| [add_cxxincludes](#add_cxxincludes)             | 添加c++头文件检测                            |
| [add_ctypes](#add_ctypes)                       | 添加c类型检测                                |
| [add_cxxtypes](#add_cxxtypes)                   | 添加c++类型检测                              |
| [add_defines_if_ok](#add_defines_if_ok)         | 如果检测选项通过，则添加宏定义               |
| [add_defines_h_if_ok](#add_defines_h_if_ok)     | 如果检测选项通过，则添加宏定义到配置头文件   |
| [add_undefines_if_ok](#add_undefines_if_ok)     | 如果检测选项通过，则取消宏定义               |
| [add_undefines_h_if_ok](#add_undefines_h_if_ok) | 如果检测选项通过，则在配置头文件中取消宏定义 |

##### 通用接口 (target)

下面的这些接口，是跟`target`目标域接口通用的，在`option()`和`target()`域范围内都能同时使用，可直接参考上面`target`中的接口描述。

| 接口                                  | 描述                                 |
| ------------------------------------- | ------------------------------------ |
| [set_warnings](#set_warnings)         | 设置警告级别                         |
| [set_optimize](#set_optimize)         | 设置优化级别                         |
| [set_languages](#set_languages)       | 设置代码语言标准                     |
| [add_links](#add_links)               | 添加链接库名                         |
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
| [add_scflags](#add_scflags)           | 添加swift编译选项                    |
| [add_asflags](#add_asflags)           | 添加汇编编译选项                     |
| [add_goflags](#add_goflags)           | 添加go编译选项                       |
| [add_ldflags](#add_ldflags)           | 添加链接选项                         |
| [add_arflags](#add_arflags)           | 添加静态库归档选项                   |
| [add_shflags](#add_shflags)           | 添加动态库链接选项                   |
| [add_cfuncs](#add_cfuncs)             | 添加c库函数检测                      |
| [add_cxxfuncs](#add_cxxfuncs)         | 添加c++库函数接口                    |
| [add_languages](#add_languages)       | 添加语言标准                         |
| [add_vectorexts](#add_vectorexts)     | 添加向量扩展指令                     |


##### option

###### 定义选项

定义和设置选项开关，可用于自定义编译配置选项、开关设置。

例如，定义一个是否启用test的选项：

```lua
option("test")
    set_default(false)
    set_showmenu(true)
    add_defines("-DTEST")
```

然后关联到指定的target中去：

```lua
target("demo")
    add_options("test")
```

这样，一个选项就算定义好了，如果这个选项被启用，那么编译这个target的时候，就会自动加上`-DTEST`的宏定义。

```lua
# 手动启用这个选项
$ xmake f --test=y
$ xmake
```

##### set_default

###### 设置选项默认值

在没有通过`xmake f --option=[y|n}`等命令修改选项值的时候，这个选项本身也是有个默认值的，可以通过这个接口来设置：

```lua
option("test")
    -- 默认禁用这个选项
    set_default(false)
```

选项的值不仅支持boolean类型，也可以是字符串类型，例如：

```lua
option("test")
    set_default("value")
```

| 值类型  | 描述                                   | 配置                                           |
| ------  | -------------------------------------- | -----------------------------------------------|
| boolean | 一般用作参数开关，值范围：`true/false` | `xmake f --optionname=[y/n/yes/no/true/false]` |
| string  | 可以是任意字符串，一般用于模式判断     | `xmake f --optionname=value`                   |

如果是`boolean`值的选项，可以通过[is_option](#is_option)来进行判断，选项是否被启用。

如果是`string`类型的选项，可以在内建变量中直接使用，例如：

```lua
-- 定义一个路径配置选项，默认使用临时目录
option("rootdir")
    set_default("$(tmpdir)")

target("test")
    -- 添加指定选项目录中的源文件
    add_files("$(rootdir)/*.c")
```

其中，`$(rootdir)` 就是自定义的选项内建变量，通过手动配置，可以动态修改它的值：

```bash
$ xmake f --rootdir=~/projectdir/src
$ xmake
```

给这个`rootdir`选项指定一个其他的源码目录路径，然后编译。

##### set_showmenu
##### set_category
##### set_description
##### add_bindings
##### add_rbindings
##### add_ctypes
##### add_cxxtypes
##### add_defines_if_ok
##### add_defines_h_if_ok
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

#### 内置模块

##### import
##### inherit
##### ifelse
##### try-catch-finally
##### pairs
##### ipairs
##### print
##### printf
##### cprint
##### cprintf
##### raise

##### table

###### insert
###### join
###### join2
###### concat
###### dump

##### path

###### join
###### basename
###### filename
###### directory
###### relative
###### absolute
###### is_absolute

##### io
##### os
##### string
##### process
##### coroutine

#### 扩展模块

##### core.base.option
##### core.tool.tool
##### core.tool.linker
##### core.tool.compiler
##### core.project.config
##### core.project.global
##### core.project.target
##### core.project.task
##### core.project.cache
##### core.project.project
##### core.language.language
##### core.platform.platform
##### core.platform.environment
