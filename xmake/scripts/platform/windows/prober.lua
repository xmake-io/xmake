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
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")
local config    = require("base/config")
local global    = require("base/global")

-- define module: prober
local prober = prober or {}

-- probe the architecture
function prober._probe_arch(configs)

    -- get the architecture
    local arch = configs.get("arch")

    -- ok? 
    if arch then return true end

    -- init the default architecture
    configs.set("arch", xmake._ARCH)

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
        VS120COMNTOOLS  = "2013"
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
        configs.set("vs", vs)
    else
        -- failed
        utils.error("The Microsoft Visual Studio is unknown now, please config it first!")
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
        ["2013"]    = "VS120COMNTOOLS"
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

    -- attempt to get the tools directory from the envirnoment variable
    local toolsdir = map[vs]
    if toolsdir then 
        toolsdir = os.getenv(toolsdir)
    end

    -- the vsvars32.bat path
    local vsvars32 = toolsdir .. "\\vsvars32.bat"
    if not os.isfile(vsvars32) then
        -- error
        utils.error("not found %s", vsvars32)
        return false
    end

    -- get the temporary directory
    local tmpdir = os.tmpdir()
    assert(tmpdir)

    -- make the call(vsvars32.bat) file
    local callpath = tmpdir .. "\\call_vsvars32.bat"
    local callfile = io.open(callpath, "w")
    assert(callfile)

    -- make call scripts
    callfile:write("@echo off\n")
    callfile:write(string.format("call \"%s\" > nul\n", vsvars32))
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

-- probe the project configure 
function prober.config()

    -- call all probe functions
    utils.call(     prober   
                ,   {   "_probe_arch"
                    ,   "_probe_vs_version"
                    ,   "_probe_vs_path"}
                
                ,   function (name, result)
                        -- trace
                        utils.verbose("checking %s ...: %s", name:gsub("_probe_", ""), utils.ifelse(result, "ok", "no"))
                        return result 
                    end

                ,   config)
end

-- probe the global configure 
function prober.global()

    -- call all probe functions
    utils.call(     prober   
                ,   {   "_probe_vs_version"
                    ,   "_probe_vs_path"}
                
                ,   function (name, result)
                        -- trace
                        utils.verbose("checking %s ...: %s", name:gsub("_probe_", ""), utils.ifelse(result, "ok", "no"))
                        return result 
                    end

                ,   global)
end

-- return module: prober
return prober
