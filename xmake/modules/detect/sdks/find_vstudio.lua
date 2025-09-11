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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        find_vstudio.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.project.config")
import("lib.detect.find_file")
import("lib.detect.find_tool")
import("lib.detect.find_directory")
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

function find_build_tools(opt)
    opt = opt or {}

    local sdkdir = opt.sdkdir
    if not sdkdir or not os.isdir(sdkdir) then
        return
    end

    local variables = {}
    local VCInstallDir = path.join(sdkdir, "VC")
    local VCToolsVersion = opt.vs_toolset
    if not VCToolsVersion or not os.isdir(path.join(VCInstallDir, "Tools/MSVC", VCToolsVersion)) then
        -- https://github.com/xmake-io/xmake/issues/6159
        local latest_toolset
        for _, dir in ipairs(os.dirs(path.join(sdkdir, "VC/Tools/MSVC/*"))) do
            local toolset = path.filename(dir)
            if not latest_toolset or semver.compare(toolset, latest_toolset) > 0 then
                latest_toolset = toolset
            end
        end
        if latest_toolset then
            VCToolsVersion = latest_toolset
        else
            return
        end
    end
    variables.VCInstallDir = VCInstallDir
    variables.VCToolsVersion = VCToolsVersion
    variables.VCToolsInstallDir = path.join(VCInstallDir, "Tools/MSVC", VCToolsVersion)

    local WindowsSDKVersion
    local vs_sdkver = opt.vs_sdkver
    if vs_sdkver and os.isdir(path.join(sdkdir, "Windows Kits/10/Lib", vs_sdkver)) then
        WindowsSDKVersion = vs_sdkver
    else
        local dir = find_directory("10*", path.join(sdkdir, "Windows Kits/10/Lib"))
        if dir then
            WindowsSDKVersion = path.filename(dir)
        else
            return
        end
    end
    variables.WindowsSDKVersion = WindowsSDKVersion
    variables.WindowsSdkDir = path.join(sdkdir, "Windows Kits/10")
    variables.WindowsSdkBinPath = path.join(variables.WindowsSdkDir, "bin")
    variables.WindowsSdkVerBinPath = path.join(variables.WindowsSdkBinPath, WindowsSDKVersion)
    variables.ExtensionSdkDir = path.join(variables.WindowsSdkDir, "ExtensionSdkDir")
    variables.UCRTVersion = WindowsSDKVersion
    variables.UniversalCRTSdkDir = variables.WindowsSdkDir

    local includedirs = {
        path.join(variables.VCToolsInstallDir, "include"),
        path.join(variables.VCToolsInstallDir, "atlmfc", "include"),
        path.join(variables.WindowsSdkDir, "Include", WindowsSDKVersion, "ucrt"),
        path.join(variables.WindowsSdkDir, "Include", WindowsSDKVersion, "shared"),
        path.join(variables.WindowsSdkDir, "Include", WindowsSDKVersion, "um"),
        path.join(variables.WindowsSdkDir, "Include", WindowsSDKVersion, "winrt"),
        path.join(variables.WindowsSdkDir, "Include", WindowsSDKVersion, "cppwinrt"),
    }

    local linkdirs = {
        path.join(variables.VCToolsInstallDir, "lib"),
        path.join(variables.VCToolsInstallDir, "atlmfc", "lib"),
        path.join(variables.WindowsSdkDir, "Lib", WindowsSDKVersion, "ucrt"),
        path.join(variables.WindowsSdkDir, "Lib", WindowsSDKVersion, "um"),
        path.join(variables.WindowsSdkDir, "Lib", WindowsSDKVersion, "km"),
    }

    local archs = {
        "x86",
        "x64",
        "arm",
        "arm64",
    }

    local vcvarsall = {}
    for _, target_arch in ipairs(archs) do
        local lib = {}
        for _, lib_dir in ipairs(linkdirs) do
            local dir = path.join(lib_dir, target_arch)
            if os.isdir(dir) then
                table.insert(lib, dir)
            end
        end

        if #lib ~= 0 then
            local vcvars = {
                BUILD_TOOLS_ROOT = sdkdir,
                VSInstallDir = sdkdir,

                -- vs runs in a windows ctx, so the envsep is always ";"
                INCLUDE = path.joinenv(includedirs, ';'),
                LIB = path.joinenv(lib, ';'),

                VSCMD_ARG_HOST_ARCH = "x64",

                VCInstallDir = variables.VCInstallDir,
                VCToolsVersion = variables.VCToolsVersion,
                VCToolsInstallDir = variables.VCToolsInstallDir,

                WindowsSDKVersion = variables.WindowsSDKVersion,
                WindowsSdkDir = variables.WindowsSdkDir,
                WindowsSdkBinPath = variables.WindowsSdkBinPath,
                WindowsSdkVerBinPath = variables.WindowsSdkVerBinPath,
                ExtensionSdkDir = variables.ExtensionSdkDir,
                UCRTVersion = variables.UCRTVersion,
                UniversalCRTSdkDir = variables.UniversalCRTSdkDir,
            }

            local build_tools_bin = {}
            local host_dir = "Host" .. vcvars.VSCMD_ARG_HOST_ARCH
            if is_host("windows") then
                table.insert(build_tools_bin, path.join(vcvars.VCToolsInstallDir, "bin", host_dir, target_arch))
                table.insert(build_tools_bin, path.join(vcvars.WindowsSdkDir, "bin", WindowsSDKVersion))
                table.insert(build_tools_bin, path.join(vcvars.WindowsSdkDir, "bin", WindowsSDKVersion, "ucrt"))
            elseif is_host("linux") then
                -- for msvc-wine
                table.insert(build_tools_bin, path.join(sdkdir, "bin", target_arch))
            end

            vcvars.VSCMD_ARG_TGT_ARCH = target_arch
            vcvars.BUILD_TOOLS_BIN = path.joinenv(build_tools_bin)

            local PATH = build_tools_bin
            table.join2(PATH, path.splitenv(os.getenv("PATH")))
            vcvars.PATH = path.joinenv(PATH)

            vcvarsall[target_arch] = vcvars
        end
    end

    return vcvarsall
