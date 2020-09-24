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
import("core.base.global")
import("core.theme.theme")
import("menuconf", {alias = "menuconf_show"})

-- main
function main()

    -- enter menu config
    if option.get("menu") then
        menuconf_show()
    end

    -- load the global configure
    --
    -- priority: option > option_default > config_check > global_cache
    --
    if option.get("clean") then
        global.clear()
    end

    -- override the option configure
    local changed = false
    for name, value in pairs(option.options()) do
        if name ~= "verbose" then
            -- the config value is changed by argument options?
            changed = changed or global.get(name) ~= value

            -- @note override it and mark as readonly
            global.set(name, value, {readonly = true})
        end
    end

    -- merge the default options
    for name, value in pairs(option.defaults()) do
        if name ~= "verbose" and global.get(name) == nil then
            global.set(name, value)
        end
    end

    -- load and check theme
    local themename = option.get("theme")
    if themename then
        theme.load(themename)
    end

    -- save it
    global.save()

    -- dump it
    global.dump()
end
