--!The Automatic Cross-platform Build Tool
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
import("platforms.checker", {rootdir = os.programdir()})
import("environment")

-- check the vs version
function _check_vs_version(config)

    -- get the vs version
    local vs = config.get("vs")
    if not vs then 

        -- make the map table
        local map =
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

        -- attempt to get it from the envirnoment variable
        for k, v in pairs(map) do
            if os.getenv(k) then
                vs = v
                break
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
end

-- check the vs path
function _check_vs_path(config)

    -- no vs path?
    if not config.get("__vsenv_path") then 

        -- get the vs version
        local vs = config.get("vs")

        -- make the map table
        local map =
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

        -- check
        if not map[vs] then
            raise("vs %s not support!", vs)
        end

        -- the vcvarsall.bat path
        local vcvarsall = format("%s\\..\\..\\VC\\vcvarsall.bat", os.getenv(map[vs]))
        if not os.isfile(vcvarsall) then
            raise("not found %s", vcvarsall)
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
    end
end

-- check the toolchains
function _check_toolchains(config)

    -- enter environment
    environment.enter("toolchains")

    -- done
    checker.check_toolchain(config, "cc",   "", "cl.exe",           "the c compiler") 
    checker.check_toolchain(config, "cxx",  "", "cl.exe",           "the c++ compiler") 
    checker.check_toolchain(config, "as",   "", "ml.exe",           "the assember") 
    checker.check_toolchain(config, "ld",   "", "link.exe",         "the linker") 
    checker.check_toolchain(config, "ar",   "", "link.exe -lib",    "the static library linker") 
    checker.check_toolchain(config, "sh",   "", "link.exe -dll",    "the shared library linker") 
    checker.check_toolchain(config, "ex",   "", "lib.exe",          "the library extractor") 
    checker.check_toolchain(config, "make", "", "nmake.exe",        "the make") 

    -- leave environment
    environment.leave("toolchains")
end

-- init it
function init()

    -- init the check list of config
    _g.config = 
    {
        { checker.check_arch, "x86" }
    ,   _check_vs_version
    ,   _check_vs_path
    ,   _check_toolchains
    }

    -- init the check list of global
    _g.global = 
    {
        _check_vs_version
    ,   _check_vs_path
    }

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

