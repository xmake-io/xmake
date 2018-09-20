--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        environment.lua
--

-- define module
local environment = environment or {}

-- load modules
local os        = require("base/os")
local platform  = require("platform/platform")
local sandbox   = require("sandbox/sandbox")
local package   = require("package/package")

-- enter the toolchains environment
function environment._enter_toolchains()

    -- save the toolchains environment
    environment._PATH            = os.getenv("PATH")
    environment._LD_LIBRARY_PATH = os.getenv("LD_LIBRARY_PATH")

    -- add search binary pathes of packages
    os.addenv("PATH", path.join(package.prefixdir(true), "release", os.host(), os.arch(), "bin"))  -- globaldir/release/../bin
    os.addenv("PATH", path.join(package.prefixdir(false), "release", os.host(), os.arch(), "bin")) -- localdir/release/../bin
end

-- leave the toolchains environment
function environment._leave_toolchains()

    -- leave the toolchains environment
    os.setenv("PATH", environment._PATH)
end

-- enter the running environment
function environment._enter_run()

    -- save the running environment
    environment._LD_LIBRARY_PATH = os.getenv("LD_LIBRARY_PATH")

    -- add search library pathes of packages
    if os.host() ~= "windows" then
        os.addenv("LD_LIBRARY_PATH", path.join(package.prefixdir(true), "release", os.host(), os.arch(), "lib"))  -- globaldir/release/../lib
        os.addenv("LD_LIBRARY_PATH", path.join(package.prefixdir(false), "release", os.host(), os.arch(), "lib")) -- localdir/release/../lib
    end
end

-- leave the running environment
function environment._leave_run()

    -- leave the running environment
    os.setenv("LD_LIBRARY_PATH", environment._LD_LIBRARY_PATH)
end

-- enter the environment for the current platform
function environment.enter(name)

    -- the maps
    local maps = {toolchains = environment._enter_toolchains, run = environment._enter_run}
    
    -- enter the common environment
    local func = maps[name]
    if func then
        func()
    end

    -- enter the environment of the given platform
    local module = platform.get("environment")
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

    -- leave the environment of the given platform
    local module = platform.get("environment")
    if module then
        local ok, errors = sandbox.load(module.leave, name)
        if not ok then
            return false, errors
        end
    end

    -- the maps
    local maps = {toolchains = environment._leave_toolchains, run = environment._enter_run}
    
    -- leave the common environment
    local func = maps[name]
    if func then
        func()
    end

    -- ok
    return true
end

-- return module
return environment
