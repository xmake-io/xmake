--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        environment.lua
--

-- define module
local environment = environment or {}

-- load modules
local os            = require("base/os")
local global        = require("base/global")
local platform_core = require("platform/platform")
local sandbox       = require("sandbox/sandbox")
local package       = require("package/package")
local import        = require("sandbox/modules/import")

-- enter the toolchains environment
function environment._enter_toolchains()

    -- save the toolchains environment
    environment._PATH = os.getenv("PATH")

    -- add $programdir/winenv/bin to $path
    if os.host() == "windows" then
        os.addenv("PATH", path.join(os.programdir(), "winenv", "bin"))
    end
end

-- leave the toolchains environment
function environment._leave_toolchains()

    -- leave the toolchains environment
    os.setenv("PATH", environment._PATH)
end

-- enter the running environment
function environment._enter_run()

    -- save the running environment
    environment._PATH            = os.getenv("PATH")
    environment._LD_LIBRARY_PATH = os.getenv("LD_LIBRARY_PATH")
end

-- leave the running environment
function environment._leave_run()

    -- leave the running environment
    os.setenv("PATH", environment._PATH)
    os.setenv("LD_LIBRARY_PATH", environment._LD_LIBRARY_PATH)
end

-- enter the environment for the current platform
function environment.enter(name)

    -- get the current platform 
    local platform, errors = platform_core.load()
    if not platform then
        return false, errors
    end

    -- the maps
    local maps = {toolchains = environment._enter_toolchains, run = environment._enter_run}
    
    -- enter the common environment
    local func = maps[name]
    if func then
        func()
    end

    -- enter the environment of the given platform
    local on_enter = platform:script("environment_enter")
    if on_enter then
        local ok, errors = sandbox.load(on_enter, platform, name)
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- leave the environment for the current platform
function environment.leave(name)

    -- get the current platform 
    local platform, errors = platform_core.load()
    if not platform then
        return false, errors
    end

    -- leave the environment of the given platform
    local on_leave = platform:script("environment_leave")
    if on_leave then
        local ok, errors = sandbox.load(on_leave, platform, name)
        if not ok then
            return false, errors
        end
    end

    -- the maps
    local maps = {toolchains = environment._leave_toolchains, run = environment._leave_run}
    
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
