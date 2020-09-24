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
-- @file        config.lua
--

-- define module
local config = config or {}

-- load modules
local io            = require("base/io")
local os            = require("base/os")
local path          = require("base/path")
local table         = require("base/table")
local utils         = require("base/utils")
local option        = require("base/option")

-- load the project configure
function config._load(targetname)

    -- check
    targetname = targetname or "all"

    -- load configure from the file first
    local filepath = config.filepath()
    if os.isfile(filepath) then

        -- load it
        local results, errors = io.load(filepath)
        if not results then
            return nil, errors
        end

        -- load the target configure
        if results._TARGETS then
            return table.wrap(results._TARGETS[targetname])
        end
    end

    -- empty
    return {}
end

-- get the current given configure
function config.get(name)

    -- get it
    local value = nil
    if config._CONFIGS then
        value = config._CONFIGS[name]
        if type(value) == "string" and value == "auto" then
            value = nil
        end
    end

    -- get it
    return value
end

-- this config name is readonly?
function config.readonly(name)
    return config._MODES and config._MODES["__readonly_" .. name]
end

-- set the given configure to the current
--
-- @param name  the name
-- @param value the value
-- @param opt   the argument options, e.g. {readonly = false, force = false}
--
function config.set(name, value, opt)

    -- check
    assert(name)

    -- init options
    opt = opt or {}

    -- check readonly
    assert(opt.force or not config.readonly(name), "cannot set readonly config: " .. name)

    -- set it
    config._CONFIGS = config._CONFIGS or {}
    config._CONFIGS[name] = value

    -- mark as readonly
    if opt.readonly then
        config._MODES = config._MODES or {}
        config._MODES["__readonly_" .. name] = true
    end
end

-- get all options
function config.options()

    -- check
    assert(config._CONFIGS)

    -- remove values with "auto" and private item
    local configs = {}
    for name, value in pairs(config._CONFIGS) do
        if not name:find("^_%u+") and (type(value) ~= "string" or value ~= "auto") then
            configs[name] = value
        end
    end

    -- get it
    return configs
end

-- get the buildir
function config.buildir()

    -- get the absolute path first
    local buildir = config.get("buildir") or "build"
    if not path.is_absolute(buildir) then
        local rootdir
        if os.isdir(path.join(os.workingdir(), ".xmake")) then
            -- we switch to independent working directory @see https://github.com/xmake-io/xmake/issues/820
            rootdir = os.workingdir()
        else
            rootdir = os.projectdir()
        end
        buildir = path.absolute(buildir, rootdir)
    end

    -- adjust path for the current directory
    buildir = path.relative(buildir, os.curdir())
    return buildir
end

-- get the configure file
function config.filepath()
    return path.join(config.directory(), xmake._NAME .. ".conf")
end

-- get the configure directory on the current host/arch platform
function config.directory()
    if config._DIRECTORY == nil then
        local rootdir = os.getenv("XMAKE_CONFIGDIR")
        if not rootdir and os.isdir(path.join(os.workingdir(), ".xmake")) then
            -- we switch to independent working directory @see https://github.com/xmake-io/xmake/issues/820
            rootdir = os.workingdir()
        end
        if not rootdir then
            rootdir = os.projectdir()
        end
        config._DIRECTORY = path.join(rootdir, "." .. xmake._NAME, os.host(), os.arch())
    end
    return config._DIRECTORY
end

-- load the project configure
function config.load(targetname)

    -- load configure
    local results, errors = config._load(targetname)
    if not results then
        utils.error(errors)
        return false
    end

    -- merge the target configure first
    local ok = false
    for name, value in pairs(results) do
        if config.get(name) == nil then
            config.set(name, value)
            ok = true
        end
    end

    -- ok?
    return ok
end

-- save the project configure
function config.save(targetname)

    -- check
    targetname = targetname or "all"

    -- load the previous results from configure
    local results = {}
    local filepath = config.filepath()
    if os.isfile(filepath) then
        results = io.load(filepath) or {}
    end

    -- the targets
    local targets = results._TARGETS or {}
    results._TARGETS = targets

    -- clear target first
    targets[targetname] = {}

    -- update target
    local target = targets[targetname]
    for name, value in pairs(config.options()) do
        target[name] = value
    end

    -- add version
    results.__version = xmake._VERSION_SHORT

    -- save it
    return io.save(config.filepath(), results)
end

-- read value from the configure file directly
function config.read(name, targetname)

    -- load configs
    local configs = config._load(targetname)

    -- get it
    local value = nil
    if configs then
        value = configs[name]
        if type(value) == "string" and value == "auto" then
            value = nil
        end
    end

    -- ok?
    return value
end

-- clear config
function config.clear()
    config._MODES = nil
    config._CONFIGS = nil
end

-- the current mode is belong to the given modes?
function config.is_mode(...)
    return config.is_value("mode", ...)
end

-- the current platform is belong to the given platforms?
function config.is_plat(...)
    return config.is_value("plat", ...)
end

-- the current architecture is belong to the given architectures?
function config.is_arch(...)
    return config.is_value("arch", ...)
end

-- the current config is belong to the given config values?
function config.is_value(name, ...)

    -- get the current config value
    local value = config.get(name)
    if not value then return false end

    -- exists this value? and escape '-'
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" and value:find("^" .. v:gsub("%-", "%%-") .. "$") then
            return true
        end
    end
end

-- has the given configs?
function config.has(...)
    for _, name in ipairs(table.join(...)) do
        if name and type(name) == "string" and config.get(name) then
            return true
        end
    end
end

-- dump the configure
function config.dump()
    if not option.get("quiet") then
        utils.print("configure")
        utils.print("{")
        for name, value in pairs(config.options()) do
            if not name:startswith("__") then
                utils.print("    %s = %s", name, value)
            end
        end
        utils.print("}")
    end
end

-- return module
return config
