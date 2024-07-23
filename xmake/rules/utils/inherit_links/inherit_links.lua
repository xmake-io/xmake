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
-- @file        inherit_links.lua
--

-- get values from target
function _get_values_from_target(target, name)
    local values = table.clone(table.wrap(target:get(name)))
    for _, value in ipairs((target:get_from(name, "option::*"))) do
        table.join2(values, value)
    end
    for _, value in ipairs((target:get_from(name, "package::*"))) do
        table.join2(values, value)
    end
    return values
end

-- @note we cannot directly set `{interface = true}`, because it will overwrite the previous configuration
-- https://github.com/xmake-io/xmake/issues/1465
function _add_export_value(target, name, value)
    local has_private = false
    local private_values = target:get(name)
    if private_values then
        for _, v in ipairs(private_values) do
            if v == value then
                has_private = true
                break
            end
        end
    end
    local extraconf = target:extraconf(name, value)
    if has_private then
        target:add(name, value, table.join(extraconf or {}, {public = true}))
    else
        target:add(name, value, table.join(extraconf or {}, {interface = true}))
    end
end

-- export values as public/interface in target
function _add_export_values(target, name, values)
    for _, value in ipairs(values) do
        _add_export_value(target, name, value)
    end
end

function main(target)

    -- disable inherit.links for `add_deps()`?
    if target:data("inherit.links") == false then
        return
    end

    -- export target links and linkdirs
    if target:is_shared() or target:is_static() then
        local targetfile = target:targetfile()

        -- rust maybe will disable inherit links, only inherit linkdirs
        if target:data("inherit.links.deplink") ~= false then
            -- we need to move target link to head
            _add_export_value(target, "links", target:linkname())
            local links = target:get("links", {rawref = true})
            if links and type(links) == "table" and #links > 1 then
                table.insert(links, 1, links[#links])
                table.remove(links, #links)
            end
        end

        _add_export_value(target, "linkdirs", path.directory(targetfile))
        if target:rule("go") then
            -- we need to add includedirs to support import modules for golang
            _add_export_value(target, "includedirs", path.directory(targetfile))
        end
    end

    -- we export all links and linkdirs in self/packages/options to the parent target by default
    --
    -- @note we only export links for static target,
    -- and we need to pass `{public = true}` to add_packages/add_links/... to export it if want to export links for shared target
    --
    if target:data("inherit.links.exportlinks") ~= false then
        if target:is_static() or target:is_object() then
            for _, name in ipairs({"rpathdirs", "frameworkdirs", "frameworks", "linkdirs", "links", "syslinks", "ldflags", "shflags"}) do
                local values = _get_values_from_target(target, name)
                if values and #values > 0 then
                    _add_export_values(target, name, values)
                end
            end
        end
    end

    -- export rpathdirs for all shared library
    if target:is_binary() and target:policy("build.rpath") then
        local targetdir = target:targetdir()
        for _, dep in ipairs(target:orderdeps({inherit = true})) do
            if dep:kind() == "shared" then
                local rpathdir = "@loader_path"
                local subdir = path.relative(path.directory(dep:targetfile()), targetdir)
                if subdir and subdir ~= '.' then
                    rpathdir = path.join(rpathdir, subdir)
                end
                target:add("rpathdirs", rpathdir)
            end
        end
    end
end

