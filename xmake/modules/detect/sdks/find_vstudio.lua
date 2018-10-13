--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_vstudio.lua
--

-- imports
import("lib.detect.find_file")
import("detect.tools.find_vswhere")

-- init vc variables
local vcvars = {"path", 
                "lib", 
                "libpath", 
                "include", 
                "DevEnvdir", 
                "VSInstallDir", 
                "VCInstallDir", 
                "WindowsSdkDir", 
                "WindowsLibPath", 
                "WindowsSDKVersion", 
                "WindowsSdkBinPath",
                "UniversalCRTSdkDir",
                "UCRTVersion"}

-- load vcvarsall environment variables
function _load_vcvarsall(vcvarsall, arch)

    -- make the genvcvars.bat 
    local genvcvars_bat = os.tmpfile() .. "_genvcvars.bat"
    local genvcvars_dat = os.tmpfile() .. "_genvcvars.txt"
    local file = io.open(genvcvars_bat, "w")
    file:print("@echo off")
    file:print("call \"%s\" %s > nul", vcvarsall, arch)
    for idx, var in ipairs(vcvars) do
        file:print("echo " .. var .. " = %%" .. var .. "%% %s %s", idx == 1 and ">" or ">>", genvcvars_dat)
    end
    file:close()

    -- run genvcvars.bat
    os.run(genvcvars_bat)

    -- load all envirnoment variables
    local variables = {}
    for _, line in ipairs((io.readfile(genvcvars_dat) or ""):split("\n")) do
        local p = line:find('=', 1, true)
        if p then
            local name = line:sub(1, p - 1):trim()
            local value = line:sub(p + 1):trim()
            variables[name] = value
        end
    end
    if not variables.path then
        return 
    end

    -- remove some empty entries
    for _, name in ipairs(vcvars) do
        if variables[name] and #variables[name]:trim() == 0 then
            variables[name] = nil
        end
    end

    -- fix WindowsSDKVersion
    local WindowsSDKVersion = variables["WindowsSDKVersion"]
    if WindowsSDKVersion then
        WindowsSDKVersion = WindowsSDKVersion:gsub("\\", ""):trim()
        if WindowsSDKVersion ~= "" then
            variables["WindowsSDKVersion"] = WindowsSDKVersion
        end
    end

    -- fix UCRTVersion 
    --
    -- @note vcvarsall.bat maybe detect error if install WDK and SDK at same time (multi-sdk version exists in include directory).
    --
    local UCRTVersion = variables["UCRTVersion"]
    if UCRTVersion and UCRTVersion ~= WindowsSDKVersion and WindowsSDKVersion ~= "" then
        local lib = variables["lib"]
        if lib then
            lib = lib:gsub(UCRTVersion, WindowsSDKVersion)
            variables["lib"] = lib
        end
        local include = variables["include"]
        if include then
            include = include:gsub(UCRTVersion, WindowsSDKVersion)
            variables["include"] = include
        end
        UCRTVersion = WindowsSDKVersion
        variables["UCRTVersion"] = UCRTVersion
    end

    -- fix rc.exe missing issues
    --
    -- @see https://github.com/tboox/xmake/issues/225
    -- https://stackoverflow.com/questions/43847542/rc-exe-no-longer-found-in-vs-2015-command-prompt/45319119
    --
    -- patch sdk bin directory to path environment
    --
    -- .e.g C:\Program Files (x86)\Windows Kits\10\bin\10.0.17134.0\x64
    --
    local WindowsSdkDir = variables["WindowsSdkDir"]
    if WindowsSdkDir and WindowsSDKVersion then
        local pathes = variables["path"]
        local bindir = path.join(WindowsSdkDir, "bin", WindowsSDKVersion, arch)
        if os.isdir(bindir) and pathes then
            variables["path"] = pathes .. ';' .. bindir
        end
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

    -- find vs from environment variables 
    local VCInstallDir = os.getenv("VCInstallDir")
    local VisualStudioVersion = os.getenv("VisualStudioVersion")
    if VCInstallDir and VisualStudioVersion then

        -- find vcvarsall.bat
        local vcvarsall = path.join(VCInstallDir, "Auxiliary", "Build", "vcvarsall.bat")
        if os.isfile(vcvarsall) then

            -- load vcvarsall
            local vcvarsall_x86 = _load_vcvarsall(vcvarsall, "x86")
            local vcvarsall_x64 = _load_vcvarsall(vcvarsall, "x64")

            -- save results
            local results = {}
            results[vsvers[VisualStudioVersion]] = {version = VisualStudioVersion, vcvarsall_bat = vcvarsall, vcvarsall = {x86 = vcvarsall_x86, x64 = vcvarsall_x64}}
            return results 
        end
    end
    
    -- find vs2017 -> vs4.2
    local results = {}
    for _, version in ipairs({"15.0", "14.0", "12.0", "11.0", "10.0", "9.0", "8.0", "7.1", "7.0", "6.0", "5.0", "4.2"}) do

        -- find VC install path (and aux build path) using `vswhere` (for version >= 15.0)
        -- * version > 15.0 eschews registry entries; but `vswhere` (included with version >= 15.2) can be used to find VC install path
        -- ref: https://github.com/Microsoft/vswhere/blob/master/README.md @@ https://archive.is/mEmdu
        local vswhere_VCAuxiliaryBuildDir = nil
        if ((version+0) >= 15) then
            local vswhere = find_vswhere()
            if vswhere then
                local vswhere_vrange = format("%s,%s)", version, (version+1))
                local out, err = os.iorunv(vswhere, {"-property", "installationpath", "-products", "Microsoft.VisualStudio.Product.BuildTools", "-version", vswhere_vrange})
                if out then vswhere_VCAuxiliaryBuildDir = out:trim().."\\VC\\Auxiliary\\Build" end
            end
        end

        -- init pathes
        local pathes = 
        {
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC", version),
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC7\\bin", version),
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC", version),
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC\\Auxiliary\\Build", version),
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC\\Auxiliary\\Build", version),
            format("$(env %s)\\..\\..\\VC", vsenvs[version] or ""),
            (vswhere_VCAuxiliaryBuildDir or "")
        }

        -- find vcvarsall.bat, vcvars32.bat for vs7.1
        local vcvarsall = find_file("vcvarsall.bat", pathes) or find_file("vcvars32.bat", pathes)
        if vcvarsall then

            -- load vcvarsall
            local vcvarsall_x86 = _load_vcvarsall(vcvarsall, "x86")
            local vcvarsall_x64 = _load_vcvarsall(vcvarsall, "x64")

            -- save results
            results[vsvers[version]] = {version = version, vcvarsall_bat = vcvarsall, vcvarsall = {x86 = vcvarsall_x86, x64 = vcvarsall_x64}}
        end
    end

    -- ok?
    return results
end
