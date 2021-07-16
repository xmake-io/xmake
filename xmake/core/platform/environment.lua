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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        environment.lua
--

-- define module
local environment = environment or {}

-- load modules
local os            = require("base/os")
local table         = require("base/table")
local global        = require("base/global")
local sandbox       = require("sandbox/sandbox")
local package       = require("package/package")
local import        = require("sandbox/modules/import")

-- enter the toolchains environment
function environment._enter_toolchains()
    return true
end

-- leave the toolchains environment
function environment._leave_toolchains()
    return true
end

-- enter the environment for the current platform
function environment.enter(name)

    -- need enter?
    local entered = environment._ENTERED or {}
    environment._ENTERED = entered
    if entered[name] then
        entered[name] = entered[name] + 1
        return true
    else
        entered[name] = 1
    end

    -- do enter
    local maps = {toolchains = environment._enter_toolchains}
    local func = maps[name]
    if func then
        local ok, errors = func()
        if not ok then
            return false, errors
        end
    end
    return true
end

-- leave the environment for the current platform
function environment.leave(name)

    -- need leave?
    local entered = environment._ENTERED or {}
    if entered[name] then
        entered[name] = entered[name] - 1
    end
    if entered[name] == 0 then
        entered[name] = nil
    else
        return true
    end

    -- do leave
    local maps = {toolchains = environment._leave_toolchains}
    local func = maps[name]
    if func then
        local ok, errors = func()
        if not ok then
            return false, errors
        end
    end
    return true
end

-- return module
return environment
