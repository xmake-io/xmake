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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        sandbox.lua
--

-- define module: sandbox
local sandbox = sandbox or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")

-- traceback
function sandbox._traceback(errors)

    -- init results
    local results = ""
    if errors then
        results = errors .. "\n"
    end
    results = results .. "stack traceback:\n"

    -- make results
    local level = 2    
    while true do    

        -- get debug info
        local info = debug.getinfo(level, "Sln")

        -- end?
        if not info or (info.name and (info.name == "xpcall" or info.name == "load")) then
            break
        end

        -- function?
        if info.what == "C" then
            results = results .. string.format("    [C]: in function '%s'\n", info.name)
        elseif info.name then 
            results = results .. string.format("    [%s:%d]: in function '%s'\n", info.short_src, info.currentline, info.name)    
        elseif info.what == "main" then
            results = results .. string.format("    [%s:%d]: in main chunk\n", info.short_src, info.currentline)    
            break
        else
            results = results .. string.format("    [%s:%d]:\n", info.short_src, info.currentline)    
        end

        -- next
        level = level + 1    
    end    

    -- ok?
    return results
end

-- register api for builtin
function sandbox._api_register_builtin(self, name, func)

    -- check
    assert(self and self._PUBLIC and func)

    -- register it
    self._PUBLIC[name] = func
end

-- init sandbox
function sandbox._init()

    -- init an sandbox instance
    local self = {_PUBLIC = {}, _PRIVATE = {}}

    -- inherit the interfaces of sandbox
    for k, v in pairs(sandbox) do
        if type(v) == "function" then
            self[k] = v
        end
    end

    -- load builtin module files
    local builtin_module_files = os.match(path.join(xmake._CORE_DIR, "sandbox/*.lua"))
    if builtin_module_files then
        for _, builtin_module_file in ipairs(builtin_module_files) do

            -- the module name
            local module_name = path.basename(builtin_module_file)
            assert(module_name)

            -- load script
            local script, errors = loadfile(builtin_module_file)
            if script then

                -- load module
                local ok, results = xpcall(script, debug.traceback)
                if not ok then
                    os.raise(results)
                end

                -- register module
                self:_api_register_builtin(module_name, results)
            else
                -- error
                os.raise(errors)
            end
        end
    end

    -- save self
    setmetatable(self._PUBLIC, {    __index = function (tbl, key)
                                        if type(key) == "string" and key == "_SANDBOX" and rawget(tbl, "_SANDBOX_READABLE") then
                                            return self
                                        end
                                        return rawget(tbl, key)
                                    end
                                ,   __newindex = function (tbl, key, val)
                                        if type(key) == "string" and (key == "_SANDBOX" or key == "_SANDBOX_READABLE") then
                                            return 
                                        end
                                        rawset(tbl, key, val)
                                    end}) 

    -- ok?
    return self
end

-- make sandbox instance with the given script
function sandbox.make(script, interp)

    -- check
    assert(script and interp)

    -- init self 
    local self = sandbox._init()

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)

    -- save filter
    self._PRIVATE._FILTER = interp:filter()

    -- save root directory
    self._PRIVATE._ROOTDIR = interp:rootdir()

    -- this script is file? load it first
    if type(script) == "string" then
    
        -- TODO
        assert(false)
    end

    -- no script?
    if script == nil then
        return nil, "no script!"
    end

    -- invalid script?
    if script ~= nil and type(script) ~= "function" then
        return nil, "invalid script!"
    end

    -- bind public scope
    setfenv(script, self._PUBLIC)

    -- save script
    self._PRIVATE._SCRIPT = script

    -- ok
    return self
end

-- load script in the sandbox
function sandbox.load(script, ...)

    -- load script
    return xpcall(script, sandbox._traceback, ...)
end

-- fork a new sandbox from the given sandbox
function sandbox.fork(self, script)

    -- no script?
    if script == nil then
        return nil, "no script!"
    end

    -- invalid script?
    if script ~= nil and type(script) ~= "function" then
        return nil, "invalid script!"
    end

    -- init a new sandbox instance
    local instance = sandbox._init()

    -- check
    assert(instance and instance._PUBLIC and instance._PRIVATE)

    -- inherit the filter
    instance._PRIVATE._FILTER = self:filter()

    -- inherit the root directory
    instance._PRIVATE._ROOTDIR = self:rootdir()

    -- bind public scope
    setfenv(script, instance._PUBLIC)

    -- save script
    instance._PRIVATE._SCRIPT = script

    -- ok?
    return instance
end

-- get script from the given sandbox
function sandbox.script(self)

    -- check
    assert(self and self._PRIVATE)

    -- get it
    return self._PRIVATE._SCRIPT
end

-- get filter from the given sandbox
function sandbox.filter(self)

    -- check
    assert(self and self._PRIVATE)

    -- get it
    return self._PRIVATE._FILTER
end

-- get root directory from the given sandbox
function sandbox.rootdir(self)

    -- check
    assert(self and self._PRIVATE)

    -- get it
    return self._PRIVATE._ROOTDIR
end

-- get current instance in the sandbox modules
function sandbox.instance()

    -- find self instance for the current sandbox
    local instance = nil
    local level = 2
    while level < 16 do

        -- get scope
        local scope = getfenv(level)
        if scope then

            -- enable to read _SANDBOX
            rawset(scope, "_SANDBOX_READABLE", true)
            
            -- attempt to get it
            instance = scope._SANDBOX

            -- disable to read _SANDBOX
            rawset(scope, "_SANDBOX_READABLE", nil)
        end

        -- found?
        if instance then
            break
        end

        -- next
        level = level + 1
    end

    -- ok?
    return instance 
end

-- return module: sandbox
return sandbox
