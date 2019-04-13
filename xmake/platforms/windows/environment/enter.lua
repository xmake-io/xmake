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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        enter.lua
--

-- imports
import("core.project.config")
import("core.base.global")
import("detect.sdks.find_vstudio")

-- enter the given environment
function _enter(platform, name)

    -- get vcvarsall
    local vcvarsall = config.get("__vcvarsall") or global.get("__vcvarsall")
    if not vcvarsall then
        return 
    end

    -- get arch
    local arch = config.get("arch") or global.get("arch") or ""

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
    local old = nil
    local new = vsenv[name]
    if new then

        -- get the current pathes
        old = os.getenv(name) or ""

        -- append the current pathes
        new = new .. ";" .. old

        -- update the pathes for the environment
        os.setenv(name, new)
    end

    -- save the previous environment
    platform:data_set("windows.environment." .. name, old)
end

-- enter the toolchains environment
function _enter_toolchains(platform)
    _enter(platform, "path")
    _enter(platform, "lib")
    _enter(platform, "include")
    _enter(platform, "libpath")
end

-- enter environment
function main(platform, name)
    local maps = {toolchains = _enter_toolchains}
    local func = maps[name]
    if func then
        func(platform)
    end
end

