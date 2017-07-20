---
nav: zh
search: zh
---

## 插件开发

#### 简介

XMake完全支持插件模式，我们可以很方便的扩展实现自己的插件，并且xmake也提供了一些内建的使用插件。

我们可以执行下 `xmake -h` 看下当前支持的插件：

```
Plugins: 
    l, lua                                 Run the lua script.
    m, macro                               Run the given macro.
       doxygen                             Generate the doxygen document.
       hello                               Hello xmake!
       project                             Create the project file.
```

* lua: 运行lua脚本的插件
* macro: 这个很实用，宏脚本插件，可以手动录制多条xmake命令并且回放，也可以通过脚本实现一些复杂的宏脚本，这个我们后续会更加详细的介绍
* doxygen：一键生成doxygen文档的插件
* hello: 插件demo，仅仅显示一句话：'hello xmake!'
* project： 生成工程文件的插件，目前仅支持(makefile)，后续还会支持(vs,xcode等工程)的生成

#### 快速开始

接下来我们介绍下本文的重点，一个简单的hello xmake插件的开发，代码如下：

```lua
-- 定义一个名叫hello的插件任务
task("hello")

    -- 设置类型为插件
    set_category("plugin")

    -- 插件运行的入口
    on_run(function ()

        -- 显示hello xmake!
        print("hello xmake!")

    end)

    -- 设置插件的命令行选项，这里没有任何参数选项，仅仅显示插件描述
    set_menu {
                -- usage
                usage = "xmake hello [options]"

                -- description
            ,   description = "Hello xmake!"

                -- options
            ,   options = {}
            } 
```

这个插件的文件结构如下：

```
hello
 - xmake.lua

``` 

现在一个最简单的插件写完了，那怎么让它被xmake检测到呢，有三种方式：

1. 把 hello 这个文件夹放置在 xmake的插件安装目录 xmake/plugins，这个里面都是些内建的插件
2. 把 hello 文件夹防止在 ~/.xmake/plugins 用户全局目录，这样对当前xmake 全局生效
3. 把 hello 文件夹防止在任意地方，通过在工程描述文件xmake.lua中调用`add_plugindirs("./hello")` 添加当前的工程的插件搜索目录，这样只对当前工程生效

#### 运行插件

接下来，我们尝试运行下这个插件：

```bash
xmake hello
```

显示结果：

```
hello xmake!
```

最后我们还可以在target自定义的脚本中运行这个插件：

```lua
target("demo")
    
    -- 构建之后运行插件
    after_build(function (target)
  
        -- 导入task模块
        import("core.project.task")

        -- 运行插件任务
        task.run("hello")
    end)
```

## 内置插件

#### 宏记录和回放

##### 简介

我们可以通过这个插件，快速记录和回放我们平常频繁使用到的一些xmake操作，来简化我们日常的开发工作。

它提供了一些功能：

* 手动记录和回放多条执行过的xmake命令
* 支持快速的匿名宏创建和回放
* 支持命名宏的长久记录和重用
* 支持宏脚本的批量导入和导出
* 支持宏脚本的删除、显示等管理功能
* 支持自定义高级宏脚本，以及参数配置

##### 记录操作

```bash
# 开始记录宏
$ xmake macro --begin

# 执行一些xmake命令
$ xmake f -p android --ndk=/xxx/ndk -a armv7-a
$ xmake p
$ xmake f -p mingw --sdk=/mingwsdk
$ xmake p
$ xmake f -p linux --sdk=/toolsdk --toolchains=/xxxx/bin
$ xmake p
$ xmake f -p iphoneos -a armv7
$ xmake p
$ xmake f -p iphoneos -a arm64
$ xmake p
$ xmake f -p iphoneos -a armv7s
$ xmake p
$ xmake f -p iphoneos -a i386
$ xmake p
$ xmake f -p iphoneos -a x86_64
$ xmake p

# 结束宏记录，这里不设置宏名字，所以记录的是一个匿名宏
xmake macro --end 
```

##### 回放

```bash
# 回放一个匿名宏
$ xmake macro .
```

##### 命名宏

匿名宏的好处就是快速记录，快速回放，如果需要长久保存，就需要给宏取个名字。

```bash
$ xmake macro --begin
$ ...
$ xmake macro --end macroname
$ xmake macro macroname
```

##### 导入导出宏

导入指定的宏脚本或者宏目录：

