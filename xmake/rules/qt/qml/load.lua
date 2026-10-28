--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- You may not use this file except in compliance with the License.
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
-- @file        load.lua
--

-- imports
import("utils")

-- do cheap checks of the options, the Qt SDK is not available yet
function main(target)
    local setting = utils.get_setting(target)

    -- a target has only one QML module
    local uris = table.unique(utils.get_values(target, "qt.qml.uri"))
    assert(#uris <= 1, "qt.qml: only one module uri is allowed in target(%s), got: %s",
        target:name(), table.concat(uris, ", "))
    utils.check_uri(setting.uri)

    -- check the option types
    local booleans = {
        {"cachegen", setting.cachegen},
        {"only_bytecode", setting.only_bytecode},
        {"type_compiler", setting.type_compiler},
        {"discard", setting.discard}
    }
    for _, item in ipairs(booleans) do
        assert(type(item[2]) == "boolean", "qt.qml: qt.qml.%s must be a boolean!", item[1])
    end
    assert(type(setting.namespace) == "string", "qt.qml: qt.qml.namespace must be a string!")
    assert(setting.aot_stats == nil or type(setting.aot_stats) == "boolean",
        "qt.qml: qt.qml.aot_stats must be a boolean or nil!")
    for _, importdir in ipairs(setting.imports) do
        assert(type(importdir) == "string", "qt.qml: qt.qml.import must be a list of directories!")
    end

    if setting.namespace ~= "" and not setting.type_compiler then
        wprint("qt.qml: qt.qml.namespace is ignored because qt.qml.type_compiler is disabled")
    end
    if setting.only_bytecode and not utils.get_option(target, "qt.qml.cachegen", true) then
        wprint("qt.qml: qt.qml.only_bytecode requires qmlcachegen, qt.qml.cachegen is forced to true")
    end
end
