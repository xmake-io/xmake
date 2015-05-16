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
-- @file        preprocessor.lua
--

-- define module: preprocessor
local preprocessor = preprocessor or {}

-- filter value
function preprocessor._filter(value, filter)

    -- the value is string?
    if filter and type(value) == "string" then

        -- replace $(variable)
        value = value:gsub("%$%((.*)%)", filter)
    end

    -- ok
    return value
end

-- register configures
function preprocessor._register(env, names, filter)

    -- check
    assert(env and names and type(names) == "table")
    assert(not filter or type(filter) == "function")

    -- register all configures
    for _, name in ipairs(names) do

        -- register the configure 
        env[name] = env[name] or function(...)

            -- check
            local _current = env._current
            assert(_current)

            -- init ldflags
            _current[name] = _current[name] or {}

            -- get arguments
            local arg = arg or {...}
            if table.getn(arg) == 0 then
                -- no argument
                _current[name] = nil
            elseif table.getn(arg) == 1 then
                -- save only one argument
                _current[name] = preprocessor._filter(arg[1], filter)
            else
                -- save all arguments
                for i, v in ipairs(arg) do
                    _current[name][i] = preprocessor._filter(v, filter)
                end
            end
        end
    end
end

-- init configures
function preprocessor._init(root, configures, scopes, filter)

    -- check
    assert(root and configures)

    -- enter new environment 
    local newenv = {}
    local oldenv = getfenv()
    setmetatable(newenv, {__index = _G})  
    setfenv(1, newenv)

    -- register all configures
    preprocessor._register(newenv, configures, filter)

    -- configure scope end
    newenv["_end"] = function ()

        -- check
        assert(_current)

        -- leave the current scope
        _current = _current._PARENT
    end

    -- configure scopes
    if scopes then
        for _, scope_name in ipairs(scopes) do
                
            newenv[scope_name] = function (...)

                -- check
                assert(_current)

                -- init config name
                local config_name = "_" .. scope_name:upper()

                -- init scope config
                _current[config_name] = _current[config_name] or {}
                local scope_config = _current[config_name]

                -- init scope
                local scope = {}

                -- configure all 
                local arg = arg or {...}
                for _, name in ipairs(arg) do

                    -- check
                    if scope_config[name] then
                        -- error
                        utils.error("the %s: %s has been defined repeatly!", config_name, name)
                        assert(false) 
                    end

                    -- init the scope
                    scope_config[name] = scope

                end

                -- enter scope
                local parent = _current
                _current = scope
                _current._PARENT = parent
            end
        end
    end

    -- the root configure 
    newenv[root] = function ()

        -- init the root scope, must be only one configs
        if not newenv._CONFIGS then
            newenv._CONFIGS = {}
        else
            -- error
            utils.error("exists double %s!", root)
            return
        end

        -- init the current scope
        _current = newenv._CONFIGS
        _current._PARENT = nil
    end

    -- enter old environment 
    setfenv(1, oldenv)
    return newenv
end
 
--!load the configure file
--
-- supports:
--     xmake.xproj
--     xmake.xconf
--
-- @code
-- local configs, errors = preprocessor.loadfile("xmake.xconf", "config", {"plat", "host", "arch", ...}, {"target"})
-- local configs, errors = preprocessor.loadfile("xmake.xproj", "project", {"links", "files", "ldflags", ...}, {"target", "platforms"}, filter)
-- @endcode
function preprocessor.loadfile(path, root, configures, scopes, filter)

    -- check
    assert(path and root and configures)

    -- load and execute the configure file
    local script = preprocessor.loadx(path)
    if script then

        -- init a new envirnoment
        local newenv = preprocessor._init(root, configures, scopes, filter)
        assert(newenv)

        -- bind this envirnoment
        setfenv(script, newenv)

        -- execute it
        local ok, err = pcall(script)
        if not ok then
            -- error
            return nil, err
        end

        -- ok?
        return newenv._CONFIGS
    else
        -- error
        return nil, string.format("load %s failed!", path)
    end
end

-- return module: preprocessor
return preprocessor
