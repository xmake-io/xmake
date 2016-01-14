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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        prober.lua
--

-- load modules
local io        = require("base/io")
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")
local config    = require("base/config")
local global    = require("base/global")
local tools     = require("tools/tools")
local platform  = require("base/platform")

-- define module: prober
local prober = prober or {}

-- probe the architecture
function prober._probe_arch(configs)

    -- get the architecture
    local arch = configs.get("arch")

    -- ok? 
    if arch then return true end

    -- init the default architecture
    configs.set("arch", "x86")

    -- trace
    utils.printf("checking for the architecture ... %s", configs.get("arch"))

    -- ok
    return true
end

-- probe the vs version
function prober._probe_vs_version(configs)

    -- get the vs version
    local vs = configs.get("vs")

    -- ok? 
    if vs then return true end

    -- clear it first
    vs = nil

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
    if not vs then
        for k, v in pairs(map) do
            if os.getenv(k) then
                vs = v
                break
            end
        end
    end

    -- probe ok? update it
    if vs then
        -- save it
        configs.set("vs", vs)

        -- trace
        utils.printf("checking for the Microsoft Visual Studio version ... %s", vs)
    else
        -- failed
        utils.error("checking for the Microsoft Visual Studio version ... no")
        utils.error("    - xmake config --vs=xxx")
        utils.error("or  - xmake global --vs=xxx")
        return false
    end

    -- ok
    return true
end

-- probe the vs path
function prober._probe_vs_path(configs)

    -- ok?
    if configs.get("__vsenv_path") then return true end

    -- get the vs version
    local vs = configs.get("vs")
    assert(vs)

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

    -- attempt to get the vs directory from the envirnoment variable
    local vsdir = map[vs]
    if vsdir then 
        vsdir = os.getenv(vsdir)
    end
    if vsdir then
        vsdir = vsdir .. "\\..\\.."
    end
    if not os.isdir(vsdir) then
        -- error
        utils.error("not found %s", vsdir)
        return false
    end

    -- the vcvarsall.bat path
    local vcvarsall = vsdir .. "\\VC\\vcvarsall.bat"
    if not os.isfile(vcvarsall) then
        -- error
        utils.error("not found %s", vcvarsall)
        return false
    end

    -- get the temporary directory
    local tmpdir = os.tmpdir()
    assert(tmpdir)

    -- make the call(vcvarsall.bat) file
    local callpath = tmpdir .. "\\call_vcvarsall.bat"
    local callfile = io.openmk(callpath)
    assert(callfile)

    -- make call scripts
    callfile:write("@echo off\n")
    callfile:write(string.format("call \"%s\" %s > nul\n", vcvarsall, configs.get("arch")))
    callfile:write("echo return \n")
    callfile:write("echo { \n")
    callfile:write("echo     path = \"%path%\"\n")
    callfile:write("echo ,   lib = \"%lib%\"\n")
    callfile:write("echo ,   libpath = \"%libpath%\"\n")
    callfile:write("echo ,   include = \"%include%\"\n")
    callfile:write("echo ,   devenvdir = \"%devenvdir%\"\n")
    callfile:write("echo ,   vsinstalldir = \"%vsinstalldir%\"\n")
    callfile:write("echo ,   vcinstalldir = \"%vcinstalldir%\"\n")
    callfile:write("echo } \n")

    -- close the file
    callfile:close()

    -- execute the call(vsvars32.bat) file and get all envirnoment variables
    local cmd = io.popen(callpath)
    local results = cmd:read("*all")
    cmd:close()

    -- translate '\' => '\\' 
    results = results:gsub("\\", "\\\\")

    -- get all envirnoment variables
    local variables = assert(loadstring(results))()
    if not variables or not variables.path then
        return false
    end

    -- save the variables
    for k, v in pairs(variables) do
        configs.set("__vsenv_" .. k, v)
    end

    -- ok
    return true
end

-- probe the tool path
function prober._probe_toolpath(configs, kind, name, description)

    -- check
    assert(kind)

    -- attempt to get it directly from the configure
    local toolpath = configs.get(kind)
    if toolpath then return true end

    -- make cmd
    local cmd = string.format("%s > %s 2>&1", name, xmake._NULDEV)
    if kind == "ld" then
        cmd = string.format("%s nul > %s 2>&1", name, xmake._NULDEV)
    end

    -- attempt to run it directly first
    if not toolpath and os.execute(cmd) ~= 1 then
        toolpath = name
    end

    -- probe ok? update it
    if toolpath then configs.set(kind, toolpath) end

    -- trace
    if toolpath then
        utils.printf("checking for %s (%s) ... %s", description, kind, path.filename(toolpath))
    else
        utils.printf("checking for %s (%s) ... no", description, kind)
    end

    -- failed?
    if not toolpath and (kind == "cc" or kind == "ld" or kind == "make") then
        return false
    end

    -- ok
    return true
end

-- probe the toolchains
function prober._probe_toolchains(configs)

    -- the windows module
    local windows = platform.module()
    assert(windows)

    -- enter envirnoment
    windows.enter()

    -- done
    if not prober._probe_toolpath(configs, "cc", "cl.exe", "the c compiler") then return false end
    if not prober._probe_toolpath(configs, "cxx", "cl.exe", "the c++ compiler") then return false end
    if not prober._probe_toolpath(configs, "as", "ml.exe", "the assember") then return false end
    if not prober._probe_toolpath(configs, "ld", "link.exe", "the linker") then return false end
    if not prober._probe_toolpath(configs, "ar", "link.exe -lib", "the static library linker") then return false end
    if not prober._probe_toolpath(configs, "sh", "link.exe -dll", "the shared library linker") then return false end
    if not prober._probe_toolpath(configs, "ex", "lib.exe", "the library extractor") then return false end
    if not prober._probe_toolpath(configs, "make", "nmake.exe", "the make") then return false end

    -- leave envirnoment
    windows.leave()

    -- ok
    return true
end

-- probe the project configure 
function prober.config()

    -- call all probe functions
    return utils.call(  {   prober._probe_arch
                        ,   prober._probe_vs_version
                        ,   prober._probe_vs_path
                        ,   prober._probe_toolchains}
                    ,   nil
                    ,   config)
end

-- probe the global configure 
function prober.global()

    -- call all probe functions
    return utils.call(  {   prober._probe_vs_version
                        ,   prober._probe_vs_path}
                    ,   nil
                    ,   global)
end

-- return module: prober
return prober