end

-- load vcvarsall environment variables
function _load_vcvarsall_impl(vcvarsall, vsver, arch, opt)
    opt = opt or {}

    -- is VsDevCmd.bat?
    local is_vsdevcmd = path.basename(vcvarsall):lower() == "vsdevcmd"

    -- make the genvcvars.bat
    local genvcvars_bat = os.tmpfile() .. "_genvcvars.bat"
    local file = io.open(genvcvars_bat, "w")
    file:print("@echo off")
    -- @note we need to get utf8 output from cmd.exe
    -- because some %PATH% and other envs maybe contains unicode characters
	if winos.version():gt("winxp") then
    	file:print("chcp 65001")
	end
    -- fix error caused by the new vsDevCmd.bat of vs2019
    -- @see https://github.com/xmake-io/xmake/issues/549
    if vsver and tonumber(vsver) >= 16 then
        file:print("set VSCMD_SKIP_SENDTELEMETRY=yes")
    end
    local host_arch = os.arch()
    if is_vsdevcmd then
        if vsver and tonumber(vsver) >= 16 then
            if opt.toolset then
                file:print("call \"%s\" -host_arch=%s -arch=%s -winsdk=%s -vcvars_ver=%s > nul", vcvarsall, host_arch, arch, opt.sdkver or "", opt.toolset or "")
            else
                file:print("call \"%s\" -host_arch=%s -arch=%s -winsdk=%s > nul", vcvarsall, host_arch, arch, opt.sdkver or "")
            end
        else
            if opt.toolset then
                file:print("call \"%s\" -arch=%s -winsdk=%s -vcvars_ver=%s > nul", vcvarsall, arch, opt.sdkver or "", opt.toolset or "")
            else
                file:print("call \"%s\" -arch=%s -winsdk=%s > nul", vcvarsall, arch, opt.sdkver or "")
            end
        end
    else
        -- @see https://github.com/xmake-io/xmake/issues/5077
        if vsver and tonumber(vsver) >= 16 and host_arch ~= arch then
            if host_arch == "x64" then
                host_arch = "amd64"
            end
            arch = host_arch .. "_" .. arch
        end
        if opt.toolset then
            file:print("call \"%s\" %s %s -vcvars_ver=%s > nul", vcvarsall, arch, opt.sdkver or "", opt.toolset or "")
        else
            file:print("call \"%s\" %s %s > nul", vcvarsall, arch, opt.sdkver or "")
        end
    end
    for idx, var in ipairs(get_vcvars()) do
        file:print("echo " .. var .. " = %%" .. var .. "%%")
    end
    file:close()

    -- run genvcvars.bat
    local outdata, errdata = try {function () return os.iorun(genvcvars_bat) end}
    if errdata and #errdata > 0 and option.get("verbose") and option.get("diagnosis") then
        cprint("${color.warning}checkinfo: ${clear dim}get vcvars error: %s", errdata)
    end
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
    else
        -- sometimes the variable `WindowsSDKVersion` is not available
        -- then parse it from `WindowsSdkBinPath`, such as: `C:\\Program Files (x86)\\Windows Kits\\8.1\\bin`
        local WindowsSdkBinPath = variables["WindowsSdkBinPath"]
        if WindowsSdkBinPath then
            WindowsSDKVersion = string.match(WindowsSdkBinPath, "\\(%d+%.%d+)\\bin$")
            if WindowsSDKVersion then
                variables["WindowsSDKVersion"] = WindowsSDKVersion
            end
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

