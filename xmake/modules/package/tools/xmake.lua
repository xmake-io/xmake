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
-- @file        xmake.lua
--

-- imports
import("core.base.option")

-- get configs
function _get_configs(package, configs)
    local configs  = configs or {}
    local cflags   = table.join(table.wrap(package:config("cflags")),   get_config("cflags"))
    local cxflags  = table.join(table.wrap(package:config("cxflags")),  get_config("cxflags"))
    local cxxflags = table.join(table.wrap(package:config("cxxflags")), get_config("cxxflags"))
    local asflags  = table.join(table.wrap(package:config("asflags")),  get_config("asflags"))
    local ldflags  = table.join(table.wrap(package:config("ldflags")),  get_config("ldflags"))
    if package:is_plat("windows") then
        local vs_runtime = package:config("vs_runtime")
        if vs_runtime then
            local vs_runtime_cxflags = "/" .. vs_runtime .. (package:debug() and "d" or "")
            table.insert(cxflags, vs_runtime_cxflags)
        end
    end
    table.insert(configs, "--mode=" .. (package:debug() and "debug" or "release"))
    if cflags then
        table.insert(configs, "--cflags=" .. table.concat(cflags, ' '))
    end
    if cxflags then
        table.insert(configs, "--cxflags=" .. table.concat(cxflags, ' '))
    end
    if cxxflags then
        table.insert(configs, "--cxxflags=" .. table.concat(cxxflags, ' '))
    end
    if asflags then
        table.insert(configs, "--asflags=" .. table.concat(asflags, ' '))
    end
    if ldflags then
        table.insert(configs, "--ldflags=" .. table.concat(ldflags, ' '))
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
