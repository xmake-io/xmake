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
-- @file        _install.lua
--

-- define module: _install
local _install = _install or {}

-- load modules
local utils     = require("base/utils")
local config    = require("base/config")
local global    = require("base/global")
local install   = require("base/install")
local package   = require("base/package")
local project   = require("base/project")
local platform  = require("base/platform")
     
-- need access to the given file?
function _install.need(name)

    -- no accessors
    return false
end

-- make configure for the given target 
function _install._makeconf(configs, target_name, target)

    -- check
    assert(configs and target_name and target)

    -- init configs for targets
    configs[target_name] = configs[target_name] or {}
    local configs_target = configs[target_name]

    -- save the install script
    local installscript = target.installscript
    if type(installscript) == "string" and os.isfile(installscript) then
        local script, errors = loadfile(installscript)
        if script then
            installscript = script()
            if type(installscript) == "table" and installscript.main then 
                installscript = installscript.main
            end
        else
            utils.error(errors)
            return false
        end
    end
    if target.installscript and type(installscript) ~= "function" then
        utils.error("invalid install script!")
        return false
    end
    configs_target.installscript = installscript

    -- ok
    return true
end

-- package target
function _install._package(target_name)

    -- get the target name
    if not target_name or target_name == "all" then 
        target_name = ""
    end

    -- package it
    if os.execute(string.format("xmake p -P %s -f %s %s", xmake._PROJECT_DIR, xmake._PROJECT_FILE, target_name)) ~= 0 then 
        return false 
    end

    -- ok
    return true
end
 
-- done 
function _install.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- trace
    print("install: ...")

    -- load the global configure first
    global.load()

    -- enter the project directory
    if not os.cd(xmake._PROJECT_DIR) then
        -- errors
        utils.error("not found project: %s!", xmake._PROJECT_DIR)
        return false
    end

    -- package the given target first 
    if not _install._package(options.target) then
        -- errors
        utils.error("package: failed!")
        return false
    end

    -- load the package configure
    local configs, errors = package.load()
    if not configs then
        -- errors
        utils.error(errors)
        return false
    end

    -- reload configure
    local errors = config.reload()
    if errors then
        -- error
        utils.error(errors)
        return false
    end

    -- make the platform configure
    if not platform.make() then
        utils.error("make platform configure: %s failed!", config.get("plat"))
        return false
    end

    -- reload project
    local errors = project.reload()
    if errors then
        -- error
        utils.error(errors)
        return false
    end

    -- update the outputdir
    for _, target in pairs(configs) do
        target.outputdir = options.installdir 
    end

    -- the targets
    local targets = project.targets()
    assert(targets)

    -- make configure for the given target
    if target_name and target_name ~= "all" then
        if not _install._makeconf(configs, target_name, targets[target_name]) then 
            utils.error("make target configure: %s failed!", target_name)
            return false
        end
    else
        for target_name, target in pairs(targets) do
            if not _install._makeconf(configs, target_name, target) then 
                utils.error("make target configure: %s failed!", target_name)
                return false
            end
        end
    end

    -- done install 
    if not install.done(configs) then
        -- errors
        utils.error("install: failed!")
        return false
    end

    -- trace
    print("install: ok!")

    -- ok
    return true
end

-- the menu
function _install.menu()

    return {
                -- xmake i
                shortname = 'i'

                -- usage
            ,   usage = "xmake install|i [options] [target]"

                -- description
            ,   description = "Package and install the project binary files."

                -- options
            ,   options = 
                {
                    {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
                ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                          , "Search priority:"
                                                          , "    1. The Given Command Argument"
                                                          , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                          , "    3. The Current Directory"                                  }
                ,   {'o', "installdir",  "kv", nil,         "Set the install directory."                                    }

                ,   {}
                ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
                ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
                ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
         
                ,   {}
                ,   {nil, "target",     "v",  "all",        "Install the given target."                                     }
                }
        }
end

-- return module: _install
return _install
