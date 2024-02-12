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
-- @file        select_script.lua
--

-- define module
local instance_deps = instance_deps or {}

-- load modules
local option = require("base/option")
local string = require("base/string")
local table = require("base/table")

-- select the matched pattern script for the current platform/architecture
--
-- the supported pattern:
--
-- `@linux`
-- `@linux|x86_64`
-- `@macosx,linux`
-- `android@macosx,linux`
-- `android|armeabi-v7a@macosx,linux`
-- `android|armeabi-v7a@macosx,linux|x86_64`
-- `android|armeabi-v7a@linux|x86_64`
--
function select_script(scripts, opt)
    opt = opt or {}
    local result = nil
    if type(scripts) == "function" then
        result = scripts
    elseif type(scripts) == "table" then
        local plat = opt.plat or ""
        local arch = opt.arch or ""
        for pattern, script in pairs(scripts) do
            local hosts = {}
            local hosts_spec = false
            pattern = pattern:gsub("@(.+)", function (v)
                for _, host in ipairs(v:split(',')) do
                    hosts[host] = true
                    hosts_spec = true
                end
                return ""
            end)
            if not pattern:startswith("__") and (not hosts_spec or hosts[os.subhost() .. '|' .. os.subarch()] or hosts[os.subhost()])
            and (pattern:trim() == "" or (plat .. '|' .. arch):find('^' .. pattern .. '$') or plat:find('^' .. pattern .. '$')) then
                result = script
                break
            end
        end
        result = result or scripts["__generic__"]
    end
    return result
end

return select_script
