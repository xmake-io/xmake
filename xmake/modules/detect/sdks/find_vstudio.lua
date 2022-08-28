--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_vstudio.lua
--

-- imports
import("core.project.config")
import("lib.detect.find_file")
import("lib.detect.find_tool")
import("core.cache.global_detectcache")

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
                "WindowsSdkVerBinPath",
                "ExtensionSdkDir",
                "UniversalCRTSdkDir",
                "UCRTVersion",
                "VCToolsVersion",
                "VCIDEInstallDir",
                "VCToolsInstallDir",
                "VCToolsRedistDir",
                "VisualStudioVersion",
                "VSCMD_VER",
                "VSCMD_ARG_app_plat",
                "VSCMD_ARG_HOST_ARCH",
                "VSCMD_ARG_TGT_ARCH"}

-- init vsvers
local vsvers =
{
    ["17.0"] = "2022"
,   ["16.0"] = "2019"
,   ["15.0"] = "2017"
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
    ["17.0"] = "VS170COMNTOOLS"
,   ["16.0"] = "VS160COMNTOOLS"
,   ["15.0"] = "VS150COMNTOOLS"
,   ["14.0"] = "VS140COMNTOOLS"
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

-- get all known Visual Studio environment variables
function get_vcvars()
    local realvcvars = vcvars
    for _, v in pairs(vsenvs) do
        table.insert(realvcvars, v)
    end
    return realvcvars
end

-- load vcvarsall environment variables
function _load_vcvarsall(vcvarsall, vsver, arch, opt)

    -- make the genvcvars.bat
    opt = opt or {}
    local genvcvars_bat = os.tmpfile() .. "_genvcvars.bat"
    local file = io.open(genvcvars_bat, "w")
    file:print("@echo off")
    -- @note we need get utf8 output from cmd.exe
    -- because some %PATH% and other envs maybe contains unicode characters
	if winos.version():gt("winxp") then
    	file:print("chcp 65001")
	end
    -- fix error caused by the new vsDevCmd.bat of vs2019
    -- @see https://github.com/xmake-io/xmake/issues/549
    if vsver and tonumber(vsver) >= 16 then
        file:print("set VSCMD_SKIP_SENDTELEMETRY=yes")
    end
    if opt.vcvars_ver then
        file:print("call \"%s\" %s %s -vcvars_ver=%s > nul", vcvarsall, arch, opt.sdkver and opt.sdkver or "", opt.vcvars_ver)
    else
        file:print("call \"%s\" %s %s > nul", vcvarsall, arch, opt.sdkver and opt.sdkver or "")
    end
    for idx, var in ipairs(get_vcvars()) do
        file:print("echo " .. var .. " = %%" .. var .. "%%")
    end
    file:close()

    -- run genvcvars.bat
    local outdata = try {function () return os.iorun(genvcvars_bat) end}
    if not outdata then
        return
    end

    -- load all envirnoment variables
    local variables = {}
    for _, line in ipairs(outdata:split("\n")) do
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
    if UCRTVersion and WindowsSDKVersion and UCRTVersion ~= WindowsSDKVersion and WindowsSDKVersion ~= "" then
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

    -- convert path/lib/include to PATH/LIB/INCLUDE
    variables.PATH    = variables.path
    variables.LIB     = variables.lib
    variables.LIBPATH = variables.libpath
    variables.INCLUDE = variables.include
    variables.path    = nil
    variables.lib     = nil
    variables.include = nil
    variables.libpath = nil
    return variables
end

-- find vstudio for msvc
function _find_vstudio(opt)
    opt = opt or {}

    -- find the single current MSVC/VS from environment variables
    local VCInstallDir = os.getenv("VCInstallDir")
    if VCInstallDir and (VCInstallDir ~= "") then
        local VisualStudioVersion = os.getenv("VisualStudioVersion")
        if not VisualStudioVersion or (VisualStudioVersion == "") then

            -- heuristic for VisualStudioVersion value (early MSVC/VS versions don't set VisualStudioVersion)
            local VSInstallDir = os.getenv("VSInstallDir") or ""
            VisualStudioVersion = VSInstallDir:match('(%d+[.]?%d*)\\?%s*$')
            if not VisualStudioVersion then VisualStudioVersion = VCInstallDir:match('(%d+[.]?%d*)\\VC\\?%s*$') end
            if not VisualStudioVersion then VisualStudioVersion = "0" end
            if not VisualStudioVersion:match('[.]') then VisualStudioVersion = VisualStudioVersion .. '.0' end

            -- find highest known version which is less than or equal to VisualStudioVersion
            if not vsvers[VisualStudioVersion] then
                local versions = {}
                local count = 0
                for k in pairs(vsvers) do
                    table.insert(versions, tonumber(k))
                    count = count + 1
                end
                table.sort(versions)
                local i = 0
                local v = tonumber(VisualStudioVersion)
                while ((i < count) and (versions[i + 1] <= v)) do
                    i = i + 1
                end
                VisualStudioVersion = versions[i] or "0"
            end
        end

        -- find vcvarsall.bat or vcvars32.bat
        local paths =
        {
            path.join(VCInstallDir, "Auxiliary", "Build"),
            path.join(VCInstallDir, "bin"),
            VCInstallDir
        }
        local vcvarsall = find_file("vcvarsall.bat", paths) or find_file("vcvars32.bat", paths)
        if vcvarsall and os.isfile(vcvarsall) and vsvers[VisualStudioVersion] then

            -- load vcvarsall
            local vcvarsall_x86 = _load_vcvarsall(vcvarsall, VisualStudioVersion, "x86", opt)
            local vcvarsall_x64 = _load_vcvarsall(vcvarsall, VisualStudioVersion, "x64", opt)

            -- save results
            local results = {}
            results[vsvers[VisualStudioVersion]] = {version = VisualStudioVersion, vcvarsall_bat = vcvarsall, vcvarsall = {x86 = vcvarsall_x86, x64 = vcvarsall_x64}}
            return results
        end
    end

    -- find vswhere
    local vswhere = find_tool("vswhere")

    -- sort vs versions
    local order_vsvers = table.keys(vsvers)
    table.sort(order_vsvers, function (a, b) return tonumber(a) > tonumber(b) end)

    -- find vs2017 -> vs4.2
    local results = {}
    for _, version in ipairs(order_vsvers) do

        -- find VC install path (and aux build path) using `vswhere` (for version >= 15.0)
        -- * version > 15.0 eschews registry entries; but `vswhere` (included with version >= 15.2) can be used to find VC install path
        -- ref: https://github.com/Microsoft/vswhere/blob/master/README.md @@ https://archive.is/mEmdu
        local vswhere_VCAuxiliaryBuildDir = nil
        if (tonumber(version) >= 15) and vswhere then
            local vswhere_vrange = format("%s,%s)", version, (version + 1))
            -- build tools: https://github.com/microsoft/vswhere/issues/22 @@ https://aka.ms/vs/workloads
            local result = os.iorunv(vswhere.program, {"-products", "*", "-prerelease", "-property", "installationpath", "-version", vswhere_vrange})
            if result then
                vswhere_VCAuxiliaryBuildDir = path.join(result:trim(), "VC", "Auxiliary", "Build")
            end
        end

        -- init paths
        local paths =
        {
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC", version),
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC7\\bin", version),
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC", version),
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC\\Auxiliary\\Build", version),
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC\\Auxiliary\\Build", version)
        }
        if vsenvs[version] then
            table.insert(paths, format("$(env %s)\\..\\..\\VC", vsenvs[version]))
        end
        if vswhere_VCAuxiliaryBuildDir and os.isdir(vswhere_VCAuxiliaryBuildDir) then
            table.insert(paths, vswhere_VCAuxiliaryBuildDir)
        end

        -- find vcvarsall.bat, vcvars32.bat for vs7.1
        local vcvarsall = find_file("vcvarsall.bat", paths) or find_file("vcvars32.bat", paths)
        if not vcvarsall then
            -- find vs from some logical drives paths
            paths = {}
            local logical_drives = winos.logical_drives()
            -- we attempt to find vs from wdk directory
            -- wdk: E:\Program Files\Windows Kits\10
            -- vcvarsall: E:\Program Files\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build
            local wdk = config.get("wdk")
            if wdk and os.isdir(wdk) then
                local p = wdk:find("Program Files")
                if p then
                    table.insert(logical_drives, wdk:sub(1, p - 1))
                end
            end
            for _, logical_drive in ipairs(logical_drives) do
                if os.isdir(path.join(logical_drive, "Program Files (x86)")) then
                    table.insert(paths, path.join(logical_drive, "Program Files (x86)", "Microsoft Visual Studio", vsvers[version], "*", "VC", "Auxiliary", "Build"))
                    table.insert(paths, path.join(logical_drive, "Program Files (x86)", "Microsoft Visual Studio " .. version, "VC"))
                end
                table.insert(paths, path.join(logical_drive, "Program Files", "Microsoft Visual Studio", vsvers[version], "*", "VC", "Auxiliary", "Build"))
                table.insert(paths, path.join(logical_drive, "Program Files", "Microsoft Visual Studio " .. version, "VC"))
            end
            vcvarsall = find_file("vcvarsall.bat", paths) or find_file("vcvars32.bat", paths)
        end
        if vcvarsall then

            -- load vcvarsall
            local vcvarsall_x86 = _load_vcvarsall(vcvarsall, version, "x86", opt)
            local vcvarsall_x64 = _load_vcvarsall(vcvarsall, version, "x64", opt)

            -- load vcvarsall for arm64
            local arch
            local arch_os = os.arch()
            if arch_os == "x64" then
                arch = "x64_arm64"
            elseif arch_os == "x86" then
                arch = "x86_arm64"
            elseif arch_os == "arm64" then
                arch = "arm64"
            end
            local vcvarsall_arm64 = arch and _load_vcvarsall(vcvarsall, version, arch, opt) or nil

            -- save results
            results[vsvers[version]] = {version = version, vcvarsall_bat = vcvarsall, vcvarsall = {x86 = vcvarsall_x86, x64 = vcvarsall_x64, arm64 = vcvarsall_arm64}}
        end
    end
    return results
end

-- get last mtime of vstudio
function _get_last_mtime(vstudio)
    local mtime = -1
    for _, msvc in pairs(vstudio) do
        local vcvarsall_bat = msvc.vcvarsall_bat
        if vcvarsall_bat and os.isfile(vcvarsall_bat) then
            local t = os.mtime(vcvarsall_bat)
            if t > mtime then
                mtime = t
            end
        else
            mtime = -1
            break
        end
    end
    return mtime
end

-- find vstudio environment
--
-- @param opt   the options, e.g. {vcvars_ver = 14.0, sdkver = "10.0.15063.0"}
--
-- @return      { 2008 = {version = "9.0", vcvarsall = {x86 = {path = .., lib = .., include = ..}}}
--              , 2017 = {version = "15.0", vcvarsall = {x64 = {path = .., lib = ..}}}}
--
function main(opt)

    -- only for windows
    if not is_host("windows") then
        return
    end

    -- attempt to get it from the global cache first
    local vstudio = global_detectcache:get2("vstudio", "msvc")
    if vstudio then
        local mtime = _get_last_mtime(vstudio)
        local mtimeprev = global_detectcache:get2("vstudio", "mtime")
        if mtime and mtimeprev and mtime > 0 and mtimeprev > 0 and mtime == mtimeprev then
            return vstudio
        end
    end

    -- find and cache result
    vstudio = _find_vstudio(opt)
    if vstudio then
        local mtime = _get_last_mtime(vstudio)
        global_detectcache:set2("vstudio", "msvc", vstudio)
        global_detectcache:set2("vstudio", "mtime", mtime)
        global_detectcache:save()
    end
    return vstudio
end
