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
-- @file        find_ifxenv.lua
--

-- imports
import("lib.detect.find_file")
import("lib.detect.find_tool")

-- init ifx variables
local ifxvars = {"path",
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

-- load ifxvars_bat environment variables
function _load_ifxvars(ifxvars_bat, arch, opt)

    -- make the genifxvars.bat
    opt = opt or {}
    local genifxvars_bat = os.tmpfile() .. "_genifxvars.bat"
    local genifxvars_dat = os.tmpfile() .. "_genifxvars.txt"
    local file = io.open(genifxvars_bat, "w")
    file:print("@echo off")
    file:print("call \"%s\" -arch %s > nul", ifxvars_bat, arch)
    for idx, var in ipairs(ifxvars) do
        file:print("echo " .. var .. " = %%" .. var .. "%% %s %s", idx == 1 and ">" or ">>", genifxvars_dat)
    end
    file:close()

    -- run genifxvars.bat
    os.run(genifxvars_bat)

    -- load all envirnoment variables
    local variables = {}
    for _, line in ipairs((io.readfile(genifxvars_dat) or ""):split("\n")) do
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
    for _, name in ipairs(ifxvars) do
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

-- find intel llvm fortran envirnoment on windows
function _find_intel_on_windows(opt)
    opt = opt or {}

    -- find ifxvars_bat.bat
    local paths = {"$(env ONEAPI_ROOT)"}
    local ifxvars_bat = find_file("setvars.bat", paths)
    if not ifxvars_bat then
        paths = {}
        local keys = winos.registry_keys("HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Intel\\Compilers\\Fortran\\**")
        for _, key in ipairs(keys) do
            table.insert(paths, format("$(reg %s;ProductDir)", key))
        end
        ifxvars_bat = find_file("../../setvars.bat", paths)
    end
    if ifxvars_bat then
        local ifxvars_x86 = _load_ifxvars(ifxvars_bat, "ia32", opt)
        local ifxvars_x64 = _load_ifxvars(ifxvars_bat, "intel64", opt)
        return {ifxvars_bat = ifxvars_bat, ifxvars = {x86 = ifxvars_x86, x64 = ifxvars_x64}}
     end
end

-- find intel llvm fortran envirnoment on linux
function _find_intel_on_linux(opt)

    -- attempt to find the sdk directory
    local oneapi_rootdirs = {"~/intel/oneapi/compiler", "/opt/intel/oneapi/compiler"}
    paths = {}
    for _, rootdir in ipairs(oneapi_rootdirs) do
        table.insert(paths, path.join(rootdir, "*", is_host("macosx") and "mac" or "linux", "bin"))
        table.insert(paths, path.join(rootdir, "*", "bin"))
    end
    if #paths > 0 then
        local ifx = find_file("ifx", paths)
        if ifx then
            local bindir = path.directory(ifx)
            local sdkdir = path.directory(path.directory(bindir))
            return {sdkdir = sdkdir, bindir = bindir}
        end
    end
end

-- find intel fortran environment
function main(opt)
    if is_host("windows") then
        return _find_intel_on_windows(opt)
    else
        return _find_intel_on_linux(opt)
    end
end

