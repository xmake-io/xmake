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
-- @file        global.lua
--

-- define module
local sandbox_core_base_global = sandbox_core_base_global or {}

-- load modules
local table     = require("base/table")
local global    = require("base/global")
local platform  = require("platform/platform")
local raise     = require("sandbox/modules/raise")

-- get the configure
function sandbox_core_base_global.get(name)
    return global.get(name)
end

-- set the configure 
function sandbox_core_base_global.set(name, value, readonly)
    global.set(name, value, readonly)
end

-- this config name is readonly?
function sandbox_core_base_global.readonly(name)
    return config.readonly(name)
end

-- dump the configure
function sandbox_core_base_global.dump()
    global.dump()
end

-- load the configure
function sandbox_core_base_global.load()
    return global.load()
end

-- save the configure
function sandbox_core_base_global.save()

    -- save it
    local ok, errors = global.save()
    if not ok then
        raise(errors)
    end
end

-- check the configure
function sandbox_core_base_global.check()

    -- check all platforms with the current host
    for _, plat in ipairs(table.wrap(platform.plats())) do

        -- load platform 
        local instance, errors = platform.load(plat)
        if not instance then
            raise(errors)
        end

        -- belong to the current host?
        for _, host in ipairs(table.wrap(instance:hosts())) do
            if host == xmake._HOST then

                -- get the check script
                local check = instance:get("check")
                if check ~= nil then

                    -- check it
                    check("global")
                end

                -- ok
                break
            end
        end
    end
end

-- get all options
function sandbox_core_base_global.options()
    return global.options()
end

-- get the configure directory
function sandbox_core_base_global.directory()

    -- get it
    local dir = global.directory()
    assert(dir)

    -- ok?
    return dir
end


-- return module
return sandbox_core_base_global
