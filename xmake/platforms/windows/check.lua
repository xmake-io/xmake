--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check.lua
--

-- imports
import("core.tool.tool")
import("core.base.option")
import("platforms.checker", {rootdir = os.programdir()})
import("environment")

-- attempt to apply vs environment
function _apply_vsenv(config, vs)

    -- version => envname
    local version2envname =
    {
        ["2015"]    = "VS140COMNTOOLS"
    ,   ["2013"]    = "VS120COMNTOOLS"
    ,   ["2012"]    = "VS110COMNTOOLS"
    ,   ["2010"]    = "VS100COMNTOOLS"
    ,   ["2008"]    = "VS90COMNTOOLS"
    ,   ["2005"]    = "VS80COMNTOOLS"
    ,   ["2003"]    = "VS71COMNTOOLS"
    ,   ["7.0"]     = "VS70COMNTOOLS"
    ,   ["6.0"]     = "VS60COMNTOOLS"
    ,   ["5.0"]     = "VS50COMNTOOLS"
    ,   ["4.2"]     = "VS42COMNTOOLS"
    }
    
    -- get the envname
    local envname = version2envname[vs]

    -- attempt to get vcvarsall.bat from environment variables
    local vcvarsall = nil
    if envname then
        local envalue = os.getenv(envname)
        if envalue then
            vcvarsall = format("%s\\..\\..\\VC\\vcvarsall.bat", envalue)
        end
    end

    -- attempt to get vcvarsall.bat from the full pathes 
    if vcvarsall == nil or not os.isfile(vcvarsall) then
        vcvarsall = nil
        for _, driver in ipairs({'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'X', 'Y', 'Z'}) do
            for _, programdir in ipairs({"Program Files (x86)", "Program Files"}) do
                for _, kind in ipairs({"Community", "Professional", "Enterprise"}) do
                    local filepath = format("%s:\\%s\\Microsoft Visual Studio\\%s\\%s\\VC\\Auxiliary\\Build\\vcvarsall.bat", driver, programdir, vs, kind)
                    if os.isfile(filepath) then
                        vcvarsall = filepath
                        break
                    end
                end
                if vcvarsall then 
                    break
                end
            end
            if vcvarsall then 
                break
            end
        end
    end
    
    -- vcvarsall.bat not found
    if vcvarsall == nil or not os.isfile(vcvarsall) then
        if vcvarsall and option.get("verbose") then
            print("not found %s", vcvarsall)
        end
        return 
    end

    -- make the genvcvars.bat 
    local genvcvars_bat = os.tmpfile() .. "_genvcvars.bat"
    local genvcvars_dat = os.tmpfile() .. "_genvcvars.dat"
    local file = io.open(genvcvars_bat, "w")
    file:print("@echo off")
    file:print("call \"%s\" %s > nul", vcvarsall, config.get("arch"))
    file:print("echo { > %s", genvcvars_dat)
    file:print("echo     path = \"%%path%%\" >> %s", genvcvars_dat)
    file:print("echo ,   lib = \"%%lib%%\" >> %s", genvcvars_dat)
    file:print("echo ,   libpath = \"%%libpath%%\" >> %s", genvcvars_dat)
    file:print("echo ,   include = \"%%include%%\" >> %s", genvcvars_dat)
    file:print("echo ,   devenvdir = \"%%devenvdir%%\" >> %s", genvcvars_dat)
    file:print("echo ,   vsinstalldir = \"%%vsinstalldir%%\" >> %s", genvcvars_dat)
    file:print("echo ,   vcinstalldir = \"%%vcinstalldir%%\" >> %s", genvcvars_dat)
    file:print("echo } >> %s", genvcvars_dat)
    file:close()

    -- run genvcvars.bat
    os.run(genvcvars_bat)

    -- replace "\" => "\\"
    io.gsub(genvcvars_dat, "\\", "\\\\")

    -- load all envirnoment variables
    local variables = io.load(genvcvars_dat)

    -- save the variables
    for k, v in pairs(variables) do
        config.set("__vsenv_" .. k, v)
    end

    -- ok
    return true
end

-- clean temporary global configs
function _clean_global(config)
    
    -- clean it for global config (need not it)
    config.set("arch",                  nil)
    config.set("__vsenv_path",          nil)
    config.set("__vsenv_lib",           nil)
    config.set("__vsenv_include",       nil)
    config.set("__vsenv_libpath",       nil)
    config.set("__vsenv_devenvdir",     nil)
    config.set("__vsenv_vsinstalldir",  nil)
    config.set("__vsenv_vcinstalldir",  nil)
end

-- attempt to check complier
function _check_compiler(config, vs)

    -- apply vs envirnoment
    if not _apply_vsenv(config, vs) then
        return 
    end

    -- enter environment
    environment.enter("toolchains")

    -- done
    local toolpath = tool.check("cl.exe")

    -- leave environment
    environment.leave("toolchains")

    -- ok?
    return toolpath 
end

-- check the visual stdio
function _check_vs(config)

    -- attempt to check the given vs version first
    local vs = config.get("vs")
    if vs and _check_compiler(config, vs) then
        return 
    end

    -- attempt to check them from the envirnoment variables again
    vs = nil
    if not vs then
        for _, version in ipairs({"2017", "2015", "2013", "2012", "2010", "2008", "2005", "2003", "7.0", "6.0", "5.0", "4.2"}) do

            -- attempt to check it
            if _check_compiler(config, version) then
                vs = version
                break
            end
        end
    end

    -- check ok? update it
    if vs then

        -- save it
        config.set("vs", vs)

        -- trace
        print("checking for the Microsoft Visual Studio (%s) version ... %s", config.get("arch"), vs)
    else
        -- failed
        print("checking for the Microsoft Visual Studio (%s) version ... no", config.get("arch"))
        print("please run:")
        print("    - xmake config --vs=xxx")
        print("or  - xmake global --vs=xxx")
        raise()
    end
end

-- check the debugger
function _check_debugger(config)

    -- get debugger
    local debugger = config.get("dg")
    if debugger then
        return
    end

    -- query the debugger info for x64
    local info = try
    {
        function ()
            return os.iorun("reg query \"HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug\" /v Debugger")
        end
    }
    -- query the debugger info for x86
    if not info then
        info = try
        {
            function ()
                return os.iorun("reg query \"HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug\" /v Debugger")
            end
        }
    end

    -- parse the debugger path
    --
    -- ! REG.EXE VERSION 3.0
    --
    -- HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug
    -- Debugger    REG_SZ  "C:\WINDOWS\system32\vsjitdebugger.exe" -p %ld -e %ld
    if info then
        debugger = info:match("Debugger%s+REG_SZ%s+\"(.+)\"")
        if debugger then
            debugger = debugger:trim()
        end
    end

    -- this debugger exists?
    if debugger and path.is_absolute(debugger) and not os.isfile(debugger) then
        debugger = nil
    end

    -- check ok? update it
    if debugger then

        -- save it
        config.set("dg", debugger)

        -- trace
        print("checking for the debugger ... %s", path.filename(debugger))
    else
        -- failed
        print("checking for the debugger ... no")
    end
end

-- get toolchains
function _toolchains(config)

    -- attempt to get it from cache first
    if _g.TOOLCHAINS then
        return _g.TOOLCHAINS
    end

    -- init toolchains
    local toolchains = {}

    -- insert c/c++ tools to toolchains
    checker.toolchain_insert(toolchains, "cc",      "",     "cl.exe",           "the c compiler") 
    checker.toolchain_insert(toolchains, "cxx",     "",     "cl.exe",           "the c++ compiler") 
    checker.toolchain_insert(toolchains, "ld",      "",     "link.exe",         "the linker") 
    checker.toolchain_insert(toolchains, "ar",      "",     "link.exe -lib",    "the static library archiver") 
    checker.toolchain_insert(toolchains, "sh",      "",     "link.exe -dll",    "the shared library linker") 
    checker.toolchain_insert(toolchains, "ex",      "",     "lib.exe",          "the static library extractor") 

    -- insert golang tools to toolchains
    checker.toolchain_insert(toolchains, "gc",       "",    "go",               "the golang compiler") 
    checker.toolchain_insert(toolchains, "gc",       "",    "gccgo",            "the golang compiler") 
    checker.toolchain_insert(toolchains, "gc-ar",    "",    "go",               "the golang static library archiver") 
    checker.toolchain_insert(toolchains, "gc-ar",    "",    "gccgo",            "the golang static library archiver") 
    checker.toolchain_insert(toolchains, "gc-ld",    "",    "go",               "the golang linker") 
    checker.toolchain_insert(toolchains, "gc-ld",    "",    "gccgo",            "the golang linker") 

    -- insert dlang tools to toolchains
    checker.toolchain_insert(toolchains, "dc",       "",    "dmd",              "the dlang compiler") 
    checker.toolchain_insert(toolchains, "dc",       "",    "ldc2",             "the dlang compiler") 
    checker.toolchain_insert(toolchains, "dc",       "",    "gdc",              "the dlang compiler") 
    checker.toolchain_insert(toolchains, "dc-ar",    "",    "dmd",              "the dlang static library archiver") 
    checker.toolchain_insert(toolchains, "dc-ar",    "",    "ldc2",             "the dlang static library archiver") 
    checker.toolchain_insert(toolchains, "dc-ar",    "",    "gdc",              "the dlang static library archiver") 
    checker.toolchain_insert(toolchains, "dc-sh",    "",    "dmd",              "the dlang shared library linker") 
    checker.toolchain_insert(toolchains, "dc-sh",    "",    "ldc2",             "the dlang shared library linker") 
    checker.toolchain_insert(toolchains, "dc-sh",    "",    "gdc",              "the dlang shared library linker") 
    checker.toolchain_insert(toolchains, "dc-ld",    "",    "dmd",              "the dlang linker") 
    checker.toolchain_insert(toolchains, "dc-ld",    "",    "ldc2",             "the dlang linker") 
    checker.toolchain_insert(toolchains, "dc-ld",    "",    "gdc",              "the dlang linker") 

    -- insert rust tools to toolchains
    checker.toolchain_insert(toolchains, "rc",       "",    "rustc",            "the rust compiler") 
    checker.toolchain_insert(toolchains, "rc-ar",    "",    "rustc",            "the rust static library archiver") 
    checker.toolchain_insert(toolchains, "rc-sh",    "",    "rustc",            "the rust shared library linker") 
    checker.toolchain_insert(toolchains, "rc-ld",    "",    "rustc",            "the rust linker") 

    -- insert asm tools to toolchains
    if config.get("arch"):find("64") then
        checker.toolchain_insert(toolchains, "as",   "",    "ml64.exe",         "the assember") 
    else
        checker.toolchain_insert(toolchains, "as",   "",    "ml.exe",           "the assember") 
    end

    -- save toolchains
    _g.TOOLCHAINS = toolchains

    -- ok
    return toolchains
end

-- check it
function main(kind, toolkind)

    -- only check the given tool?
    if toolkind then

        -- import the given config
        local config = import("core.project." .. kind)

        -- apply vs envirnoment (maybe config.arch has been updated)
        if not _apply_vsenv(config, config.get("vs")) then
            return 
        end

        -- enter environment
        environment.enter("toolchains")

        -- check it
        checker.toolchain_check(config, toolkind, _toolchains)

        -- leave environment
        environment.leave("toolchains")

        -- end
        return 
    end

    -- init the check list of config
    _g.config = 
    {
        { checker.check_arch, "x86" }
    ,   _check_vs
    ,   _check_debugger
    }

    -- init the check list of global
    _g.global = 
    {
        { checker.check_arch, "x86" }
    ,   _check_vs
    ,   _clean_global
    }

    -- check it
    checker.check(kind, _g)
end