```bash
$ xmake macro --import=/xxx/macro.lua macroname
$ xmake macro --import=/xxx/macrodir
```

导出指定的宏到脚本或者目录：

```bash
$ xmake macro --export=/xxx/macro.lua macroname
$ xmake macro --export=/xxx/macrodir
```

##### 列举显示宏

列举所有`xmake`内置的宏脚本：

```bash
$ xmake macro --list
```

显示指定的宏脚本内容：

```bash
$ xmake macro --show macroname
```

##### 自定义宏脚本

我们也可以自己编写个宏脚本 `macro.lua` 然后导入到xmake中去。

```lua
function main()
    os.exec("xmake f -p android --ndk=/xxx/ndk -a armv7-a")
    os.exec("xmake p")
    os.exec("xmake f -p mingw --sdk=/mingwsdk")
    os.exec("xmake p")
    os.exec("xmake f -p linux --sdk=/toolsdk --toolchains=/xxxx/bin")
    os.exec("xmake p")
    os.exec("xmake f -p iphoneos -a armv7")
    os.exec("xmake p")
    os.exec("xmake f -p iphoneos -a arm64")
    os.exec("xmake p")
    os.exec("xmake f -p iphoneos -a armv7s")
    os.exec("xmake p")
    os.exec("xmake f -p iphoneos -a i386")
    os.exec("xmake p")
    os.exec("xmake f -p iphoneos -a x86_64")
    os.exec("xmake p")  
end
```

导入到xmake，并且定义宏名字：

```bash
$ xmake macro --import=/xxx/macro.lua [macroname]
```

回放这个宏脚本：

```bash
$ xmake macro [.|macroname]
```

##### 内置的宏脚本

XMake 提供了一些内置的宏脚本，来简化我们的日常开发工作。

例如，我们可以使用 `package` 宏来对`iphoneos`平台的所有架构，一次性批量构建和打包：

```bash
$ xmake macro package -p iphoneos 
```

##### 高级的宏脚本编写

以上面提到的`package`宏为例，我们看下其具体代码，里面通过`import`导入一些扩展模块，实现了复杂的脚本操作。


```lua
-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")

-- the options
local options =
{
    {'p', "plat",       "kv",  os.host(),   "Set the platform."                                    }
,   {'f', "config",     "kv",  nil,         "Pass the config arguments to \"xmake config\" .."     }
,   {'o', "outputdir",  "kv",  nil,         "Set the output directory of the package."             }
}

-- package all
--
-- .e.g
-- xmake m package 
-- xmake m package -f "-m debug"
-- xmake m package -p linux
-- xmake m package -p iphoneos -f "-m debug --xxx ..." -o /tmp/xxx
-- xmake m package -f \"--mode=debug\"
--
function main(argv)

    -- parse arguments
    local args = option.parse(argv, options, "Package all architectures for the given the platform."
                                           , ""
                                           , "Usage: xmake macro package [options]")

    -- package all archs
    local plat = args.plat
    for _, arch in ipairs(platform.archs(plat)) do

        -- config it
        os.exec("xmake f -p %s -a %s %s -c %s", plat, arch, args.config or "", ifelse(option.get("verbose"), "-v", ""))

        -- package it
        if args.outputdir then
            os.exec("xmake p -o %s %s", args.outputdir, ifelse(option.get("verbose"), "-v", ""))
        else
            os.exec("xmake p %s", ifelse(option.get("verbose"), "-v", ""))
        end
    end

    -- package universal for iphoneos, watchos ...
    if plat == "iphoneos" or plat == "watchos" then

        -- load configure
        config.load()

        -- load project
        project.load()

        -- enter the project directory
        os.cd(project.directory())

        -- the outputdir directory
        local outputdir = args.outputdir or config.get("buildir")

        -- package all targets
        for _, target in pairs(project.targets()) do

            -- get all modes
            local modedirs = os.match(format("%s/%s.pkg/lib/*", outputdir, target:name()), true)
            for _, modedir in ipairs(modedirs) do
                
                -- get mode
                local mode = path.basename(modedir)

                -- make lipo arguments
                local lipoargs = nil
                for _, arch in ipairs(platform.archs(plat)) do
                    local archfile = format("%s/%s.pkg/lib/%s/%s/%s/%s", outputdir, target:name(), mode, plat, arch, path.filename(target:targetfile())) 
                    if os.isfile(archfile) then
                        lipoargs = format("%s -arch %s %s", lipoargs or "", arch, archfile) 
                    end
                end
                if lipoargs then

                    -- make full lipo arguments
                    lipoargs = format("-create %s -output %s/%s.pkg/lib/%s/%s/universal/%s", lipoargs, outputdir, target:name(), mode, plat, path.filename(target:targetfile()))

                    -- make universal directory
                    os.mkdir(format("%s/%s.pkg/lib/%s/%s/universal", outputdir, target:name(), mode, plat))

                    -- package all archs
                    os.execv("xmake", {"l", "lipo", lipoargs})
                end
            end
        end
    end
end
```