-- strip toolset version, e.g. 14.16.27023 -> 14.16
function _strip_toolset_ver(vs_toolset)
    local version = semver.new(vs_toolset)
    if version then
        return version:major() .. "." .. version:minor()
    end
    return vs_toolset
end

function _load_vcvarsall(vcvarsall, vsver, arch, opt)
    opt = opt or {}
    local vs_toolset = opt.toolset or opt.vcvars_ver
    if vs_toolset then
        opt.toolset = _strip_toolset_ver(vs_toolset)
    end
    local result = _load_vcvarsall_impl(vcvarsall, vsver, arch, opt)
    if result and not vs_toolset then
        -- if no vs toolset version is specified, we default to the latest version.
        -- https://github.com/xmake-io/xmake/issues/6159
        local latest_toolset
        local VCToolsVersion = result.VCToolsVersion
        local VCInstallDir = result.VCInstallDir
        if VCToolsVersion and VCInstallDir then
            for _, dir in ipairs(os.dirs(path.join(VCInstallDir, "Tools/MSVC/*"))) do
                local toolset = path.filename(dir)
                if not latest_toolset or semver.compare(toolset, latest_toolset) > 0 then
                    latest_toolset = toolset
                end
            end
        end
        if latest_toolset and VCToolsVersion and semver.compare(latest_toolset, VCToolsVersion) > 0 then
            opt.toolset = _strip_toolset_ver(latest_toolset)
            result = _load_vcvarsall_impl(vcvarsall, vsver, arch, opt)
        end
    end
    return result
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
            local vcvarsall_x86     = _load_vcvarsall(vcvarsall, VisualStudioVersion, "x86", opt)
            local vcvarsall_x64     = _load_vcvarsall(vcvarsall, VisualStudioVersion, "x64", opt)
            local vcvarsall_arm     = _load_vcvarsall(vcvarsall, VisualStudioVersion, "arm", opt)
            local vcvarsall_arm64   = _load_vcvarsall(vcvarsall, VisualStudioVersion, "arm64", opt)
            local vcvarsall_arm64ec = vcvarsall_arm64

            -- save results
            local results = {}
            results[vsvers[VisualStudioVersion]] = {
                version = VisualStudioVersion,
                vcvarsall_bat = vcvarsall,
                vcvarsall = {
                    x86 = vcvarsall_x86,
                    x64 = vcvarsall_x64,
                    arm = vcvarsall_arm,
                    arm64 = vcvarsall_arm64,
                    arm64ec = vcvarsall_arm64ec
                }
            }
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
        local vswhere_VCAuxiliaryBuildDir = {}
        local vswhere_Common7ToolsDir = {}
        if (tonumber(version) >= 15) and vswhere then
            local vswhere_vrange = format("%s,%s)", version, (version + 1))
            -- build tools: https://github.com/microsoft/vswhere/issues/22 @@ https://aka.ms/vs/workloads
            local result = os.iorunv(vswhere.program, {"-products", "*", "-prerelease", "-property", "installationpath", "-version", vswhere_vrange})
            if result then
                for _, vc_path in ipairs(result:split("\n")) do
                    table.insert(vswhere_VCAuxiliaryBuildDir, path.join(vc_path:trim(), "VC", "Auxiliary", "Build"))
                    table.insert(vswhere_Common7ToolsDir, path.join(vc_path:trim(), "Common7", "Tools"))
                end
            end
        end

        -- init paths
        local paths = {
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC", version),
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC7\\bin", version),
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC", version),
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC\\Auxiliary\\Build", version),
            format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\VC\\Auxiliary\\Build", version)
        }
        if vsenvs[version] then
            table.insert(paths, format("$(env %s)\\..\\..\\VC", vsenvs[version]))
        end
        
        if vswhere_VCAuxiliaryBuildDir then
            for _, vc_path in ipairs(vswhere_VCAuxiliaryBuildDir) do
                if os.isdir(vc_path) then
                    table.insert(paths, 1, vc_path)
                end
            end
        end
        if version == "6.0" and os.arch() == "x64" then
            table.insert(paths, "$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\DevStudio\\6.0\\Products\\Microsoft Visual C++;ProductDir)\\Bin")
            table.insert(paths, "$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\VisualStudio\\6.0\\Setup\\Microsoft Visual C++;ProductDir)\\Bin")
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
                if version == "6.0" then
                    table.insert(paths, path.join(logical_drive, "Program Files", "Microsoft Visual Studio", "VC98", "Bin"))
                    table.insert(paths, path.join(logical_drive, "Program Files (x86)", "Microsoft Visual Studio", "VC98", "Bin"))
                end
            end
            vcvarsall = find_file("vcvarsall.bat", paths) or find_file("vcvars32.bat", paths)
        end
        if not vcvarsall then
            local paths = {
                format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\Common7\\Tools", version),
                format("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VS7;%s)\\Common7\\Tools", version)
            }
            if vswhere_Common7ToolsDir then
                for _, vc_path in ipairs(vswhere_Common7ToolsDir) do
                    if os.isdir(vc_path) then
                        table.insert(paths, 1, vc_path)
                    end
                end
            end
            vcvarsall = find_file("VsDevCmd.bat", paths)
        end
        if vcvarsall then

            -- load vcvarsall
            local vcvarsall_x86     = _load_vcvarsall(vcvarsall, version, "x86", opt)
            local vcvarsall_x64     = _load_vcvarsall(vcvarsall, version, "x64", opt)
            local vcvarsall_arm     = _load_vcvarsall(vcvarsall, version, "arm", opt)
            local vcvarsall_arm64   = _load_vcvarsall(vcvarsall, version, "arm64", opt)
            local vcvarsall_arm64ec = vcvarsall_arm64

            -- save results
            results[vsvers[version]] = {
                version = version,
                vcvarsall_bat = vcvarsall,
                vcvarsall = {
                    x86 = vcvarsall_x86,
                    x64 = vcvarsall_x64,
                    arm = vcvarsall_arm,
                    arm64 = vcvarsall_arm64,
                    arm64ec = vcvarsall_arm64ec
                }
            }
        end
    end
    return results
