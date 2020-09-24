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
-- @file        main.lua
--

-- imports
import("core.base.option")

-- show list
function _show_list(name)
    assert(#name > 0 and import("lists." .. name, {try = true, anonymous = true}), "unknown list name(%s)", name)()
end

-- main entry
function main()

    -- show list?
    local listname = option.get("list")
    if listname then
        return _show_list(listname)
    else
        -- show the information of the given object
        for _, filepath in ipairs(os.files(path.join(os.scriptdir(), "info", "*.lua"))) do
            local name = path.basename(filepath)
            if option.get(name) then
                local show_info = assert(import("info." .. name, {try = true, anonymous = true}), "unknown option name(%s)", name)
                return show_info(option.get(name))
            end
        end
    end

    -- show the basic information of xmake and the current project
    assert(import("info.basic", {try = true, anonymous = true}))()
end
