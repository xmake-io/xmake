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
-- @file        template.lua
--

-- define module
local sandbox_core_project_template = sandbox_core_project_template or {}

-- load modules
local template  = require("project/template")
local raise     = require("sandbox/modules/raise")

-- get all languages
function sandbox_core_project_template.languages()

    -- get it 
    local languages = template.languages()
    assert(languages)

    -- ok
    return languages
end

-- load all templates from the given language 
function sandbox_core_project_template.templates(language)

    -- get it 
    local templates = template.templates(language)
    assert(templates)

    -- ok
    return templates
end

-- create project from template
function sandbox_core_project_template.create(language, templateid, targetname)

    -- create it
    local ok, errors = template.create(language, templateid, targetname)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_project_template
