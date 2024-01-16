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
-- @file        qt_add_static_plugins.lua
--

-- add static plugins for qt rules
--
-- e.g.
--
-- @code
-- includes("qt_add_static_plugins.lua")
-- target("test")
--     add_rules("qt.quickapp")
--     add_files("src/*.c")
--     qt_add_static_plugins("QSvgPlugin", {linkdirs = "plugins/imageformats", links = {"qsvg"}})
-- @endcode
--
function qt_add_static_plugins(plugin, opt)
    opt = opt or {}
    add_values("qt.plugins", plugin)
    if opt.links then
        add_values("qt.links", table.unpack(table.wrap(opt.links)))
    end
    if opt.linkdirs then
        add_values("qt.linkdirs", table.unpack(table.wrap(opt.linkdirs)))
    end
end

