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
-- @author      ruki
-- @file        platforms.lua
--

-- imports
import("core.project.project")
import("core.platform.platform")
import("core.base.text")
import("core.base.option")
import(".showlist")

-- show all platforms
function main()

    -- get all platforms
    local plats = try {function () return project.allowed_plats() end}
    if plats then
        plats = plats:to_array()
    end
    plats = plats or platform.plats()

    -- get all architectures
    local result = {align = 'l', sep = " "}
    local json_result = {}
    for i, plat in ipairs(plats) do
        local archs = try {function () return project.allowed_archs(plat) end}
        if archs then
            archs = archs:to_array()
        end
        if not archs then
            archs = platform.archs(plat)
        end
        if archs and #archs > 0 then
            table.insert(result, table.join(plat, archs))
            json_result[plat] = archs
        end
    end
    if option.get("json") then
        showlist(json_result)
    else
        print(text.table(result))
    end
end
