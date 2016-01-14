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
-- @file        _lua.lua
--

-- define module: _lua
local _lua = _lua or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local config    = require("base/config")
local string    = require("base/string")
local tools     = require("tools/tools")
local platform  = require("base/platform")
   
-- need access to the given file?
function _lua.need(name)
    
    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- do not load config if be not given -f or -P options
    if options.file == nil and options.project == nil then
        return false
    end

    -- patch target for loading config ok
    options.target = "all"

    -- the accessors
    local accessors = { config = true, global = true, platform = true }

    -- need it?
    return accessors[name]
end

-- done 
function _lua.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- no script?
    if not options.script then
        return false
    end

    -- the arguments
    local arguments = options.arguments or {}
    if type(arguments) ~= "table" then
        arguments = {}
    end

    -- is string script? 
    if options.string then

        -- trace
        utils.verbose("script: %s", options.script)

        -- load and run string
        local script = loadstring(options.script)
        if script then
            return script(arguments)
        end
    else
        -- attempt to load script from the given file if exists
        local file = options.script
        if not path.is_absolute(file) then
            file = path.absolute(file)
        end

        -- attempt to load script from the tools directory
        if not os.isfile(file) then
            file = tools.find(options.script, xmake._CORE_DIR .. "/tools")
        end

        -- load and run the script file
        if os.isfile(file) then

            -- load script
            local script = loadfile(file)
            if script then

                -- load module
                local module = script()
                if module then

                    -- init module 
                    if module.init then
                        module:init(options.script)
                    end

                    -- done module 
                    return module:main(arguments)
                end
            end
        end
    end
 
    -- failed
    utils.error("cannot run this script: %s", options.script)
    return false
end

-- the menu
function _lua.menu()

    return {
                -- xmake l
                shortname = 'l'

                -- usage
            ,   usage = "xmake lua|l [options] [script] [arguments]"

                -- description
            ,   description = "Run the lua script."

                -- options
            ,   options = 
                {
                    {'f', "file",       "kv", nil,          "Read a given xmake.lua file."                                  }
                ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                          , "Search priority:"
                                                          , "    1. The Given Command Argument"
                                                          , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                          , "    3. The Current Directory"                                  }

                ,   {}
                ,   {'s', "string",     "k",  nil,          "Run the lua string script."                                    }

                ,   {}
                ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
                ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
                ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
                
                ,   {}
                ,   {nil, "script",     "v",  nil,          "Run the given lua script."
                                                          , "    - The script name from the xmake tool directory"
                                                          , "    - The script file"
                                                          , "    - The script string"                                       }      
                ,   {nil, "arguments",  "vs", nil,          "The script arguments"                                          }
                }
            }
end

-- return module: _lua
return _lua
