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
-- @file        load.lua
--

-- imports
import("utils")

-- do cheap checks of the options, the Qt SDK is not available yet
function main(target)
    local setting = utils.get_setting(target)

    -- check the option types
    local uri = setting.uri
    assert(type(uri) == "string" and uri ~= "", "qt.qml: qt.qml.uri must be a non-empty string")
    assert(not uri:find("/", 1, true), "qt.qml: module uri(%s) cannot contain '/'", uri)
    assert(not uri:find("%s"), "qt.qml: module uri(%s) cannot contain whitespace", uri)
    for _, name in ipairs({ "cachegen", "only_bytecode", "discard" }) do
        assert(type(setting[name]) == "boolean", "qt.qml: qt.qml.%s must be a boolean", name)
    end
    for _, importdir in ipairs(setting.imports) do
        assert(type(importdir) == "string", "qt.qml: qt.qml.import must be a list of directories")
    end

    -- only_bytecode is disabled by get_setting() in this case, warn the user once
    if utils.get_option(target, "qt.qml.only_bytecode", false) and not setting.cachegen then
        wprint("qt.qml: qt.qml.only_bytecode is ignored because qt.qml.cachegen is disabled")
    end
end
