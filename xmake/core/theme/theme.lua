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
-- @file        theme.lua
--

-- define module
local theme         = theme or {}
local _instance     = _instance or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local table         = require("base/table")
local interpreter   = require("base/interpreter")
local global        = require("base/global")

-- new an instance
function _instance.new(name, info, rootdir)
    local instance    = table.inherit(_instance)
    instance._NAME    = name
    instance._INFO    = info
    instance._ROOTDIR = rootdir
    return instance
end

-- get theme name
function _instance:name()
    return self._NAME
end

-- get the theme configuration
function _instance:get(name)
    return self._INFO:get(name)
end

-- the interpreter
function theme._interpreter()

    -- the interpreter has been initialized? return it directly
    if theme._INTERPRETER then
        return theme._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)

    -- define apis
    interp:api_define(theme._apis())

    -- save interpreter
    theme._INTERPRETER = interp

    -- ok?
    return interp
end

-- get theme apis
function theme._apis()
    return
    {
        keyvalues =
        {
            -- theme.set_xxx
            "theme.set_color"
        ,   "theme.set_text"
        }
    }
end

-- get theme directories
function theme.directories()

    -- init directories
    local dirs = theme._DIRS or {   path.join(global.directory(), "themes")
                                ,   path.join(os.programdir(), "themes")
                                }

    -- save directories to cache
    theme._DIRS = dirs
    return dirs
end

-- find all themes
function theme.names()

    local paths = {}
    for _, dir in ipairs(theme.directories()) do
        table.join2(paths, (os.files(path.join(dir, "*", "xmake.lua"))))
    end
    for i, v in ipairs(paths) do
        local value = path.split(v)
        paths[i] = value[#value - 1]
    end
    return paths
end

-- load the given theme
function theme.load(name)

    -- find the theme script path
    local scriptpath = nil
    for _, dir in ipairs(theme.directories()) do
        scriptpath = path.join(dir, name, "xmake.lua")
        if os.isfile(scriptpath) then
            break
        end
    end

    -- not exists? uses the default theme
    if not scriptpath or not os.isfile(scriptpath) then
        scriptpath = path.join(os.programdir(), "themes", "default", "xmake.lua")
    end

    -- get interpreter
    local interp = theme._interpreter()

    -- load script
    local ok, errors = interp:load(scriptpath)
    if not ok then
        return nil, errors
    end

    -- load theme
    local results, errors = interp:make("theme", true, false)
    if not results and os.isfile(scriptpath) then
        return nil, errors
    end

    -- get result
    local result = results[name]
    if not result then
        return nil, string.format("the theme %s not found!", name)
    end

    -- new an instance
    local instance, errors = _instance.new(name, result, interp:rootdir())
    if not instance then
        return nil, errors
    end

    -- save the current theme instance
    theme._THEME = instance
    return instance
end

-- get the current theme instance
function theme.instance()
    return theme._THEME
end

-- get the given theme configuration
function theme.get(name)
    local instance = theme._THEME
    if instance then
        return instance:get(name)
    end
end

-- return module
return theme
