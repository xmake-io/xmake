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
-- @file        _run.lua
--

-- define module: _run
local _run = _run or {}

-- load modules
local rule      = require("base/rule")
local path      = require("base/path")
local utils     = require("base/utils")
local config    = require("base/config")
local project   = require("base/project")
local platform  = require("base/platform")
    
-- need access to the given file?
function _run.need(name)

    -- check
    assert(name)

    -- the accessors
    local accessors = { config = true, global = true, project = true, platform = true }

    -- need it?
    return accessors[name]
end

-- done 
function _run.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options and xmake._PROJECT_DIR)

    -- the target name
    local name = options.target
    if not name then
        -- error
        utils.error("no runable target!")
        return false
    end

    -- the arguments
    local arguments = options.arguments or {}
    if type(arguments) ~= "table" then
        arguments = {}
    end

    -- the targets
    local targets = project.targets()
    if not targets or not targets[name] then
        -- error
        utils.error("not found target: %s!", name)
        return false
    end

    -- the target
    local target = targets[name]

    -- the target file
    local targetfile = rule.targetfile(name, target)
    if targetfile and not path.is_absolute(targetfile) then
        targetfile = path.absolute(targetfile, xmake._PROJECT_DIR)
    end

    -- load the run script
    local runscript = target.runscript
    if type(runscript) == "string" and os.isfile(runscript) then
        local script, errors = loadfile(runscript)
        if script then
            runscript = script()
            if type(runscript) == "table" and runscript.main then 
                runscript = runscript.main
            end
        else
            utils.error(errors)
            return false
        end
    end

    -- run script
    if runscript ~= nil then
        if type(runscript) == "function" then
            
            -- make passed target 
            local target_passed         = {}
            target_passed.name          = name
            target_passed.arguments     = arguments
            target_passed.targetfile    = targetfile

            -- run it
            local ok = runscript(target_passed)
            if ok ~= 0 then return utils.ifelse(ok == 1, true, false) end
        else
            utils.error("invalid run script!")
            return false
        end
    end

    -- not executale?
    if not target.kind or type(target.kind) ~= "string" or target.kind ~= "binary" then
        -- error
        utils.error("the target %s is not executale!", name)
        return false
    end

    -- check the target file
    if not targetfile and not os.isfile(targetfile) then
        -- error
        utils.error("not found target file: %s!", targetfile)
        return false
    end

    -- done 
    local ok = os.execute(string.format("%s %s", targetfile, table.concat(arguments, " ")))

    -- ok?
    return utils.ifelse(ok == 0, true, false)
end

-- the menu
function _run.menu()
 
    return {
                -- xmake r
                shortname = 'r'

                -- usage
            ,   usage = "xmake run|r [options] [target] [arguments]"

                -- description
            ,   description = "Run the project target."

                -- options
            ,   options = 
                {
                    {'d', "debug",      "k",  nil,          "Run and debug the given target."                               }
                ,   {nil, "debugger",   "kv", "auto",       "Set the debugger path."                                        }

                ,   {}
                ,   {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
                ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                          , "Search priority:"
                                                          , "    1. The Given Command Argument"
                                                          , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                          , "    3. The Current Directory"                                  }
                ,   {}
                ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
                ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
                ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
                
                ,   {}
                ,   {nil, "target",     "v",  nil,          "Run the given target."                                         }      
                ,   {nil, "arguments",  "vs",  nil,         "The target arguments"                                          }
                }
            }
end

-- return module: _run
return _run
