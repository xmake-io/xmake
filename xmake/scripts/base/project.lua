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
-- @file        project.lua
--

-- define module: config
local project = project or {}

-- load modules
local utils         = require("base/utils")
local config        = require("base/config")
local preprocessor  = require("base/preprocessor")

-- load xproj
function project.loadxproj(file)

    -- check
    assert(file)

    -- init configures
    local configures = {   "kind"
                        ,   "deps"
                        ,   "files"
                        ,   "links" 
                        ,   "mflags" 
                        ,   "headers" 
                        ,   "headerdir" 
                        ,   "targetdir" 
                        ,   "objectdir" 
                        ,   "linkdirs" 
                        ,   "includedirs" 
                        ,   "cflags" 
                        ,   "cxxflags" 
                        ,   "ldflags" 
                        ,   "mxflags" 
                        ,   "defines"} 

    -- init filter
    local filter =  function (v) 
                        if v == "buildir" then
                            return config.get("buildir")
                        elseif v == "projectdir" then
                            return xmake._PROJECT_DIR
                        end
                        return v 
                    end

    -- init import 
    local import = function (name)

        -- import configs?
        if name == "configs" then

            -- init configs
            local configs = {}

            -- get the config for the current target
            for k, v in pairs(config._CURRENT) do
                configs[k] = v
            end

            -- init the project directory
            configs.projectdir = xmake._OPTIONS.project

            -- import it
            return configs
        end

    end

    -- load and execute the xmake.xproj
    local newenv, errors = preprocessor.loadfile(file, "project", configures, {"target", "platforms"}, filter, import)
    if newenv and newenv._CONFIGS then
        -- ok
        project._CONFIGS = newenv._CONFIGS
    elseif errors then
        -- error
        return errors
    else
        -- error
        return string.format("load %s failed!", file)
    end

end

-- dump configs
function project.dump()
    
    -- check
    assert(project._CONFIGS)

    -- dump
    if xmake._OPTIONS.verbose then
        utils.dump(project._CONFIGS, "_PARENT")
    end
   
end

-- return module: project
return project
