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
import("core.package.package", {alias = "core_package"})

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
    if requireinfo.host then
        if is_subhost(core_package.targetplat()) and os.subarch() == core_package.targetarch() then
            -- we need to pass plat/arch to avoid repeat installation
            -- @see https://github.com/xmake-io/xmake/issues/1579
        else
            key = key .. "/host"
        end
    end
    if requireinfo.system then
        key = key .. "/system"
    end
    -- @see https://github.com/xmake-io/xmake/issues/4934
    if requireinfo.private then
        key = key .. "/private"
    end
    if key:startswith("/") then
        key = key:sub(2)
    end
    local configs = requireinfo.configs
    if configs then
        local configs_order = {}
        for k, v in pairs(configs) do
            if type(v) == "table" then
                v = string.serialize(v, {strip = true, indent = false, orderkeys = true})
            end
            table.insert(configs_order, k .. "=" .. tostring(v))
        end
        table.sort(configs_order)
        key = key .. ":" .. string.serialize(configs_order, true)
    end
    if opt.hash then
        if key == "" then
            key = "_" -- we need to generate a fixed hash value
        end
        return hash.strhash32(key)
    else
        return key
    end
end

