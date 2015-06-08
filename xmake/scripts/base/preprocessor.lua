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

-- load modules
local utils = require("base/utils")

-- filter value
function preprocessor._filter(env, value, filter)

    -- the value is string?
    if type(value) == "string" then

        -- init
        local _v = nil
        local _n = 0

        -- replace it for filter
        if filter then
            -- replace $(variable)
            _v, _n = value:gsub("%$%((.*)%)", function (v) return filter(env, v) end)
        end

        -- replace it for script
        if _n == 0 then
            _v, _n = value:gsub("%[(.*)%]",     function (v) 

                                                    -- load the script
                                                    local script = assert(loadstring("return " .. v))

                                                    -- bind the envirnoment
                                                    setfenv(script, env)

                                                    -- done it
                                                    local ok, result = pcall(script)
                                                    if not ok then return end

                                                    -- ok?
                                                    return result or ""
                                                end)
        end

        -- update value
        value = _v
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

            -- init the configure entry
            _current[name] = _current[name] or {}

            -- get arguments
            local arg = arg or {...}
            if table.getn(arg) == 0 then
                -- no argument
                _current[name] = nil
            else
                -- save all arguments
                for _, v in ipairs(arg) do
                    v = preprocessor._filter(env, v, filter)
                    if v and type(v) == "string" and #v ~= 0 then
                        table.insert(_current[name], v)
                    end
                end
            end
        end
    end
end

-- init configures
function preprocessor._init(root, configures, scopes, filter, import)

    -- check
    assert(root and configures)

    -- enter new environment 
    local newenv = {}
    local oldenv = getfenv()
    setmetatable(newenv, {  __index =   function(tbl, key)
                                            -- private configure entry? we can get it directly and need not register it
                                            if key and type(key) == "string" and key:startswith("__") then

                                                return function(...)

                                                    -- check
                                                    local _current = newenv._current
                                                    assert(_current)

                                                    -- init the configure entry
                                                    _current[key] = _current[key] or {}

                                                    -- get arguments
                                                    local arg = arg or {...}
                                                    if table.getn(arg) == 0 then
                                                        -- no argument
                                                        _current[key] = nil
                                                    elseif table.getn(arg) == 1 then
                                                        -- save only one argument
                                                        _current[key] = arg[1]
                                                    else
                                                        -- save all arguments
                                                        for i, v in ipairs(arg) do
                                                            _current[key][i] = v
                                                        end
                                                    end
                                                end
                                            end

                                            -- get it from the global table
                                            return rawget(_G, key)
                                        end})  
    setfenv(1, newenv)

    -- register all configures
    preprocessor._register(newenv, configures, filter)

    -- configure import
    if import then
        newenv["import"] = import
    end

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
-- local configs, errors = preprocessor.loadfile("xmake.xproj", "project", {"links", "files", "ldflags", ...}, {"target", "platforms"}, filter, import)
-- @endcode
function preprocessor.loadfile(path, root, configures, scopes, filter, import)

    -- check
    assert(path and root and configures)

    -- load and execute the configure file
    local script = preprocessor.loadx(path)
    if script then

        -- init a new envirnoment
        local newenv = preprocessor._init(root, configures, scopes, filter, import)
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
        return newenv
    else
        -- error
        return nil, string.format("load %s failed!", path)
    end
end

-- return module: preprocessor
return preprocessor
