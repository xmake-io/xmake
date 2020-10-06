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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_intel.lua
--

-- imports
import("lib.detect.find_file")
import("lib.detect.find_tool")

--[[
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

-- load iclvars environment variables
function _load_iclvars(iclvars, vsver, arch, opt)

    -- make the genvcvars.bat
    opt = opt or {}
    local genvcvars_bat = os.tmpfile() .. "_genvcvars.bat"
    local genvcvars_dat = os.tmpfile() .. "_genvcvars.txt"
    local file = io.open(genvcvars_bat, "w")
    file:print("@echo off")
    -- fix error caused by the new vsDevCmd.bat of vs2019
    -- @see https://github.com/xmake-io/xmake/issues/549
    if vsver and tonumber(vsver) >= 16 then
        file:print("set VSCMD_SKIP_SENDTELEMETRY=yes")
    end
    if opt.vcvars_ver then
        file:print("call \"%s\" %s %s -vcvars_ver=%s > nul", iclvars, arch,  opt.sdkver and opt.sdkver or "", opt.vcvars_ver)
    else
        file:print("call \"%s\" %s %s > nul", iclvars, arch, opt.sdkver and opt.sdkver or "")
    end
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
    -- @note iclvars.bat maybe detect error if install WDK and SDK at same time (multi-sdk version exists in include directory).
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

    -- ok
    return variables
end

-- find intel envirnoment on windows
function _find_intel_on_windows(opt)

    -- init options
    opt = opt or {}

        -- find iclvars.bat, vcvars32.bat for vs7.1
        local iclvars = find_file("iclvars.bat", paths) or find_file("vcvars32.bat", paths)
        if iclvars then

            -- load iclvars
            local iclvars_x86 = _load_iclvars(iclvars, version, "x86", opt)
            local iclvars_x64 = _load_iclvars(iclvars, version, "x64", opt)
]]
            -- save results
  --          results[vsvers[version]] = {version = version, iclvars_bat = iclvars, iclvars = {x86 = iclvars_x86, x64 = iclvars_x64}}
   --     end
--end

-- find intel envirnoment on linux
function _find_intel_on_linux(opt)

    -- attempt to find the sdk directory
    local paths = {"/opt/intel/bin", "/usr/local/bin", "/usr/bin"}
    local icc = find_file("icc", paths)
    if icc then
        local sdkdir = path.directory(path.directory(icc))
        return {sdkdir = sdkdir, bindir = path.directory(icc), path.join(sdkdir, "include"), libdir = path.join(sdkdir, "lib")}
    end
end

-- find intel environment
function main(opt)
    if is_host("windows") then
        return _find_intel_on_windows(opt)
    else
        return _find_intel_on_linux(opt)
    end
end
