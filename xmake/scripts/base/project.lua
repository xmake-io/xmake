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

-- make the given configure to scope
function project._make_configs(scope, configs)

    -- check
    assert(configs)

    -- the current mode
    local mode = config.get("mode")
    assert(mode)

    -- the current platform
    local plat = config.get("plat")
    assert(plat)

    -- done
    for k, v in pairs(configs) do
        
        -- check
        assert(type(k) == "string")

        -- enter the target configure?
        if k == "_TARGET" then
 
            -- the current 
            local current = project._CURRENT

            -- init all targets
            for _k, _v in pairs(v) do

                -- init target scope first
                current[_k] = current[_k] or {}

                -- make the target configure to this scope
                project._make_configs(current[_k], _v)
            end

        -- enter the platform configure?
        elseif k == "_PLATFORMS" then

            -- append configure to scope for the current mode
            for _k, _v in pairs(v) do
                if _k == plat then
                    project._make_configs(scope, _v)
                end
            end

        -- enter the mode configure?
        elseif k == "_MODES" then

            -- append configure to scope for the current mode
            for _k, _v in pairs(v) do
                if _k == mode then
                    project._make_configs(scope, _v)
                end
            end

        -- append configure to scope
        elseif scope and not k:startswith("_") and k:endswith("s") then

            -- wrap it first
            local values = utils.wrap(v)

            -- append all 
            for _, _v in ipairs(values) do

                -- the configure item
                scope[k] = scope[k] or {}
                local item = scope[k]

                -- append it
                item[table.getn(item) + 1] = _v
            end
        -- replace configure to scope
        elseif scope and not k:startswith("_") then
            
            -- wrap it first
            local values = utils.wrap(v)
            if table.getn(values) == 1 then

                -- the configure item
                scope[k] = scope[k] or {}
                local item = scope[k]

                -- replace it
                item[1] = values[1]
            end
        end
    end
end

-- make the current project configure
function project._make()

    -- the configs
    local configs = project._CONFIGS
    assert(configs)
  
    -- init current
    project._CURRENT = project._CURRENT or {}

    -- make the root configure to the current scope
    project._make_configs(nil, configs)

    -- remove repeat values and unwrap it
    for _, target in pairs(project._CURRENT) do
        for k, v in pairs(target) do

            -- remove repeat first
            v = utils.unique(v)

            -- unwrap it if be only one
            v = utils.unwrap(v)

            -- update it
            target[k] = v
        end
    end
end

-- get the current configure for targets
function project.targets()

    -- check
    assert(project._CURRENT)

    -- return it
    return project._CURRENT
end

-- load xproj
function project.loadxproj(file)

    -- check
    assert(file)

    -- init configures
    local configures = {    "kind"
                        ,   "deps"
                        ,   "files"
                        ,   "links" 
                        ,   "headers" 
                        ,   "headerdir" 
                        ,   "targetdir" 
                        ,   "objectdir" 
                        ,   "linkdirs" 
                        ,   "includedirs" 
                        ,   "cflags" 
                        ,   "cxflags" 
                        ,   "cxxflags" 
                        ,   "mflags" 
                        ,   "mxflags" 
                        ,   "mxxflags" 
                        ,   "ldflags" 
                        ,   "shflags" 
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
    local newenv, errors = preprocessor.loadfile(file, "project", configures, {"target", "platforms", "modes"}, filter, import)
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

    -- make the current project configure
    project._make()

end

-- dump the current configure
function project.dump()
    
    -- check
    assert(project._CURRENT)

    -- dump
    if xmake._OPTIONS.verbose then
        utils.dump(project._CURRENT)
    end
   
end

-- return module: project
return project
