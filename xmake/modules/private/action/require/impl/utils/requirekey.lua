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
-- @file        requirekey.lua
--

-- imports
import("core.base.hashset")

-- get require key from requireinfo
function main(requireinfo, opt)
    opt = opt or {}
    local key = ""
    if opt.name then
        key = key .. "/" .. opt.name
    end
    if opt.plat then
        key = key .. "/" .. opt.plat
    end
    if opt.arch then
        key = key .. "/" .. opt.arch
    end
    if opt.kind then
        key = key .. "/" .. opt.kind
    end
    if opt.version then
        key = key .. "/" .. opt.version
    end
    if requireinfo.label then
        key = key .. "/" .. requireinfo.label
    end
    if requireinfo.system then
        key = key .. "/system"
    end
    if key:startswith("/") then
        key = key:sub(2)
    end
    local ignored_configs = hashset.from(requireinfo.ignored_configs or {})
    local configs = requireinfo.configs
    if configs then
        local configs_order = {}
        for k, v in pairs(configs) do
            if not ignored_configs:has(k) then
                table.insert(configs_order, k .. "=" .. tostring(v))
            end
        end
        table.sort(configs_order)
        key = key .. ":" .. string.serialize(configs_order, true)
    end
    if opt.hash then
        if key == "" then
            key = "_" -- we need generate a fixed hash value
        end
        return hash.uuid(key):split("-", {plain = true})[1]:lower()
    else
        return key
    end
end

