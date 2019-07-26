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
-- @file        xmake.lua
--

-- imports
import("core.base.option")

-- get configs
function _get_configs(package, configs)
    local configs  = configs or {}
    local cflags   = package:config("cflags")
    local cxflags  = package:config("cxflags")
    local cxxflags = package:config("cxxflags")
    local asflags  = package:config("asflags")
    if package:is_plat("windows") then
        local vs_runtime = package:config("vs_runtime")
        if vs_runtime then
            cxflags = (cxflags or "") .. " /" .. vs_runtime .. (package:debug() and "d" or "")
        end
    end
    table.insert(configs, "--mode=" .. (package:debug() and "debug" or "release"))
    if cflags then
        table.insert(configs, "--cflags=" .. cflags)
    end
    if cxflags then
        table.insert(configs, "--cxflags=" .. cxflags)
    end
    if cxxflags then
        table.insert(configs, "--cxxflags=" .. cxxflags)
    end
    if asflags then
        table.insert(configs, "--asflags=" .. asflags)
    end
    return configs
end

-- init arguments and inherit some global options from the parent xmake
function _init_argv(...)
    local argv = {...}
    for _, name in ipairs({"diagnosis", "verbose", "quiet", "yes", "confirm", "root"}) do
        local value = option.get(name) 
        if type(value) == "boolean" then
            table.insert(argv, "--" .. name)
        elseif value ~= nil then
            table.insert(argv, "--" .. name .. "=" .. value)
        end
    end
    return argv
end

-- install package
function install(package, configs)

    -- inherit builtin configs
    local argv = _init_argv("f", "-y", "-c")
    local names   = {"plat", "arch", "ndk", "ndk_sdkver", "vs", "mingw", "sdk", "bin", "cross", "ld", "sh", "ar", "cc", "cxx", "mm", "mxx"}
    for _, name in ipairs(names) do
        local value = get_config(name)
        if value ~= nil then
            table.insert(argv, "--" .. name .. "=" .. tostring(value))
        end
    end

    -- pass configurations
    for name, value in pairs(_get_configs(package, configs)) do
        value = tostring(value):trim()
        if type(name) == "number" then
            if value ~= "" then
                table.insert(argv, value)
            end
        else
            table.insert(argv, "--" .. name .. "=" .. value)
        end
    end
    os.vrunv("xmake", argv)

    -- do build
    argv = _init_argv()
    os.vrunv("xmake", argv)

    -- do install
    argv = _init_argv("install", "-y", "-o", package:installdir())
    os.vrunv("xmake", argv)
end
