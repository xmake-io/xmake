--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        checker.lua
--

-- imports
import("core.tool.tool")
import("core.base.option")
import("platforms.checker", {rootdir = os.programdir()})
import("environment")

-- attempt to apply this visual stdio from the given the envirnoment variable
function _apply_vs(config, envalue)

    -- get the vcvarsall.bat path
    local vcvarsall = format("%s\\..\\..\\VC\\vcvarsall.bat", envalue)

    -- skip it if vcvarsall.bat not found
    if not os.isfile(vcvarsall) then
        if option.get("verbose") then
            print("not found %s", vcvarsall)
        end
        return 
    end

    -- make the genvcvars.bat 
    local genvcvars_bat = path.join(os.tmpdir(), "xmake.genvcvars.bat")
    local genvcvars_dat = path.join(os.tmpdir(), "xmake.genvcvars.dat")
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

    -- checked?
    if config.get("vs") and config.get("__vsenv_path") then 
        return 
    end

    -- envname => version
    local envname2version =
    {
        VS140COMNTOOLS  = "2015"
    ,   VS120COMNTOOLS  = "2013"
    ,   VS110COMNTOOLS  = "2012"
    ,   VS100COMNTOOLS  = "2010"
    ,   VS90COMNTOOLS   = "2008"
    ,   VS80COMNTOOLS   = "2005"
    ,   VS71COMNTOOLS   = "2003"
    ,   VS70COMNTOOLS   = "7.0"
    ,   VS60COMNTOOLS   = "6.0"
    ,   VS50COMNTOOLS   = "5.0"
    ,   VS42COMNTOOLS   = "4.2"
    }

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

    -- attempt to check the given vs version first
    local vs = config.get("vs")
    if vs then
        
        -- get the envname
        local envname = version2envname[vs]

        -- clear vs first
        vs = nil

        -- attempt to check it
        if envname then
            local envalue = os.getenv(envname)
            if envalue and _apply_vs(config, envalue) then
                vs = version
            end
        end
    end

    -- attempt to check them from the envirnoment variables again
    if not vs then
        for envname, version in pairs(envname2version) do

            -- attempt to get envirnoment variable and check it
            local envalue = os.getenv(envname)
            if envalue and _apply_vs(config, envalue) then
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
        print("checking for the Microsoft Visual Studio version ... %s", vs)
    else
        -- failed
        print("checking for the Microsoft Visual Studio version ... no")
        print("please run:")
        print("    - xmake config --vs=xxx")
        print("or  - xmake global --vs=xxx")
        raise()
    end
end

-- check the toolchains
function _check_toolchains(config)

    -- enter environment
    environment.enter("toolchains")

    -- done
    checker.check_toolchain(config, "cc",   "", "cl.exe",           "the c compiler") 
    checker.check_toolchain(config, "cxx",  "", "cl.exe",           "the c++ compiler") 
    checker.check_toolchain(config, "ld",   "", "link.exe",         "the linker") 
    checker.check_toolchain(config, "ar",   "", "link.exe -lib",    "the static library archiver") 
    checker.check_toolchain(config, "sh",   "", "link.exe -dll",    "the shared library linker") 
    checker.check_toolchain(config, "ex",   "", "lib.exe",          "the static library extractor") 
    if config.get("arch"):find("64") then
        checker.check_toolchain(config, "as",   "", "ml64.exe",     "the assember") 
    else
        checker.check_toolchain(config, "as",   "", "ml.exe",       "the assember") 
    end

    -- leave environment
    environment.leave("toolchains")
end

-- check the debugger
function _check_debugger(config)

    -- get debugger
    local debugger = config.get("dd")
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
        config.set("dd", debugger)

        -- trace
        print("checking for the debugger ... %s", path.filename(debugger))
    else
        -- failed
        print("checking for the debugger ... no")
    end
end

-- init it
function init()

    -- init the check list of config
    _g.config = 
    {
        { checker.check_arch, "x86" }
    ,   _check_vs
    ,   _check_toolchains
    ,   _check_debugger
    }

    -- init the check list of global
    _g.global = 
    {
        _check_vs
    }

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

