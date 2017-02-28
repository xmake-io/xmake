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
-- @file        template.lua
--

-- define module: template
local template = template or {}

-- load modules
local os                = require("base/os")
local io                = require("base/io")
local path              = require("base/path")
local table             = require("base/table")
local utils             = require("base/utils")
local string            = require("base/string")
local filter            = require("base/filter")
local option            = require("base/option")
local sandbox           = require("sandbox/sandbox")
local project           = require("project/project")
local interpreter       = require("base/interpreter")

-- the interpreter
function template._interpreter()

    -- the interpreter has been initialized? return it directly
    if template._INTERPRETER then
        return template._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)

    -- define apis (only root scope)
    interp:api_define
    {
        values =
        {
            -- set_xxx
            "set_description"
        ,   "set_projectdir"
            -- add_xxx
        ,   "add_macrofiles"
        }
    ,   script =
        {
            -- on_xxx
            "on_create"
        }
    ,   dictionary = 
        {
            -- set_xxx
            "set_macros"
            -- add_xxx
        ,   "add_macros"
        }
    }

    -- save interpreter
    template._INTERPRETER = interp

    -- ok?
    return interp
end

-- replace macros
function template._replace(macros, macrofiles)

    -- check
    assert(macros and macrofiles)

    -- make all files
    local files = {}
    for _, macrofile in ipairs(table.wrap(macrofiles)) do
        local matchfiles = os.match(macrofile)
        if matchfiles then
            table.join2(files, matchfiles)
        end
    end

    -- replace all files
    for _, file in ipairs(files) do
        for macro, value in pairs(macros) do
            io.gsub(file, "%[" .. macro .. "%]", value)
        end
    end

    -- ok
    return true
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
function template.templates(language)

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
                os.raise(errors)
            end

            -- save template directory
            results._DIRECTORY = path.directory(templatefile)

            -- insert to templates
            table.insert(templates, results)
        end
    end

    -- sort templates
    table.sort(templates, function(a, b) return a.description:less(b.description) end)

    -- ok?
    return templates
end

-- create project from template
function template.create(language, templateid, targetname)

    -- check the language
    if not language then
        return false, "no language!"
    end

    -- check the template id
    if not templateid then
        return false, "no template id!"
    end

    templateid = tonumber(templateid)
    if type(templateid) ~= "number" then
        return false, "invalid template id!"
    end

    -- get interpreter
    local interp = template._interpreter()
    assert(interp) 

    -- get project directory
    local projectdir = path.absolute(option.get("project") or path.join(os.curdir(), targetname))

    -- set filter
    interp:filter_set(filter.new(function (variable)

        -- init maps
        local maps = 
        {
            targetname  = targetname
        ,   projectdir  = projectdir
        }

        -- map it
        local result = maps[variable]
        if result ~= nil then
            return result
        end

        -- ok?
        return variable

    end))

    -- load all templates for the given language
    local templates = template.templates(language)

    -- load the template module
    local module = nil
    if templates then module = templates[templateid] end
    if not module then
        return false, string.format("invalid template id: %d!", templateid)
    end

    -- enter the template directory
    if not module._DIRECTORY or not os.cd(module._DIRECTORY) then
        return false, string.format("not found template id: %d!", templateid)
    end

    -- check the template project
    if not module.projectdir or not os.isdir(module.projectdir) then
        return false, string.format("the template project not exists!")
    end
    
    -- ensure the project directory 
    if not os.isdir(projectdir) then 
        os.mkdir(projectdir)
    end

    -- copy the project files
    local ok, errors = os.cp(path.join(module.projectdir, "*"), projectdir) 
    if not ok then
        return false, errors
    end

    -- enter the project directory
    if not os.cd(projectdir) then
        return false, string.format("can not enter %s!", projectdir)
    end

    -- replace macros
    if module.macros and module.macrofiles then
        ok, errors = template._replace(module.macros, module.macrofiles)
        if not ok then
            return false, errors
        end
    end

    -- create project
    if module.create then
        local ok, errors = sandbox.load(module.create)
        if not ok then
            utils.errors(errors)
            return false
        end
    end

    -- ok
    return true
end

-- return module: template
return template
