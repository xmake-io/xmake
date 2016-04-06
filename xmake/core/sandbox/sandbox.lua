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

-- define module
local sandbox = sandbox or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")
local option    = require("base/option")

-- traceback
function sandbox._traceback(errors)

    -- not verbose?
    if not option.get("verbose") then
        if errors then
            -- remove the prefix info
            local _, pos = errors:find(":%d+: ")
            if pos then
                return errors:sub(pos + 1)
            end
        end
        return errors
    end

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
        if not info then
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

-- new a sandbox instance
function sandbox._new()

    -- init an sandbox instance
    local instance = {_PUBLIC = {}, _PRIVATE = {}}

    -- inherit the interfaces of sandbox
    table.inherit2(instance, sandbox)

    -- load builtin module files
    local builtin_module_files = os.match(path.join(xmake._CORE_DIR, "sandbox/modules/*.lua"))
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
                instance:_api_register_builtin(module_name, results)
            else
                -- error
                os.raise(errors)
            end
        end
    end

    -- save instance
    setmetatable(instance._PUBLIC, {    __index = function (tbl, key)
                                        if type(key) == "string" and key == "_SANDBOX" and rawget(tbl, "_SANDBOX_READABLE") then
                                            return instance
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
    return instance
end

-- new a sandbox instance with the given script
function sandbox.new(script, interp)

    -- check
    assert(script and interp)

    -- new instance 
    local self = sandbox._new()

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)

    -- save filter
    self._PRIVATE._FILTER = interp:filter()

    -- save root directory
    self._PRIVATE._ROOTDIR = interp:rootdir()

    -- this script is module name? import it first
    if type(script) == "string" then
    
        -- import module as script
        local modulename = script
        script = function ()
       
            -- import it
            import(modulename).main()
        end
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
function sandbox:fork(script)

    -- no script?
    if script == nil then
        return nil, "no script!"
    end

    -- invalid script?
    if script ~= nil and type(script) ~= "function" then
        return nil, "invalid script!"
    end

    -- init a new sandbox instance
    local instance = sandbox._new()

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
function sandbox:script()

    -- check
    assert(self and self._PRIVATE)

    -- get it
    return self._PRIVATE._SCRIPT
end

-- get filter from the given sandbox
function sandbox:filter()

    -- check
    assert(self and self._PRIVATE)

    -- get it
    return self._PRIVATE._FILTER
end

-- get root directory from the given sandbox
function sandbox:rootdir()

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

-- return module
return sandbox
