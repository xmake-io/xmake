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
-- @file        config.lua
--

-- load modules
local io        = require("base/io")
local utils     = require("base/utils")
local option    = require("base/option")

-- enter config 
local _CONFIG = _CONFIG or {}
local _MAINENV = getfenv()
setmetatable(_CONFIG, {__index = _G})  
setfenv(1, _CONFIG)

-- init the current scope
local current = nil

-- configure scope end
function _end()

    -- check
    assert(current)

    -- leave the current scope
    current = current._PARENT
end

-- auto configs
function _auto(name)

    -- get platform or host
    if name == "plat" or name == "host" then
        return xmake._HOST
    -- get architecture
    elseif name == "arch" then
        return xmake._ARCH
    end

    -- unknown
    utils.error("unknown config: %s", name)
    return "unknown"
end

-- register configures
function _register(names)

    -- check
    assert(_CONFIG)
    assert(names and type(names) == "table")

    -- register all configures
    for _, name in ipairs(names) do

        -- register the configure 
        _CONFIG[name] = _CONFIG[name] or function(...)

            -- check
            assert(current)

            -- init ldflags
            current[name] = current[name] or {}

            -- get arguments
            local arg = arg or {...}
            if table.getn(arg) == 0 then
                -- no argument
                current[name] = nil
            elseif table.getn(arg) == 1 then
                -- save only one argument
                current[name] = arg[1]
            else
                -- save all arguments
                for i, v in ipairs(arg) do
                    current[name][i] = v
                end
            end
        end
    end
end

-- init configures
function _init()

    -- check
    assert(option._MENU)
    assert(option._MENU.config)

    -- get all configures name
    local i = 1
    local configures = {}
    for _, o in ipairs(option._MENU.config.options) do
        local name = o[2]
        if name and name ~= "target" and name ~= "file" and name ~= "project" and name ~= "verbose" then
            configures[i] = name
            i = i + 1
        end
    end

    -- register all configures
    _register(configures)

end

-- save object with the level
function _save_with_level(file, object, level)
 
    -- check
    assert(object)

    -- save string
    if type(object) == "string" then  
        file:write(object) 
    -- save boolean
    elseif type(object) == "boolean" then  
        file:write(tostring(object))  
    -- save number 
    elseif type(object) == "number" then  
        file:write(object)  
    -- save function 
    elseif type(object) == "function" then  
        file:write("<function>")  
    -- save table
    elseif type(object) == "table" then  

        -- save head
        file:write(utils.ifelse(level == 0, "config:\n", "\n"))
        for l = 1, level do
            file:write("    ")
        end
        file:write("{\n")  

        -- save body
        for k, v in pairs(object) do  

            -- save _TARGETS
            if type(k) == "string" and k == "_TARGETS" then

                for _k, _v in pairs(v) do  

                    -- save spaces
                    for l = 0, level do
                        file:write("    ")
                    end

                    -- save key
                    file:write("target: ", _k)  

                    -- save value
                    if not _save_with_level(file, _v, level + 1) then 
                        return false
                    end

                    -- save newline
                    file:write("\n")
                end

            -- exclude _PARENT
            elseif type(k) ~= "string" or k ~= "_PARENT" then

                -- save spaces
                for l = 0, level do
                    file:write("    ")
                end

                -- save key
                if type(k) == "string" then
                    file:write(k, ": ")  
                end

                -- save value
                if not _save_with_level(file, v, level + 1) then 
                    return false
                end

                -- save newline
                file:write("\n")
            end
        end  

        -- save tail
        for l = 1, level do
            file:write("    ")
        end
        file:write("}\n")  
    else  
        -- error
        utils.error("invalid object type: %s", type(object))
        return false
    end  

    -- ok
    return true
end

-- save object
function _save(file, object)

    -- save it
    return _save_with_level(file, object, 0)
end

-- configure target
function target(name)

    -- check
    assert(name and current)

    -- init targets
    current._TARGETS = current._TARGETS or {}

    -- init target scope
    current._TARGETS[name] = {}

    -- enter target scope
    local parent = current
    current = current._TARGETS[name]
    current._PARENT = parent
end

-- the root configure 
function config()

    -- init the root scope, must be only one configs
    if not _CONFIGS then
        _CONFIGS = {}
    else
        -- error
        utils.error("exists double configs!")
        return
    end

    -- init the current scope
    current = _CONFIGS
    current._PARENT = nil

end

-- get the current target scope
function getarget()

    -- check
    assert(_CONFIGS)
    
    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- the target name
    local name = options.target or options._DEFAULTS.target
    assert(name and type(name) == "string")

    -- for all targets?
    if name == "all" then
        return _CONFIGS
    else
        -- init it if not exists
        _CONFIGS._TARGETS = _CONFIGS._TARGETS or {}
        _CONFIGS._TARGETS[name] = _CONFIGS._TARGETS[name] or {}

        -- get it
        return _CONFIGS._TARGETS[name]
    end
end

-- save xmake.xconf
function savexconf()
    
    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- open the configure file
    local path = options.project .. "/xmake.xconf"
    local file = io.open(path, "w")
    if not file then
        -- error
        utils.error("open %s failed!", path)
        return false
    end

    -- save configs to file
    if not _save(file, _CONFIGS) then
        -- error 
        utils.error("save %s failed!", path)
        file:close()
        return false
    end

    -- close file
    file:close()
   
    -- ok
    return true
end
 
-- load xmake.xconf
function loadxconf()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- load and execute the xmake.xproj
    local path = options.project .. "/xmake.xconf"
    local script = preprocessor.loadx(path)
    if script then

        -- init the configs envirnoment
        _CONFIG._init()
        setfenv(script, _CONFIG)

        -- execute it
        local ok, err = pcall(script)
        if not ok then
            -- error
            return err
        end
    end

    -- exists local configures?
    if _CONFIGS then

        -- clear configs if the host environment has been changed
        local target = getarget()
        if target and target.host ~= xmake._HOST then
            _CONFIGS = {}
        end
    end

    -- the target name
    local name = options.target or options._DEFAULTS.target
    assert(name and type(name) == "string")

    -- ensures the configs
    _CONFIGS = _CONFIGS or {}

    -- get the current target scope
    local target = getarget()
    assert(target and type(target) == "table")

    -- merge xmake._OPTIONS to target
    for k, v in pairs(options) do

        -- check
        assert(type(k) == "string")

        -- skip some options
        if not k:startswith("_") and k ~= "project" and k ~= "file" and k ~= "verbose" and k ~= "target" then

            -- save the option to the target
            target[k] = v
        end
    end

    -- merge xmake._OPTIONS._DEFAULTS to target
    for k, v in pairs(options._DEFAULTS) do

        -- check
        assert(type(k) == "string")

        -- skip some options
        if k ~= "project" and k ~= "file" and k ~= "verbose" and k ~= "target" then

            -- save the default option to the target
            if not target[k] then

                if v == "auto" then 
                    target[k] = _auto(k)
                else
                    target[k] = v
                end
            end
        end
    end

    -- ok
    return nil
end

-- dump configs
function dump()
    
    -- check
    assert(_CONFIGS)

    -- dump
    if xmake._OPTIONS.verbose then
        utils.dump(_CONFIGS, "_PARENT")
    end
   
end

-- leave configs 
setfenv(1, _MAINENV)
return _CONFIG
