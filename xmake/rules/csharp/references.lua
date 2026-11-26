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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      Omega
-- @file        references.lua
--

import("private.utils.target", {alias = "target_utils"})

function _get_linkdirs(target)
    local linkdirs = {}
    for _, linkdir in ipairs(target_utils.get_values_from_target(target, "linkdirs")) do
        table.insert(linkdirs, path.absolute(linkdir, os.projectdir()))
    end
    return table.unique(linkdirs)
end

function _get_links(target)
    local links = {}
    for _, link in ipairs(target_utils.get_values_from_target(target, "links")) do
        link = tostring(link):trim()
        if link:lower():endswith(".dll") then
            link = link:sub(1, -5)
        end
        if #link > 0 then
            table.insert(links, link)
        end
    end
    return table.unique(links)
end

function _find_assemblyfile(linkdirs, name)
    for _, linkdir in ipairs(linkdirs) do
        local assemblyfile = path.join(linkdir, name .. ".dll")
        if os.isfile(assemblyfile) then
            return assemblyfile
        end
    end
end

function main(target)
    local references = {}
    local linkdirs = _get_linkdirs(target)
    for _, name in ipairs(_get_links(target)) do
        table.insert(references, {name = name, assemblyfile = _find_assemblyfile(linkdirs, name)})
    end
    table.sort(references, function (a, b) return a.name < b.name end)
    return references
end
