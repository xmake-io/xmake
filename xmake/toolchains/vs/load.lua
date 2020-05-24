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

    -- get arch
    local arch = config.get("arch") or ""

    -- get vs environment for the current arch
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
            if vsenv and vsenv.path and vsenv.include and vsenv.lib then
                config.set("__vcvarsall", vcvarsall)
            end
        end
    end

    -- get the pathes for the vs environment
    local new = vsenv[name]
    if new then
        toolchain:add("runenvs", name:upper(), path.splitenv(new))
    end
end

-- main entry
function main(toolchain)

    -- set toolsets
    toolchain:set("toolsets", "cc",  "cl.exe")
    toolchain:set("toolsets", "cxx", "cl.exe")
    toolchain:set("toolsets", "mrc", "rc.exe")
    if is_arch("x64") then
        toolchain:set("toolsets", "as",  "ml64.exe")
    else
        toolchain:set("toolsets", "as",  "ml.exe")
    end
    toolchain:set("toolsets", "ld",  "link.exe")
    toolchain:set("toolsets", "sh",  "link.exe -dll")
    toolchain:set("toolsets", "ar",  "link.exe -lib")
    toolchain:set("toolsets", "ex",  "lib.exe")

    -- add vs environments
    _add_vsenv(toolchain, "path")
    _add_vsenv(toolchain, "lib")
    _add_vsenv(toolchain, "include")
    _add_vsenv(toolchain, "libpath")
end

