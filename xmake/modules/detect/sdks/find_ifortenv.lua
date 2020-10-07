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
-- @file        find_ifortenv.lua
--

-- imports
import("lib.detect.find_file")
import("lib.detect.find_tool")

-- init ifort variables
local ifortvars = {"path",
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

-- load ifortvars_bat environment variables
function _load_ifortvars(ifortvars_bat, arch, opt)

    -- make the genifortvars.bat
    opt = opt or {}
    local genifortvars_bat = os.tmpfile() .. "_genifortvars.bat"
    local genifortvars_dat = os.tmpfile() .. "_genifortvars.txt"
    local file = io.open(genifortvars_bat, "w")
    file:print("@echo off")
    file:print("call \"%s\" -arch %s > nul", ifortvars_bat, arch)
    for idx, var in ipairs(ifortvars) do
        file:print("echo " .. var .. " = %%" .. var .. "%% %s %s", idx == 1 and ">" or ">>", genifortvars_dat)
    end
    file:close()

    -- run genifortvars.bat
    os.run(genifortvars_bat)

    -- load all envirnoment variables
    local variables = {}
    for _, line in ipairs((io.readfile(genifortvars_dat) or ""):split("\n")) do
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
    for _, name in ipairs(ifortvars) do
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

-- find intel fortran envirnoment on windows
function _find_intel_on_windows(opt)

    -- init options
    opt = opt or {}

    -- find ifortvars_bat.bat
    local paths = {"$(env IFORT_COMPILER20)"}
    local ifortvars_bat = find_file("bin/ifortvars.bat", paths)
    if ifortvars_bat then

        -- load ifortvars_bat
        local ifortvars_x86 = _load_ifortvars(ifortvars_bat, "ia32", opt)
        local ifortvars_x64 = _load_ifortvars(ifortvars_bat, "intel64", opt)

        -- save results
        return {ifortvars_bat = ifortvars_bat, ifortvars = {x86 = ifortvars_x86, x64 = ifortvars_x64}}
     end
end

-- find intel fortran envirnoment on linux
function _find_intel_on_linux(opt)

    -- attempt to find the sdk directory
    local paths = {"/opt/intel/bin", "/usr/local/bin", "/usr/bin"}
    local ifort = find_file("ifort", paths)
    if ifort then
        local sdkdir = path.directory(path.directory(ifort))
        return {sdkdir = sdkdir, bindir = path.directory(ifort), path.join(sdkdir, "include"), libdir = path.join(sdkdir, "lib")}
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
