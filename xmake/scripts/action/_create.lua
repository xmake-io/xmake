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
-- @file        _create.lua
--

-- define module: _create
local _create = _create or {}

-- load modules
local utils     = require("base/utils")
local template  = require("base/template")
    
-- need access to the given file?
function _create.need(name)

    -- no accessors
    return false
end

-- done 
function _create.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- the target name
    local targetname = options.target or options.name or path.basename(xmake._PROJECT_DIR) or "demo"

    -- trace
    utils.printf("create %s ...", targetname)

    -- the language
    local language = options.language 
    if not language then
        utils.error("no language!")
        return false
    end

    -- the template id
    local templateid = tonumber(options.template)
    if type(templateid) ~= "number" then
        utils.error("invalid template id: %s!", options.template)
        return false
    end

    -- load all templates for the given language
    local templates = template.loadall(language)

    -- load the template module
    local module = nil
    if templates then module = templates[templateid] end
    if not module then
        utils.error("invalid template id: %s!", options.template)
        return false
    end

    -- enter the template directory
    if not module._DIRECTORY or not os.cd(module._DIRECTORY) then
        -- error
        utils.error("not found template id: %s!", options.template)
        return false
    end

    -- check the template project
    if not os.isdir("project") then
        -- errors
        utils.error("the template project not exists!")
        return false
    end

    -- ensure the project directory 
    if not os.isdir(xmake._PROJECT_DIR) then 
        os.mkdir(xmake._PROJECT_DIR)
    end

    -- copy the project files
    local ok, errors = os.cp("project/*", xmake._PROJECT_DIR) 
    if not ok then
        -- errors
        utils.error(errors)
        return false
    end

    -- done the template files
    if not module.done(targetname, xmake._PROJECT_DIR, xmake._PACKAGES_DIR) then
        utils.error("update the template failed!")
        return false
    end

    -- trace
    utils.printf("create %s ok!", targetname)

    -- ok
    return true
end

-- the menu
function _create.menu()

    return {
                -- usage
                usage = "xmake create [options] [target]"

                -- description
            ,   description = "Create a new project."

                -- options
            ,   options = 
                {
                    {'n', "name",       "kv", nil,          "The project name."                                             }
                ,   {'f', "file",       "kv", "xmake.lua",  "Create a given xmake.lua file."                                }
                ,   {'P', "project",    "kv", nil,          "Create from the given project directory."
                                                          , "Search priority:"
                                                          , "    1. The Given Command Argument"
                                                          , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                          , "    3. The Current Directory"                                  }
                ,   {'l', "language",   "kv", "c",          "The project language"
                                                          , function ()
                                                                local descriptions = {}
                                                                local languages = template.languages()
                                                                for _, language in ipairs(languages) do
                                                                    table.insert(descriptions, "    - " .. language)
                                                                end
                                                                return descriptions
                                                            end                                                             }
                ,   {'t', "template",   "kv", "1",          "Select the project template id of the given language."
                                                          , function ()
                                                                local descriptions = {}
                                                                local languages = template.languages()
                                                                for _, language in ipairs(languages) do
                                                                    table.insert(descriptions, string.format("    - language: %s", language))
                                                                    local templates = template.loadall(language)
                                                                    if templates then
                                                                        for i, template in ipairs(templates) do
                                                                            table.insert(descriptions, string.format("      %d. %s", i, utils.ifelse(template.description, template.description, "The Unknown Project")))
                                                                        end
                                                                    end
                                                                end
                                                                return descriptions
                                                            end                                                             }

                ,   {}
                ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
                ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
                ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
         
                ,   {}
                ,   {nil, "target",     "v",  nil,          "Create the given target."                     
                                                          , "Uses the project name as target if not exists."                }
                }
            }
end

-- return module: _create
return _create
