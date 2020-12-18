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
-- @file        template.lua
--

-- define module: template
local template  = template or {}
local _instance = _instance or {}

-- load modules
local os                = require("base/os")
local io                = require("base/io")
local path              = require("base/path")
local table             = require("base/table")
local utils             = require("base/utils")
local string            = require("base/string")
local interpreter       = require("base/interpreter")

-- new an instance
function _instance.new(name, info, scriptdir)
    local instance = table.inherit(_instance)
    instance._NAME = name
    instance._INFO = info
    instance._SCRIPTDIR = scriptdir
    return instance
end

-- get the package name
function _instance:name()
    return self._NAME
end

-- get the package configure
function _instance:get(name)

    -- get it from info first
    local value = self._INFO:get(name)
    if value ~= nil then
        return value
    end
end

-- get the script directory
function _instance:scriptdir()
    return self._SCRIPTDIR
end

-- the interpreter
function template._interpreter()

    -- the interpreter has been initialized? return it directly
    if template._INTERPRETER then
        return template._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)

    -- define apis
    interp:api_define
    {
        values =
        {
            -- add_xxx
            "template.add_configfiles"
        }
    ,   script =
        {
            -- after_xxx
            "template.after_create"
        }
    }

    -- save interpreter
    template._INTERPRETER = interp

    -- ok?
    return interp
end

-- get the language list
function template.languages()

    -- make list
    local list = {}

    -- get the language list
    local languages = os.dirs(path.join(os.programdir(), "templates", "*"))
    if languages then
        for _, v in ipairs(languages) do
            table.insert(list, path.basename(v))
        end
    end

    -- ok?
    return list
end

-- load all templates from the given language
function template.templates(language)

    -- check
    assert(language)

    -- get interpreter
    local interp = template._interpreter()
    assert(interp)

    -- load all templates
    local templates = {}
    local templatefiles = os.files(path.join(os.programdir(), "templates", language, "*", "template.lua"))
    if templatefiles then

        -- load template
        for _, templatefile in ipairs(templatefiles) do

            -- load script
            local ok, errors = interp:load(templatefile)
            if not ok then
                os.raise(errors)
            end

            -- load template
            local results, errors = interp:make("template", true, true)
            if not results then
                os.raise(errors)
            end

            -- get the template name and info
            local templatename = nil
            local templateinfo = nil
            for name, info in pairs(results) do
                templatename = name
                templateinfo = info
                break
            end
            if not templateinfo then
                return nil, string.format("%s: package not found!", templatefile)
            end

            -- new an instance
            local instance = _instance.new(templatename, templateinfo, path.directory(templatefile))

            -- insert to templates
            table.insert(templates, instance)
        end
    end
    return templates
end

-- return module: template
return template