<p class="tip">
    如果你想要获取更多宏参数选项信息，请运行： `xmake macro --help`
</p>

#### 运行自定义lua脚本

这个跟宏脚本类似，只是省去了导入导出操作，直接指定lua脚本来加载运行，这对于想要快速测试一些接口模块，验证自己的某些思路，都是一个不错的方式。

##### 运行指定的脚本文件

我们先写个简单的lua脚本：

```lua
function main()
    print("hello xmake!")
end
```

然后直接运行它就行了：

```bash
$ xmake lua /tmp/test.lua
```

<p class="tip">
    当然，你也可以像宏脚本那样，使用`import`接口导入扩展模块，实现复杂的功能。
</p>

##### 运行内置的脚本命令

你可以运行 `xmake lua -l` 来列举所有内置的脚本名，例如：

```bash
$ xmake lua -l
scripts:
    cat
    cp
    echo
    versioninfo
    ...
```

并且运行它们：

```bash
$ xmake lua cat ~/file.txt
$ xmake lua echo "hello xmake"
$ xmake lua cp /tmp/file /tmp/file2
$ xmake lua versioninfo
```

##### 运行交互命令 (REPL)

有时候在交互模式下，运行命令更加的方便测试和验证一些模块和api，也更加的灵活，不需要再去额外写一个脚本文件来加载。

我们先看下，如何进入交互模式：

```bash
# 不带任何参数执行，就可以进入
$ xmake lua
>

# 进行表达式计算
> 1 + 2
3

# 赋值和打印变量值
> a = 1
> a
1

# 多行输入和执行
> for _, v in pairs({1, 2, 3}) do
>> print(v)
>> end
1
2
3
```

我们也能够通过 `import` 来导入扩展模块：

```bash
> task = import("core.project.task")
> task.run("hello")
hello xmake!
```

如果要中途取消多行输入，只需要输入字符：`q` 就行了

```bash
> for _, v in ipairs({1, 2}) do
>> print(v)
>> q             <--  取消多行输入，清空先前的输入数据
> 1 + 2
3
```

#### 生成IDE工程文件

##### 简介

XMake跟`cmake`, `premake`等其他一些构建工具的区别在于：

<p class="warning">
`xmake`默认是直接构建运行的，生成第三方的IDE的工程文件仅仅作为`插件`来提供。
</p>

这样做的一个好处是：插件更加容易扩展，维护也更加独立和方便。

##### 生成Makefile

```bash
$ xmake project -k makefile
```

##### 生成VisualStudio工程

```bash
$ xmake project -k [vs2008|vs2013|vs2015|..]
```

v2.1.2以上版本，增强了vs201x版本工程的生成，支持多模式+多架构生成，生成的时候只需要指定：

```bash
$ xmake project -k vs2017 -m "debug,release"
```

生成后的工程文件，同时支持`debug|x86`, `debug|x64`, `release|x86`, `release|x64`四种配置模式。

如果不想每次生成的时候，指定模式，可以把模式配置加到`xmake.lua`的中，例如：

```lua
-- 配置当前的工程，支持哪些编译模式
set_modes("debug", "release")
```

具体`set_modes`的使用，可以参考对应的接口手册文档。

#### 生成doxygen文档

请先确保本机已安装`doxygen`工具，然后在工程目录下运行：

```bash
$ xmake doxygen
```

## 更多插件

请到插件仓库进行下载安装: [xmake-plugins](https://github.com/tboox/xmake-plugins).

#### 从app生成ipa包

这仅仅是一个小插件，ios开发的同学，可能会用的到。

```bash
$ xmake app2ipa --icon=/xxx.png /xxx/ios.app -o /xxx.ios.ipa
```
