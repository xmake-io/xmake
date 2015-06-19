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
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")

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

    -- load all templates
    local modules = {}
    local templates = os.match(string.format("%s/%s/**/_template.lua", xmake._TEMPLATES_DIR, language))
    if templates then
        for _, t in ipairs(templates) do
            local script = assert(loadfile(t))
            if script then
                local module = script()
                if module then 
                    module._DIRECTORY = path.directory(t)
                    table.insert(modules, module)
                end
            end
        end
    end

    -- ok?
    return modules
end


-- return module: template
return template