end

-- get last mtime of msvc
-- @see https://github.com/xmake-io/xmake/issues/3652
function _get_last_mtime_of_msvc(msvc)
    local mtime = -1
    for arch, envs in pairs(msvc.vcvarsall) do
        if envs.PATH then
            local pathenv = path.splitenv(envs.PATH)
            for _, dir in ipairs(pathenv) do
                local cl = path.join(dir, "cl.exe")
                if os.isfile(cl) then
                    local t = os.mtime(cl)
                    if t > mtime then
                        mtime = t
                    end
                end
            end
        end
        local winsdk = envs.WindowsSdkDir
        if winsdk and os.isdir(winsdk) then
            local t = os.mtime(winsdk)
            if t > mtime then
                mtime = t
            end
        end
    end
    return mtime
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
            t = _get_last_mtime_of_msvc(msvc)
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
-- @param opt   the options, e.g. {toolset = 14.0, sdkver = "10.0.15063.0"}
--
-- @return      { 2008 = {version = "9.0", vcvarsall = {x86 = {path = .., lib = .., include = ..}}}
--              , 2017 = {version = "15.0", vcvarsall = {x64 = {path = .., lib = ..}}}}
--
function main(opt)
    opt = opt or {}

    -- only for windows
    if not is_host("windows") then
        return
    end

    local key = "vstudio"
    if opt.toolset then
        key = key .. opt.toolset
    end
    if opt.sdkver then
        key = key .. opt.sdkver
    end

    -- attempt to get it from the global cache first
    local vstudio = global_detectcache:get2(key, "msvc")
    if vstudio then
        local mtime = _get_last_mtime(vstudio)
        local mtimeprev = global_detectcache:get2(key, "mtime")
        if mtime and mtimeprev and mtime > 0 and mtimeprev > 0 and mtime == mtimeprev then
            return vstudio
        end
    end

    -- find and cache result
    vstudio = _find_vstudio(opt)
    if vstudio then
        local mtime = _get_last_mtime(vstudio)
        global_detectcache:set2(key, "msvc", vstudio)
        global_detectcache:set2(key, "mtime", mtime)
        global_detectcache:save()
    end
    return vstudio
end

