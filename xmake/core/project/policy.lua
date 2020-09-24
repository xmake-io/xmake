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
-- @file        policy.lua
--

-- define module: policy
local policy  = policy or {}

-- load modules
local os      = require("base/os")
local io      = require("base/io")
local path    = require("base/path")
local table   = require("base/table")
local utils   = require("base/utils")
local string  = require("base/string")

-- get all defined policies
function policy.policies()
    local policies = policy._POLICIES
    if not policies then
        policies =
        {
            -- we will check and ignore all unsupported flags by default, but we can also pass `{force = true}` to force to set flags, e.g. add_ldflags("-static", {force = true})
            ["check.auto_ignore_flags"]          = {description = "Enable check and ignore unsupported flags automatically.", default = true, type = "boolean"},
            -- we will map gcc flags to the current compiler and linker by default.
            ["check.auto_map_flags"]             = {description = "Enable map gcc flags to the current compiler and linker automatically.", default = true, type = "boolean"},
            -- we can compile the source files for each target in parallel
            ["build.across_targets_in_parallel"] = {description = "Enable compile the source files for each target in parallel.", default = true, type = "boolean"}
        }
        policy._POLICIES = policies
    end
    return policies
end

-- check policy value
function policy.check(name, value)
    local defined_policy = policy.policies()[name]
    if defined_policy then
        if value == nil then
            value = defined_policy.default
        else
            local valtype = type(value)
            if valtype ~= defined_policy.type then
                utils.warning("policy(%s): invalid value type(%s), it shound be '%s'!", name, valtype, defined_policy.type)
            end
        end
        return value
    else
        os.raise("unknown policy(%s)!", name)
    end
end

-- return module: policy
return policy
