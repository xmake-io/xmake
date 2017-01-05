--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        language.lua
--

-- define module
local language      = language or {}
local _instance     = _instance or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local table         = require("base/table")
local interpreter   = require("base/interpreter")
local sandbox       = require("sandbox/sandbox")
local config        = require("project/config")
local global        = require("project/global")

-- new an instance
function _instance.new(name, info, rootdir)

    -- new an instance
    local instance = table.inherit(_instance)

    -- init instance
    instance._NAME      = name
    instance._INFO      = info
    instance._ROOTDIR   = rootdir

    -- ok
    return instance
end

-- get the language configure
function _instance:get(name)

    -- the info
    local info = self._INFO

    -- get if from info first
    local value = info[name]
    if value ~= nil then
        return value 
    end

    -- load _g 
    if self._g == nil and info.load ~= nil then

        -- load it
        local ok, results = sandbox.load(info.load)
        if not ok then
            os.raise(results)
        end

        -- save _g
        self._g = results
    end

    -- get it from _g 
    return self._g[name]
end

-- get the language sourcekinds
function _instance:sourcekinds()

    -- get it
    return self._INFO.sourcekinds
end

-- the directory of language
function language._directory()

    -- the directory
    return path.join(xmake._PROGRAM_DIR, "languages")
end

-- the interpreter
function language._interpreter()

    -- the interpreter has been initialized? return it directly
    if language._INTERPRETER then
        return language._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)
 
    -- define apis
    interp:api_define
    {
        values =
        {
            -- language.set_xxx
            "language.set_sourcekinds"
        }
    ,   script =
        {
            -- language.on_xxx
            "language.on_load"
        }
    }

    -- save interpreter
    language._INTERPRETER = interp

    -- ok?
    return interp
end

-- load the language from the given name
function language.load(name)

    -- load all languages
    if not name then
        for _, name in ipairs(table.wrap(os.match(path.join(language._directory(), "*"), true))) do
            local instance, errors = language.load(path.basename(name))
            if not instance then
                return nil, errors
            end
        end
        return language._LANGUAGES
    end

    -- get it directly from cache dirst
    language._LANGUAGES = language._LANGUAGES or {}
    if language._LANGUAGES[name] then
        return language._LANGUAGES[name]
    end

    -- find the language script path
    local scriptpath = path.join(path.join(language._directory(), name), "xmake.lua")
    if not os.isfile(scriptpath) then
        return nil, string.format("the language %s not found!", name)
    end

    -- not exists?
    if not scriptpath or not os.isfile(scriptpath) then
        return nil, string.format("the language %s not found!", name)
    end

    -- load language
    local results, errors = language._interpreter():load(scriptpath, "language", true, false)
    if not results and os.isfile(scriptpath) then
        return nil, errors
    end

    -- check the language name
    if not results[name] then
        return nil, string.format("the language %s not found!", name)
    end

    -- new an instance
    local instance, errors = _instance.new(name, results[name], language._interpreter():rootdir())
    if not instance then
        return nil, errors
    end

    -- save instance to the cache
    language._LANGUAGES[name] = instance

    -- ok
    return instance
end

-- load the language from the given kind: .c, .cpp, .mm ..
function language.load_from_kind(kind)

    -- load all languages
    local languages, errors = language.load()
    if not languages then
        return nil, errors
    end

    -- make kind as lower
    kind = kind:lower()

    -- get it directly from cache dirst
    language._LANGUAGES_OF_KIND = language._LANGUAGES_OF_KIND or {}
    if language._LANGUAGES_OF_KIND[kind] then
        return language._LANGUAGES_OF_KIND[kind]
    end

    -- find language instance
    local result = nil
    for _, instance in pairs(languages) do
        for _, sourcekind in ipairs(table.wrap(instance:sourcekinds())) do
            if sourcekind == kind then
                result = instance
                break
            end
        end
    end

    -- not found?
    if not result then
        return nil, string.format("unknown language kind: %s", kind)
    end

    -- cache this language
    language._LANGUAGES_OF_KIND[kind] = result

    -- ok
    return result
end

-- load the language apis
function language.apis()

    -- load all languages
    local languages, errors = language.load()
    if not languages then
        os.raise(errors)
    end

    -- merge apis for each language
    local apis = {values = {}, pathes = {}, custom = {}}
    for name, instance in pairs(languages) do
        local instance_apis = instance:get("apis")
        if instance_apis then
            table.join2(apis.values, table.wrap(instance_apis.values))
            table.join2(apis.pathes, table.wrap(instance_apis.pathes))
            table.join2(apis.custom, table.wrap(instance_apis.custom))
        end
    end
    apis.values = table.unique(apis.values)
    apis.pathes = table.unique(apis.pathes)
    apis.custom = table.unique(apis.custom)

    -- ok
    return apis
end

-- get language sourcekinds
function language.sourcekinds()

    -- attempt to get it from cache
    if language._SOURCEKINDS then
        return language._SOURCEKINDS
    end

    -- load all languages
    local languages, errors = language.load()
    if not languages then
        os.raise(errors)
    end

    -- merge apis for each language
    local sourcekinds = {}
    for name, instance in pairs(languages) do
        table.join2(sourcekinds, table.wrap(instance:sourcekinds()))
    end

    -- cache it
    language._SOURCEKINDS = table.unique(sourcekinds)

    -- ok
    return language._SOURCEKINDS
end

-- return module
return language
