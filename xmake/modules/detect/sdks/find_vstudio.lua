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
-- @file        find_vstudio.lua
--

-- imports
import("lib.detect.find_file")

-- load vcvarsall environment variables
function _load_vcvarsall(vcvarsall, arch)

    -- make the genvcvars.bat 
    local genvcvars_bat = os.tmpfile() .. "_genvcvars.bat"
    local genvcvars_dat = os.tmpfile() .. "_genvcvars.dat"
    local file = io.open(genvcvars_bat, "w")
    file:print("@echo off")
    file:print("call \"%s\" %s > nul", vcvarsall, arch)
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
    if not variables then
        return 
    end

    -- remove some empty entries
    for _, name in ipairs({"path", "lib", "libpath", "include", "devenvdir", "vsinstalldir", "vcinstalldir"}) do
        if variables[name] and #variables[name]:trim() == 0 then
            variables[name] = nil
        end
    end

    -- get sdk version
    local include = variables["include"]
    if include then
        variables["sdkver"] = include:match("Windows Kits\\%d+\\include\\(%d+%.%d+%.%d+%.%d+)\\")
    end

    -- ok
    return variables
end

-- find vstudio environment
--
-- @return      { 2008 = {version = "9.0", vcvarsall = {x86 = {path = .., lib = .., include = ..}}}
--              , 2017 = {version = "15.0", vcvarsall = {x64 = {path = .., lib = ..}}}}
--
function main()

    -- init vsvers
    local vsvers = 
    {
        ["15.0"] = "2017"
    ,   ["14.0"] = "2015"
    ,   ["12.0"] = "2013"
    ,   ["11.0"] = "2012"
    ,   ["10.0"] = "2010"
    ,   ["9.0"]  = "2008"
    ,   ["8.0"]  = "2005"
    ,   ["7.1"]  = "2003"
    ,   ["7.0"]  = "7.0"
    ,   ["6.0"]  = "6.0"
    ,   ["5.0"]  = "5.0"
    ,   ["4.2"]  = "4.2"
    }

    -- init vsenvs
    local vsenvs = 
    {
        ["14.0"] = "VS140COMNTOOLS"
    ,   ["12.0"] = "VS120COMNTOOLS"
    ,   ["11.0"] = "VS110COMNTOOLS"
    ,   ["10.0"] = "VS100COMNTOOLS"
    ,   ["9.0"]  = "VS90COMNTOOLS"
    ,   ["8.0"]  = "VS80COMNTOOLS"
    ,   ["7.1"]  = "VS71COMNTOOLS"
    ,   ["7.0"]  = "VS70COMNTOOLS"
    ,   ["6.0"]  = "VS60COMNTOOLS"
    ,   ["5.0"]  = "VS50COMNTOOLS"
    ,   ["4.2"]  = "VS42COMNTOOLS"
    }
    
    -- find vs2017 -> vs4.2
    local results = {}
    for _, version in ipairs({"15.0", "14.0", "12.0", "11.0", "10.0", "9.0", "8.0", "7.1", "7.0", "6.0", "5.0", "4.2"}) do

        -- find vcvarsall.bat
        local vcvarsall = find_file("vcvarsall.bat", {format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC", version),
                                                      format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC", version),
                                                      format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC\\Auxiliary\\Build", version),
                                                      format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC\\Auxiliary\\Build", version),
                                                      format("$(env %s)\\..\\..\\VC", vsenvs[version] or "")})

        -- found?
        if vcvarsall then

            -- load vcvarsall
            local vcvarsall_x86 = _load_vcvarsall(vcvarsall, "x86")
            local vcvarsall_x64 = _load_vcvarsall(vcvarsall, "x64")

            -- save results
            results[vsvers[version]] = {version = version, vcvarsall = {x86 = vcvarsall_x86, x64 = vcvarsall_x64}}
        end
    end

    -- ok?
    return results
end
