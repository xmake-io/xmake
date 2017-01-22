--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
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

-- get the language menu
function _instance:menu()

    -- get it
    return self._INFO.menu
end

-- get the language name
function _instance:name()

    -- get it
    return self._NAME
end

-- get the language source extensions
function _instance:extensions()

    -- attempt to get it from cache
    if self._EXTENSIONS then
        return self._EXTENSIONS
    end

    -- get extensions
    local extensions = {}
    for sourcekind, exts in pairs(self:sourcekinds()) do
        for _, extension in ipairs(table.wrap(exts)) do
            extensions[extension:lower()] = sourcekind
        end
    end

    -- cache it
    self._EXTENSIONS = extensions

    -- get it
    return extensions
end

-- get the language source kinds
function _instance:sourcekinds()

    -- get it
    return self._INFO.sourcekinds
end

-- get the language target kinds
function _instance:targetkinds()

    -- get it
    return self._INFO.targetkinds
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
            "language.set_menu"
        ,   "language.set_targetkinds"
        }
    ,   script =
        {
            -- language.on_xxx
            "language.on_load"
        ,   "language.on_check_main"
        }
    ,   dictionary =
        {
            -- language.set_xxx
            "language.set_sourcekinds"
        }
    }

    -- save interpreter
    language._INTERPRETER = interp

    -- ok?
    return interp
end

-- load the language from the given name (c++, objc++, swift, golang, asm, ...)
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

-- load the language from the given source kind: cc, cxx, mm, mxx, sc, go, as ..
function language.load_sk(sourcekind)

    -- load all languages
    local languages, errors = language.load()
    if not languages then
        return nil, errors
    end

    -- make source kind as lower
    sourcekind = sourcekind:lower()

    -- get it directly from cache dirst
    language._LANGUAGES_OF_SK = language._LANGUAGES_OF_SK or {}
    if language._LANGUAGES_OF_SK[sourcekind] then
        return language._LANGUAGES_OF_SK[sourcekind]
    end

    -- find language instance
    local result = nil
    for _, instance in pairs(languages) do
        if instance:sourcekinds()[sourcekind] ~= nil then
            result = instance
            break
        end
    end

    -- not found?
    if not result then
        return nil, string.format("unknown language sourcekind: %s", sourcekind)
    end

    -- cache this language
    language._LANGUAGES_OF_SK[sourcekind] = result

    -- ok
    return result
end

-- load the language from the given source extension: .c, .cpp, .m, .mm, .swift, .go, .s ..
function language.load_ex(extension)

    -- load all languages
    local languages, errors = language.load()
    if not languages then
        return nil, errors
    end

    -- make source extension as lower
    extension = extension:lower()

    -- get it directly from cache dirst
    language._LANGUAGES_OF_EX = language._LANGUAGES_OF_EX or {}
    if language._LANGUAGES_OF_EX[extension] then
        return language._LANGUAGES_OF_EX[extension]
    end

    -- find language instance
    local result = nil
    for _, instance in pairs(languages) do
        if instance:extensions()[extension] ~= nil then
            result = instance
            break
        end
    end

    -- not found?
    if not result then
        return nil, string.format("unknown language source extension: %s", extension)
    end

    -- cache this language
    language._LANGUAGES_OF_EX[extension] = result

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

-- get language source extensions
--
-- .e.g
--
-- {
--      [".c"]      = cc
-- ,    [".cc"]     = cxx
-- ,    [".cpp"]    = cxx
-- ,    [".m"]      = mm
-- ,    [".mm"]     = mxx
-- ,    [".swift"]  = sc
-- ,    [".go"]     = go
-- }
--
function language.extensions()

    -- attempt to get it from cache
    if language._EXTENSIONS then
        return language._EXTENSIONS
    end

    -- load all languages
    local languages, errors = language.load()
    if not languages then
        os.raise(errors)
    end

    -- merge all for each language
    local extensions = {}
    for name, instance in pairs(languages) do
        table.join2(extensions, instance:extensions())
    end

    -- cache it
    language._EXTENSIONS = extensions

    -- ok
    return extensions
end

-- get language source kinds
--
-- .e.g
--
-- {
--      cc  = ".c"
-- ,    cxx = {".cc", ".cpp", ".cxx"}
-- ,    mm  = ".m"
-- ,    mxx = ".mm"
-- ,    sc  = ".swift"
-- ,    go  = ".go"
-- }
--
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

    -- merge all for each language
    local sourcekinds = {}
    for name, instance in pairs(languages) do
        table.join2(sourcekinds, instance:sourcekinds())
    end

    -- cache it
    language._SOURCEKINDS = sourcekinds

    -- ok
    return sourcekinds
end

-- get source kind of the source file name
function language.sourcekind_of(sourcefile)

    -- get the source file extension
    local extension = path.extension(sourcefile)
    if not extension then
        return nil, string.format("%s has not extension", sourcefile)
    end

    -- get extensions
    local extensions = language.extensions()

    -- get source kind from extension
    local sourcekind = extensions[extension:lower()]
    if not sourcekind then
        return nil, string.format("%s is unknown extension", extension)
    end

    -- ok
    return sourcekind
end

-- return module
return language
