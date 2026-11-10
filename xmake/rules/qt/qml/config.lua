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
-- @author      24bit-xjkp
-- @file        config.lua
--

-- imports
import("utils")
import("cachegen")
import("qmltc")

-- find and check the tools needed by the module
function main(target)
    local setting = utils.get_setting(target)
    local tools = {}
    if setting.cachegen then
        tools.cachegen = cachegen.get_tool(target, setting)
    end
    if setting.type_compiler then
        tools.qmltc = qmltc.get_tool(target)
    end
    target:data_set("qt.qml.tools", tools)
end
