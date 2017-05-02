--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
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
    if not option.get("backtrace") then
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
function sandbox.new(script, filter, rootdir)

    -- check
    assert(script)

    -- new instance 
    local self = sandbox._new()

    -- check
    assert(self and self._PUBLIC and self._PRIVATE)

    -- save filter
    self._PRIVATE._FILTER = filter

    -- save root directory
    self._PRIVATE._ROOTDIR = rootdir

    -- invalid script?
    if type(script) ~= "function" then
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
function sandbox:fork(script, rootdir)

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
    instance._PRIVATE._ROOTDIR = rootdir or self:rootdir()

    -- bind public scope
    if script then
        setfenv(script, instance._PUBLIC)
        instance._PRIVATE._SCRIPT = script
    end

    -- ok?
    return instance
end

-- load script and import module 
function sandbox:import()

    -- this module has been imported?
    if self._PRIVATE._MODULE then
        return self._PRIVATE._MODULE
    end

    -- backup the scope variables first
    local scope_public = getfenv(self:script())
    local scope_backup = {}
    table.copy2(scope_backup, scope_public)

    -- load module with sandbox
    local ok, errors = sandbox.load(self:script())
    if not ok then
        return nil, errors
    end

    -- only export new public functions
    local module = {}
    for k, v in pairs(scope_public) do
        if type(v) == "function" and not k:startswith("_") and scope_backup[k] == nil then
            module[k] = v
        end
    end

    -- save module
    self._PRIVATE._MODULE = module

    -- ok
    return module

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
