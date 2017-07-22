---
search: en
---

## Plugin Development

#### Introduction

XMake supports the plugin module and we can develop ourself plugin module conveniently.

We can run command `xmake -h` to look over some builtin plugins of xmake

```
Plugins: 
    l, lua                                 Run the lua script.
    m, macro                               Run the given macro.
       doxygen                             Generate the doxygen document.
       hello                               Hello xmake!
       project                             Create the project file.
```

* lua: Run a given lua script.
* macro: Record and playback some xmake commands repeatly.
* doxygen：Generate doxygen document automatically.
* hello:  The demo plugin and only print: 'hello xmake!'
* project：Generate project file for IDE, only generate makefile now and will generate vs, xcode project in the future

#### Quick Start

Now we write a simple plugin demo for printing 'hello xmake!'

```lua
-- define a plugin task 
task("hello")

    -- set the category for showing it in plugin category menu (optional)
    set_category("plugin")

    -- the main entry of the plugin
    on_run(function ()

        -- print 'hello xmake!'
        print("hello xmake!")
    end)

    -- set the menu options, but we put empty options now.
    set_menu {
                -- usage
                usage = "xmake hello [options]"

                -- description
            ,   description = "Hello xmake!"

                -- options
            ,   options = {}
            }
```

The file tree of this plugin:

```
hello
 - xmake.lua

``` 

Now one of the most simple plugin finished, how was it to be xmake detected it, there are three ways:

1. Put this plugin directory into xmake/plugins the source codes as the builtin plugin.
2. Put this plugin directory into ~/.xmake/plugins as the global user plugin.
3. Put this plugin directory to anywhere and call `add_plugindirs("./hello")` in xmake.lua as the local project plugin.

#### Run Plugin

Next we run this plugin

```bash
xmake hello
```

The results is 

```
hello xmake!
```

Finally, we can also run this plugin in the custom scripts of `xmake.lua`

```lua

target("demo")
    
    -- run this plugin after building target
    after_build(function (target)
  
        -- import task module
        import("core.project.task")

        -- run the plugin task
        task.run("hello")
    end)
```

## Builtin Plugins

#### Macros Recording and Playback 

##### Introduction

We can record and playback our xmake commands and save as macro quickly using this plugin.

And we can run this macro to simplify our jobs repeatly.

##### Record Commands

```bash
# begin to record commands
$ xmake macro --begin

# run some xmake commands
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

# stop to record and  save as anonymous macro
xmake macro --end 
```

##### Playback Macro

```bash
# playback the previous anonymous macro
$ xmake macro .
```

##### Named Macro

```bash
$ xmake macro --begin
$ ...
$ xmake macro --end macroname
$ xmake macro macroname
```

##### Import and Export Macro

Import the given macro file or directory.

```bash
$ xmake macro --import=/xxx/macro.lua macroname
$ xmake macro --import=/xxx/macrodir
```

Export the given macro to file or directory.

```bash
$ xmake macro --export=/xxx/macro.lua macroname
$ xmake macro --export=/xxx/macrodir
```

##### List and Show Macro

List all builtin macros.

```bash
$ xmake macro --list
```

Show the given macro script content.

```bash
$ xmake macro --show macroname
```

##### Custom Macro Script

Create and write a `macro.lua` script first.

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

Import this macro script to xmake.

```bash
$ xmake macro --import=/xxx/macro.lua [macroname]
```

Playback this macro script.

```bash
$ xmake macro [.|macroname]
```

##### Builtin Macros

XMake supports some builtins macros to simplify our jobs.

For example, we use `package` macro to package all architectures of the iphoneos platform just for once.

```bash
$ xmake macro package -p iphoneos 
```

##### Advance Macro Script

Let's see the `package` macro script:

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
    If you want to known more options, please run: `xmake macro --help`
</p>

#### Run the Custom Lua Script

##### Run the given script

Write a simple lua script:

```lua
function main()
    print("hello xmake!")
end
```

Run this lua script.

```bash
$ xmake lua /tmp/test.lua
```

<p class="tip">
    You can also use `import` api to write a more advance lua script. 
</p>

##### Run the builtin script

You can run `xmake lua -l` to list all builtin script name, for example:

```bash
$ xmake lua -l
scripts:
    cat
    cp
    echo
    versioninfo
    ...
```

And run them:

```bash
$ xmake lua cat ~/file.txt
$ xmake lua echo "hello xmake"
$ xmake lua cp /tmp/file /tmp/file2
$ xmake lua versioninfo
```

##### Run interactive commands (REPL) 

Enter interactive mode:

```bash
$ xmake lua
> 1 + 2
3

> a = 1
> a
1

> for _, v in pairs({1, 2, 3}) do
>> print(v)
>> end
1
2
3
```

And we can `import` modules:

```bash
> task = import("core.project.task")
> task.run("hello")
hello xmake!
```

If you want to cancel multiline input, please input character `q`, for example:

```bash
> for _, v in ipairs({1, 2}) do
>> print(v)
>> q             <--  cancel multiline and clear previous input
> 1 + 2
3
```

#### Generate IDE Project Files

##### Generate Makefile

```bash
$ xmake project -k makefile
```

##### Generate compiler_commands

We can export the compilation commands info of all source files and it is JSON compilation database format.

```console
$ xmake project -k compile_commands
```

The the content of the output file:

```
[
  { "directory": "/home/user/llvm/build",
    "command": "/usr/bin/clang++ -Irelative -DSOMEDEF=\"With spaces, quotes and \\-es.\" -c -o file.o file.cc",
    "file": "file.cc" },
  ...
]

```

Please see [JSONCompilationDatabase](#https://clang.llvm.org/docs/JSONCompilationDatabase.html) if need known more info about `compile_commands`.

##### Generate VisualStudio Project

```bash
$ xmake project -k [vs2008|vs2013|vs2015|..]
```

v2.1.2 or later, it supports multi-mode and multi-architecture generation for vs201x project.

For example:

```bash
$ xmake project -k vs2017 -m "debug,release"
```

It will generate four project configurations: `debug|x86`, `debug|x64`, `release|x86`, `release|x64`.

Or you can set modes to `xmake.lua`:

```lua
set_modes("debug", "release")
```

Then, we run the following command:

```bash
$ xmake project -k vs2017
```

The effect is same.

#### Generate Doxygen Document

Please ensure that the doxygen tool has been installed first.

```bash
$ xmake doxygen
```

## More Plugins

Please download and install from the plugins repository [xmake-plugins](https://github.com/tboox/xmake-plugins).

#### Convert .app to .ipa

```bash
$ xmake app2ipa --icon=/xxx.png /xxx/ios.app -o /xxx.ios.ipa
```
