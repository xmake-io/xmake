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
-- @file        _package.lua
--

-- define module: _package
local _package = _package or {}

-- load modules
local rule      = require("base/rule")
local utils     = require("base/utils")
local config    = require("base/config")
local global    = require("base/global")
local string    = require("base/string")
local project   = require("base/project")
local platform  = require("platform/platform")
    
-- need access to the given file?
function _package.need(name)

    -- no accessors
    return false
end
 
-- configure target for the given architecture
function _package._config(arch, target_name)

    -- need not configure it
    if not arch then return true end

    -- done the command
    return os.execute(string.format("xmake f -P %s -f %s -a %s %s", xmake._PROJECT_DIR, xmake._PROJECT_FILE, arch, target_name)) == 0;
end

-- build target for the given architecture
function _package._build(arch, target_name)

    -- get the target name
    if not target_name or target_name == "all" then 
        target_name = ""
    end

    -- configure it first
    if not _package._config(arch, target_name) then return false end

    -- rebuild it
    if os.execute(string.format("xmake -r -P %s %s", xmake._PROJECT_DIR, target_name)) ~= 0 then 
        -- errors
        utils.error("build %s failed!", utils.ifelse(target_name, target_name, "all"))
        return false 
    end

    -- ok
    return true
end

-- make configure for the given target 
function _package._makeconf(target_name, target)

    -- check
    assert(target_name and target)

    -- the configs
    local configs = _package._CONFIGS
    assert(configs)

    -- the architecture 
    local arch = config.get("arch")
    if not arch then return false end

    -- init configs for targets
    configs._TARGETS = configs._TARGETS or {}
    configs._TARGETS[target_name] = configs._TARGETS[target_name] or {}
    local configs_target = configs._TARGETS[target_name]

    -- init configs for architecture
    configs_target[arch] = configs_target[arch] or {}
    local configs_arch = configs_target[arch]

    -- save the target kind
    configs_arch.kind = target.kind

    -- save the config file
    configs_arch.config_h = rule.config_h(target)

    -- save the target file
    configs_arch.targetfile = rule.targetfile(target_name, target)

    -- save the header files
    configs_arch.headerfiles = rule.headerfiles(target)

    -- ok
    return true
end

-- load configure for the given target 
function _package._loadconf(target_name)

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

    -- the targets
    local targets = project.targets()
    assert(targets)

    -- make configure for the given target
    if target_name and target_name ~= "all" then
        if not _package._makeconf(target_name, targets[target_name]) then 
            utils.error("make target configure: %s failed!", target_name)
            return false
        end
    else
        for target_name, target in pairs(targets) do
            if not _package._makeconf(target_name, target) then 
                utils.error("make target configure: %s failed!", target_name)
                return false
            end
        end
    end

    -- ok
    return true
end

-- build target for all architectures
function _package._build_all(archs, target_name)

    -- exists the given architectures?
    if archs then
    
        -- split all architectures
        archs = archs:split(",")
        if not archs then return false end

        -- build for all architectures
        for _, arch in ipairs(archs) do

            -- trim it
            arch = arch:trim()

            -- build it
            if not _package._build(arch, target_name) then return false end

            -- load configure
            if not _package._loadconf(target_name) then return false end

        end

    -- build for single architecture
    else

        -- build it
        if not _package._build(nil, target_name) then return false end

        -- load configure
        if not _package._loadconf(target_name) then return false end

    end

    -- ok
    return true
end

-- done package from the configure
function _package._done()

    -- the configs
    local configs = _package._CONFIGS
    assert(configs)

    -- dump
    utils.dump(configs)
 
    -- ok
    return true
end

-- done 
function _package.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- trace
    print("package: ...")

    -- init configs
    _package._CONFIGS = _package._CONFIGS or {}
    local configs = _package._CONFIGS

    -- load the global configure first
    global.load()

    -- build the given target first for all architectures
    if not _package._build_all(options.archs, options.target) then
        -- errors
        utils.error("build package failed!")
        return false
    end

    -- save platform
    configs.plat = config.get("plat")
    assert(configs.plat)

    -- save build directory
    configs.buildir = config.get("buildir")

    -- save project directory
    configs.projectdir = xmake._PROJECT_DIR

    -- done package 
    if not _package._done() then
        -- errors
        utils.error("package: failed!")
        return false
    end

    -- trace
    print("package: ok!")

    -- ok
    return true
end

-- the menu
function _package.menu()

    return {
                -- xmake p
                shortname = 'p'

                -- usage
            ,   usage = "xmake package|p [options] [target]"

                -- description
            ,   description = "Package target."

                -- options
            ,   options = 
                {
                    {'a', "archs",      "kv", nil,          "Package multiple given architectures."                             
                                                          , "    .e.g --archs=\"armv7, arm64\" or -a i386"
                                                          , ""
                                                          , function () 
                                                              local descriptions = {}
                                                              local plats = platform.plats()
                                                              if plats then
                                                                  for i, plat in ipairs(plats) do
                                                                      descriptions[i] = "    - " .. plat .. ":"
                                                                      local archs = platform.archs(plat)
                                                                      if archs then
                                                                          for _, arch in ipairs(archs) do
                                                                              descriptions[i] = descriptions[i] .. " " .. arch
                                                                          end
                                                                      end
                                                                  end
                                                              end
                                                              return descriptions
                                                            end                                                             }

                ,   {}
                ,   {'f', "file",       "kv", "xmake.lua",  "Create a given xmake.lua file."                                }
                ,   {'P', "project",    "kv", nil,          "Create from the given project directory."
                                                          , "Search priority:"
                                                          , "    1. The Given Command Argument"
                                                          , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                          , "    3. The Current Directory"                                  }

                ,   {}
                ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
                ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
                ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
         
                ,   {}
                ,   {nil, "target",     "v",  "all",        "Package a given target"                                        }   
                }
            }
end

-- return module: _package
return _package
