--!A cross-toolchain build utility based on Lua
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
-- @file        load.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("detect.sdks.find_vstudio")

-- add the given vs environment
function _add_vsenv(toolchain, name)

    -- get vcvarsall
    local vcvarsall = config.get("__vcvarsall")
    if not vcvarsall then
        return
    end

    -- get vs environment for the current arch
    local arch = toolchain:arch()
    local vsenv = vcvarsall[arch] or {}

    -- switch vstudio environment if vs_sdkver has been changed
    local switch_vsenv = false
    local vs = config.get("vs")
    local vs_sdkver = config.get("vs_sdkver")
    if vs and vs_sdkver and vsenv.WindowsSDKVersion and vs_sdkver ~= vsenv.WindowsSDKVersion then
        switch_vsenv = true
    end
    if switch_vsenv then
        -- find vstudio
        local vstudio = find_vstudio({vcvars_ver = config.get("vs_toolset"), sdkver = vs_sdkver})
        if vstudio then
            vcvarsall = (vstudio[vs] or {}).vcvarsall or {}
            vsenv = vcvarsall[arch] or {}
            if vsenv and vsenv.PATH and vsenv.INCLUDE and vsenv.LIB then
                config.set("__vcvarsall", vcvarsall)
            end
        end
    end

    -- get the paths for the vs environment
    local new = vsenv[name]
    if new then
        toolchain:add("runenvs", name:upper(), path.splitenv(new))
    end
end

-- main entry
function main(toolchain)

    -- set toolset
    toolchain:set("toolset", "cc",  "cl.exe")
    toolchain:set("toolset", "cxx", "cl.exe")
    toolchain:set("toolset", "mrc", "rc.exe")
    if toolchain:is_arch("x64") then
        toolchain:set("toolset", "as",  "ml64.exe")
    else
        toolchain:set("toolset", "as",  "ml.exe")
    end
    toolchain:set("toolset", "ld",  "link.exe")
    toolchain:set("toolset", "sh",  "link.exe")
    toolchain:set("toolset", "ar",  "link.exe")
    toolchain:set("toolset", "ex",  "lib.exe")

    -- add vs environments
    _add_vsenv(toolchain, "PATH")
    _add_vsenv(toolchain, "LIB")
    _add_vsenv(toolchain, "INCLUDE")
    _add_vsenv(toolchain, "LIBPATH")
end

