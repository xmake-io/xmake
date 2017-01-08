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
-- @file        environment.lua
--

-- define module
local environment = environment or {}

-- load modules
local platform  = require("platform/platform")
local sandbox   = require("sandbox/sandbox")

-- load the given environment from the given platform
function environment.load(plat)

    -- load platform
    local instance, errors = platform.load(plat)
    if not instance then
        return nil, errors
    end

    -- get environment
    return instance:environment()
end

-- enter the environment for the current platform
function environment.enter(name)

    -- load the environment module
    local module, errors = environment.load()
    if not module and errors then
        return false, errors
    end

    -- enter it
    if module then
        local ok, errors = sandbox.load(module.enter, name)
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- leave the environment for the current platform
function environment.leave(name)

    -- load the environment module
    local module, errors = environment.load()
    if not module and errors then
        return false, errors
    end

    -- leave it
    if module then
        local ok, errors = sandbox.load(module.leave, name)
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- return module
return environment
