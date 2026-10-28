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
-- @file        qt_add_qml_module.lua
--

-- add a QML module, the equivalent of Qt CMake's qt_add_qml_module()
--
-- @code
-- includes("@builtin/qt")
-- target("myapp")
--     add_rules("qt.quickapp")
--     qt_add_qml_module("*.qml", "*.js", "qmldir", "assets/*.svg", {uri = "MyApp"})
-- @endcode
--
function qt_add_qml_module(...)

    -- the last argument table contains the options
    local args = table.pack(...)
    local opt = {}
    if args.n > 0 and table.is_dictionary(args[args.n]) then
        opt = table.remove(args)
        args.n = args.n - 1
    end

    -- classify the files by their extension, unknown patterns are passed to xmake's
    -- native add_files() so that xmake reports unmatched/unknown source files itself
    local qmlfiles = {}
    local resfiles = {}
    local unknown = {}
    local function _classify(file)
        for _, pattern in ipairs(table.wrap(file)) do
            local extension = path.extension(pattern):lower()
            local filename = path.filename(pattern):lower()
            if extension == ".qml" or extension == ".js" or extension == ".mjs" or
                extension == ".qmldir" or filename == "qmldir" then
                table.insert(qmlfiles, pattern)
            elseif extension ~= "" and not extension:find("*", 1, true) then
                table.insert(resfiles, pattern)
            else
                table.insert(unknown, pattern)
            end
        end
    end
    for i = 1, args.n do
        _classify(args[i])
    end

    -- activate the qt.qml rule, it provides on_load()/on_config()
    add_rules("qt.qml")

    -- inject the module settings
    if opt.uri then
        add_values("qt.qml.uri", opt.uri)
    end
    local values = {
        {"cachegen", opt.cachegen},
        {"only_bytecode", opt.only_bytecode},
        {"type_compiler", opt.type_compiler},
        {"namespace", opt.namespace},
        {"discard", opt.discard},
        {"aot_stats", opt.aot_stats}
    }
    for _, value in ipairs(values) do
        if value[2] ~= nil then
            add_values("qt.qml." .. value[1], value[2])
        end
    end
    if opt.import then
        add_values("qt.qml.import", opt.import)
    end

    if #qmlfiles > 0 then
        add_files(qmlfiles, {rules = "qt.qml"})
    end
    if #resfiles > 0 then
        add_files(resfiles, {rules = "qt.qml.resource"})
    end
    if #unknown > 0 then
        add_files(unknown)
    end
end
