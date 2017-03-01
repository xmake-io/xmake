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
-- @file        config.lua
--

-- define module
local sandbox_core_project_config = sandbox_core_project_config or {}

-- load modules
local config    = require("project/config")
local platform  = require("platform/platform")
local raise     = require("sandbox/modules/raise")

-- get the build directory
function sandbox_core_project_config.buildir()

    -- get it 
    return config.buildir()
end

-- get the current platform
function sandbox_core_project_config.plat()

    -- get it 
    return config.get("plat")
end

-- get the current architecture
function sandbox_core_project_config.arch()

    -- get it 
    return config.get("arch")
end

-- get the current mode
function sandbox_core_project_config.mode()

    -- get it 
    return config.get("mode")
end

-- get the current host
function sandbox_core_project_config.host()

    -- get it 
    return config.get("host")
end

-- get the configure directory
function sandbox_core_project_config.directory()

    -- get it
    local dir = config.directory()
    assert(dir)

    -- ok?
    return dir
end

-- get the given configure from the current 
function sandbox_core_project_config.get(name)

    -- get it
    return config.get(name)
end

-- set the given configure to the current 
function sandbox_core_project_config.set(name, value)

    -- set it
    return config.set(name, value)
end

-- load the configure
function sandbox_core_project_config.load(targetname)

    -- load it
    local ok, errors = config.load(targetname)
    if not ok then
        raise(errors)
    end
end

-- save the configure
function sandbox_core_project_config.save(targetname)

    -- save it
    local ok, errors = config.save(targetname)
    if not ok then
        raise(errors)
    end
end

-- read the value from the configure file directly
function sandbox_core_project_config.read(name, targetname)

    -- read it
    return config.read(name, targetname)
end

-- the configure has been changed for the given target?
function sandbox_core_project_config.changed(targetname)

    -- changed?
    return config.changed(targetname)
end

-- init the configure
function sandbox_core_project_config.init()

    -- init it
    config.init()
end

-- check the configure
function sandbox_core_project_config.check()

    -- get the check script
    local check = platform.get("check")
    if check then
        check("config")
    end
end

-- dump the configure
function sandbox_core_project_config.dump()

    -- dump it
    config.dump()
end


-- return module
return sandbox_core_project_config
