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
-- @file        check_targets.lua
--

-- add values from target options
function _add_values_from_targetopts(values, target, name)
    for _, opt in ipairs(target:orderopts()) do
        table.join2(values, table.wrap(opt:get(name)))
    end
end

-- add values from target packages
function _add_values_from_targetpkgs(values, target, name)
    for _, pkg in ipairs(target:orderpkgs()) do
        -- uses them instead of the builtin configs if exists extra package config
        -- e.g. `add_packages("xxx", {links = "xxx"})`
        local configinfo = target:pkgconfig(pkg:name())
        if configinfo and configinfo[name] then
            table.join2(values, configinfo[name])
        else
            -- uses the builtin package configs
            table.join2(values, pkg:get(name))
        end
    end
end

-- get values from target
function _get_values_from_target(target, name)
    local values = table.wrap(target:get(name))
    _add_values_from_targetopts(values, target, name)
    _add_values_from_targetpkgs(values, target, name)
    return values
end

-- main entry
function main(target)
    for _, name in ipairs({"includedirs", "frameworkdirs", "linkdirs"}) do
        for _, value in ipairs(_get_values_from_target(target, name)) do
            if not os.isdir(value) then
                local sourceinfo = (target:get("__sourceinfo_" .. name) or {})[value] or {}
                cprint("${color.warning}${text.warning}: %s(%s).add_%s(\"%s\") path not found at %s:%d", target:type(), target:name(), name, value, sourceinfo.file or "", sourceinfo.line or -1)
            end
        end
    end
end
