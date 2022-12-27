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
-- @file        find_iccenv.lua
--

-- imports
import("lib.detect.find_file")
import("lib.detect.find_tool")

-- init icl variables
local iclvars = {"path",
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

-- load iclvars_bat environment variables
function _load_iclvars(iclvars_bat, arch, opt)

    -- make the geniclvars.bat
    opt = opt or {}
    local geniclvars_bat = os.tmpfile() .. "_geniclvars.bat"
    local geniclvars_dat = os.tmpfile() .. "_geniclvars.txt"
    local file = io.open(geniclvars_bat, "w")
    file:print("@echo off")
    file:print("call \"%s\" -arch %s > nul", iclvars_bat, arch)
    for idx, var in ipairs(iclvars) do
        file:print("echo " .. var .. " = %%" .. var .. "%% %s %s", idx == 1 and ">" or ">>", geniclvars_dat)
    end
    file:close()

    -- run geniclvars.bat
    os.run(geniclvars_bat)

    -- load all envirnoment variables
    local variables = {}
    for _, line in ipairs((io.readfile(geniclvars_dat) or ""):split("\n")) do
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
    for _, name in ipairs(iclvars) do
        if variables[name] and #variables[name]:trim() == 0 then
            variables[name] = nil
        end
    end

    -- fix bin path for ia32
    if variables.path and arch == "ia32" then
        variables.path = variables.path:gsub("windows\\bin\\intel64;", "windows\\bin\\intel64_ia32;")
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

-- find intel c/c++ envirnoment on windows
function _find_intel_on_windows(opt)

    -- init options
    opt = opt or {}

    -- find iclvars_bat.bat
    local paths = {"$(env ICPP_COMPILER20)"}
    local iclvars_bat = find_file("bin/iclvars.bat", paths)
    -- look for setvars.bat which is new in 2021
    if not iclvars_bat then
        -- find setvars.bat in intel oneapi toolkits rootdir
        paths = {"$(env ONEAPI_ROOT)"}
        iclvars_bat = find_file("setvars.bat", paths)
    end
    if not iclvars_bat then
        -- find setvars.bat using ICPP_COMPILER.*
        paths = {
            "$(env ICPP_COMPILER21)",
            "$(env ICPP_COMPILER22)",
            "$(env ICPP_COMPILER23)"
        }
        iclvars_bat = find_file("../../../setvars.bat", paths)
    end
    if iclvars_bat then

        -- load iclvars_bat
        local iclvars_x86 = _load_iclvars(iclvars_bat, "ia32", opt)
        local iclvars_x64 = _load_iclvars(iclvars_bat, "intel64", opt)

        -- save results
        return {iclvars_bat = iclvars_bat, iclvars = {x86 = iclvars_x86, x64 = iclvars_x64}}
     end
end

-- find intel c/c++ envirnoment on linux
function _find_intel_on_linux(opt)

    -- attempt to find the sdk directory
    local paths = {"/opt/intel/bin", "/usr/local/bin", "/usr/bin"}
    local icc = find_file("icc", paths)
    if icc then
        local sdkdir = path.directory(path.directory(icc))
        return {sdkdir = sdkdir, bindir = path.directory(icc), path.join(sdkdir, "include"), libdir = path.join(sdkdir, "lib")}
    end

    -- find it from oneapi sdk directory
    local oneapi_rootdirs = {"~/intel/oneapi/compiler", "/opt/intel/oneapi/compiler"}
    local arch = os.arch() == "x86_64" and "intel64" or "ia32"
    paths = {}
    for _, rootdir in ipairs(oneapi_rootdirs) do
        table.insert(paths, path.join(rootdir, "*", is_host("macosx") and "mac" or "linux", "bin", arch))
    end
    if #paths > 0 then
        local icc = find_file("icc", paths)
        if icc then
            local bindir = path.directory(icc)
            local sdkdir = path.directory(path.directory(bindir))
            return {sdkdir = sdkdir, bindir = bindir, libdir = path.join(sdkdir, "compiler", "lib", arch)}
        end
    end
end

-- find intel c/c++ environment
function main(opt)
    if is_host("windows") then
        return _find_intel_on_windows(opt)
    else
        return _find_intel_on_linux(opt)
    end
end
