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
-- @file        global.lua
--

-- define module
local global = global or {}

-- load modules
local io            = require("base/io")
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local option        = require("base/option")

-- get the current given configure
function global.get(name)
    local value = nil
    if global._CONFIGS then
        value = global._CONFIGS[name]
        if type(value) == "string" and value == "auto" then
            value = nil
        end
    end
    return value
end

-- this global name is readonly?
function global.readonly(name)
    return global._MODES and global._MODES["__readonly_" .. name]
end

-- set the given configure to the current
--
-- @param name  the name
-- @param value the value
-- @param opt   the argument options, e.g. {readonly = false, force = false}
--
function global.set(name, value, opt)

    -- check
    assert(name)

    -- init options
    opt = opt or {}

    -- check readonly
    assert(opt.force or not global.readonly(name), "cannot set readonly global: " .. name)

    -- set it
    global._CONFIGS = global._CONFIGS or {}
    global._CONFIGS[name] = value

    -- mark as readonly
    if opt.readonly then
        global._MODES = global._MODES or {}
        global._MODES["__readonly_" .. name] = true
    end
end

-- get all options
function global.options()

    -- remove values with "auto" and private item
    local configs = {}
    for name, value in pairs(table.wrap(global._CONFIGS)) do
        if not name:find("^_%u+") and name ~= "__version" and (type(value) ~= "string" or value ~= "auto") then
            configs[name] = value
        end
    end
    return configs
end

-- get the configure file
function global.filepath()
    return path.join(global.directory(), xmake._NAME .. ".conf")
end

-- get the global configure directory
function global.directory()
    if global._DIRECTORY == nil then
        local name = "." .. xmake._NAME
        local rootdir = os.getenv("XMAKE_GLOBALDIR")
        if not rootdir then
            -- compatible with the old `%appdata%/.xmake` directory if it exists
            local appdata = (os.host() == "windows") and os.getenv("APPDATA")
            if appdata and os.isdir(path.join(appdata, name)) then
                rootdir = appdata
            else
                rootdir = path.translate("~")
            end
        end
        global._DIRECTORY = path.join(rootdir, name)
    end
    return global._DIRECTORY
end

-- get the global cache directory
function global.cachedir()
    return global.get("cachedir") or path.join(global.directory(), "cache")
end

-- load the global configuration
function global.load()

    -- load configure from the file first
    local filepath = global.filepath()
    if os.isfile(filepath) then

        -- load configs
        local results, errors = io.load(filepath)
        if not results then
            return false, errors
        end

        -- merge the configure
        for name, value in pairs(results) do
            if global.get(name) == nil then
                global.set(name, value)
            end
        end
    end
    return true
end

-- save the global configure
function global.save()

    -- the options
    local options = global.options()
    assert(options)

    -- add version
    options.__version = xmake._VERSION_SHORT

    -- save it
    return io.save(global.filepath(), options)
end

-- clear config
function global.clear()
    global._MODES = nil
    global._CONFIGS = nil
end

-- dump the configure
function global.dump()
    if not option.get("quiet") then
        utils.print("configure")
        utils.print("{")
        for name, value in pairs(global.options()) do
            if not name:startswith("__") then
                utils.print("    %s = %s", name, value)
            end
        end
        utils.print("}")
    end
end

-- return module
return global
