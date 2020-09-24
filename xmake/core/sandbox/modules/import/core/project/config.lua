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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        config.lua
--

-- define module
local sandbox_core_project_config = sandbox_core_project_config or {}

-- load modules
local config    = require("project/config")
local project   = require("project/project")
local platform  = require("platform/platform")
local raise     = require("sandbox/modules/raise")

-- get the build directory
function sandbox_core_project_config.buildir()
    return config.buildir()
end

-- get the current platform
function sandbox_core_project_config.plat()
    return config.get("plat")
end

-- get the current architecture
function sandbox_core_project_config.arch()
    return config.get("arch")
end

-- get the current mode
function sandbox_core_project_config.mode()
    return config.get("mode")
end

-- get the current host
function sandbox_core_project_config.host()
    return config.get("host")
end

-- get the configuration file path
function sandbox_core_project_config.filepath()
    local filepath = config.filepath()
    assert(filepath)
    return filepath
end

-- get the configuration directory
function sandbox_core_project_config.directory()
    local dir = config.directory()
    assert(dir)
    return dir
end

-- get the given configuration from the current
function sandbox_core_project_config.get(name)
    return config.get(name)
end

-- set the given configuration to the current
--
-- @param name  the name
-- @param value the value
-- @param opt   the argument options, e.g. {readonly = false, force = false}
--
function sandbox_core_project_config.set(name, value, opt)
    return config.set(name, value, opt)
end

-- this config name is readonly?
function sandbox_core_project_config.readonly(name)
    return config.readonly(name)
end

-- load the configuration
function sandbox_core_project_config.load(targetname)
    return config.load(targetname)
end

-- save the configuration
function sandbox_core_project_config.save(targetname)

    -- save it
    local ok, errors = config.save(targetname)
    if not ok then
        raise(errors)
    end
end

-- read the value from the configuration file directly
function sandbox_core_project_config.read(name, targetname)
    return config.read(name, targetname)
end

-- clear the configuration
function sandbox_core_project_config.clear()
    config.clear()
end

-- check the configuration
function sandbox_core_project_config.check()

    -- check configuration for the current platform
    local instance, errors = platform.load()
    if instance then
        local ok, errors = instance:check()
        if not ok then
            raise(errors)
        end
    else
        raise(errors)
    end
end

-- dump the configuration
function sandbox_core_project_config.dump()
    config.dump()
end


-- return module
return sandbox_core_project_config
