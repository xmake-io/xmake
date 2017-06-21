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
-- @file        tool.lua
--

-- define module
local tool      = tool or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local table         = require("base/table")
local string        = require("base/string")
local sandbox       = require("sandbox/sandbox")
local platform      = require("platform/platform")
local import        = require("sandbox/modules/import")

-- load the given tool 
function tool._load(kind, name, program)

    -- calculate the cache key
    local key = (kind or "") .. program

    -- get it directly from cache dirst
    tool._TOOLS = tool._TOOLS or {}
    if tool._TOOLS[key] then
        return tool._TOOLS[key]
    end

    -- not exists?
    local toolpath = path.join(os.programdir(), "tools", name .. ".lua")
    if not os.isfile(toolpath) then
        return nil, string.format("%s not found!", name)
    end

    -- load script
    local script, errors = loadfile(toolpath)
    if script then

        -- make sandbox instance with the given script
        local instance, errors = sandbox.new(script, nil, path.directory(toolpath))
        if not instance then
            return nil, errors
        end

        -- import the tool module
        local module, errors = instance:import()
        if not module then
            return nil, errors
        end

        -- init the tool module
        if module.init then
            module.init(program, kind)
        end
    
        -- save tool to the cache
        tool._TOOLS[key] = module

        -- ok?
        return module
    end

    -- failed
    return nil, errors
end

-- check the program
function tool._check(program, check)

    -- uses the passed checker
    if check ~= nil then

        -- check it
        local ok, errors = sandbox.load(check, program) 
        if not ok then
            utils.verror(errors)
        end

        -- ok?
        return ok
    end
 
    -- load the tool module
    local module, errors = tool._load(program)
    if not module then
        utils.verror(errors)
    end

    -- no checker? attempt to run it directly
    if not module or not module.check then
        return 0 == os.exec(program, os.nuldev(), os.nuldev())
    end

    -- check it
    local ok, errors = sandbox.load(module.check) 
    if not ok then
        utils.verror(errors)
    end

    -- ok?
    return ok
end

-- load the given tool from the given kind
--
-- the kinds:
-- 
-- .e.g cc, cxx, mm, mxx, as, ar, ld, sh, ..
--
function tool.load(kind)

    -- get the tool program
    local program = platform.tool(kind)
    if not program then
        return nil, string.format("cannot get tool for %s", kind)
    end

    -- import find_toolname()
    local find_toolname = import("lib.detect.find_toolname")

    -- get the tool name from the program
    local name = find_toolname(program)
    if not name then
        return nil, string.format("cannot find tool name for %s", program)
    end

    -- load it
    return tool._load(kind, name, program)
end

-- check the tool and return the absolute path if exists
function tool.check(program, dirs, check)

    -- check
    assert(program)

    -- attempt to get result from cache first
    tool._CHECKINFO = tool._CHECKINFO or {}
    local result = tool._CHECKINFO[program]
    if result then
        return result
    end

    -- attempt to check it directly 
    if tool._check(program, check) then
        tool._CHECKINFO[program] = program
        return program
    end

    -- attempt to check it from the given directories
    if not path.is_absolute(program) then
        for _, dir in ipairs(table.wrap(dirs)) do

            -- the tool path
            local toolpath = path.join(dir, program)
            if os.isexec(toolpath) then
            
                -- check it
                if tool._check(toolpath, check) then
                    tool._CHECKINFO[program] = toolpath
                    return toolpath
                end
            end
        end
    end
end

-- return module
return tool
