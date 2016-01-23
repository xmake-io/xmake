--!The Automatic Cross-platform Build Tool
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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        template.lua
--

-- define module: template
local template = template or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local interpreter   = require("base/interpreter")

-- get interpreter
function template._interpreter()

    -- the interpreter has been initialized? return it directly
    if template._INTERPRETER then
        return template._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.init()
    assert(interp)

    -- register api: set_values() for root
    interp:api_register_set_values(nil, nil,    "description"
                                            ,   "projectdir")

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
    local languages = os.match(xmake._TEMPLATES_DIR .. "/*", true)
    if languages then
        for _, v in ipairs(languages) do
            table.insert(list, path.basename(v))
        end
    end

    -- ok?
    return list
end

-- load all templates from the given language 
function template.loadall(language)

    -- check
    assert(language)

    -- get interpreter
    local interp = template._interpreter()
    assert(interp) 

    -- load all templates
    local templates = {}
    local templatefiles = os.match(string.format("%s/%s/**/template.lua", xmake._TEMPLATES_DIR, language))
    if templatefiles then

        -- load template
        for _, templatefile in ipairs(templatefiles) do

            -- load templates
            local results, errors = interp:load(templatefile, nil, true, true)
            if not results then
                -- trace
                utils.error(errors)
                utils.abort()
            end

            -- insert to templates
            table.insert(templates, results)

        end
    end

    -- ok?
    return templates
end

-- return module: template
return template
