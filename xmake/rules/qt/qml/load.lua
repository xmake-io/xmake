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
import("core.base.semver")
import("utils")

-- do cheap checks of the options, the Qt SDK is not available yet
function main(target)
    local setting = utils.get_setting(target)

    -- check the option types
    local uri = setting.uri
    assert(type(uri) == "string" and uri ~= "", "qt.qml: qt.qml.uri must be a non-empty string")
    assert(not uri:find("[/%s]"), "qt.qml: module uri(%s) cannot contain '/' or whitespace", uri)
    local boolean_names = { "cachegen", "only_bytecode", "type_compiler", "discard" }
    for _, name in ipairs(boolean_names) do
        assert(type(setting[name]) == "boolean", "qt.qml: qt.qml.%s must be a boolean", name)
    end
    local namespace = setting.namespace
    assert(namespace == nil or type(namespace) == "string", "qt.qml: qt.qml.namespace must be a string or nil")
    local aot_stats = setting.aot_stats
    assert(aot_stats == nil or type(aot_stats) == "boolean", "qt.qml: qt.qml.aot_stats must be a boolean or nil")
    assert(type(setting.version) == "string", "qt.qml: qt.qml.version must be a string")
    assert(
        semver.is_valid(setting.version),
        "qt.qml: invalid qt.qml.version(%s), it must be a semver version",
        setting.version
    )
    for _, importdir in ipairs(setting.imports) do
        assert(type(importdir) == "string", "qt.qml: qt.qml.import must be a list of directories")
    end
    -- without qmlcachegen the QML sources are neither compiled nor packed into the qrc,
    -- so enabling discard would leave the module without any QML content
    assert(
        not (setting.discard and not setting.cachegen),
        "qt.qml: qt.qml.discard requires qt.qml.cachegen, otherwise the QML files are neither compiled nor packed"
    )

    if setting.namespace and setting.namespace ~= "" and not setting.type_compiler then
        wprint("qt.qml: qt.qml.namespace is ignored because qt.qml.type_compiler is disabled")
    end
    -- only_bytecode is disabled by get_setting() in this case, warn the user once
    if utils.get_option(target, "qt.qml.only_bytecode", false) and not setting.cachegen then
        wprint("qt.qml: qt.qml.only_bytecode is ignored because qt.qml.cachegen is disabled")
    end
    -- the AOT report requires qmlcachegen and cannot be combined with only_bytecode
    if setting.aot_stats and (not setting.cachegen or setting.only_bytecode) then
        wprint("qt.qml: qt.qml.aot_stats is ignored because the AOT compilation is disabled")
    end
end
