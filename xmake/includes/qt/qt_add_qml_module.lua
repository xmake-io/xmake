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
-- @param ...   the file patterns and the last argument table contains the options:
--              - uri          the module uri, default: target:name()
--              - cachegen     enable qmlcachegen AOT, default: true
--              - only_bytecode  pass --only-bytecode to qmlcachegen, requires cachegen
--              - type_compiler  compile the .qml files with qmltc, default: false
--              - namespace    the qmltc namespace, default: nil (auto-generated from the
--                             uri), "" disables --namespace (keep the anonymous namespace)
--              - discard      do not pack the qml file contents into the qrc
--              - aot_stats    dump the AOT statistics: nil (auto), true (required), false
--              - import       the extra QML import directories
--
--              The files are classified by their extension: .qml/.js/.mjs/.qmldir and
--              the qmldir files are processed by the qt.qml rule, the other files with
--              a known extension are packed as resources by the qt.qml.resource rule,
--              unknown patterns are passed to the native add_files().
--
-- @code
-- includes("@builtin/qt")
-- target("myapp")
--     add_rules("qt.quickapp")
--     qt_add_qml_module("*.qml", "*.js", "qmldir", "assets/*.svg", {uri = "MyApp"})
-- @endcode
--
function qt_add_qml_module(...)
    add_rules("qt.qml", "qt.qrc", "qt.moc")

    -- the last argument table contains the options
    local args = table.pack(...)
    local opt = {}
    if args.n > 0 and table.is_dictionary(args[args.n]) then
        opt = table.remove(args)
        args.n = args.n - 1
    end

    -- Since the qmldir file may not have a suffix and the resource files may have any suffix,
    -- manual implementation of file classification is required.
    local qml_files = {}
    local res_files = {}
    local unknown = {}
    local qml_extension = { ".qml", ".js", ".mjs", ".qmldir" }
    local function _classify(pattern)
        local extension = path.extension(pattern):lower()
        local filename = path.filename(pattern):lower()
        if table.contains(qml_extension, extension) or filename == "qmldir" then
            table.insert(qml_files, pattern)
        elseif extension ~= "" and not extension:find("*", 1, true) then
            table.insert(res_files, pattern)
        else
            table.insert(unknown, pattern)
        end
    end
    for i = 1, args.n do
        for _, pattern in ipairs(table.wrap(args[i])) do
            _classify(pattern)
        end
    end

    -- inject the module settings
    local value_names = {
        "uri", "cachegen", "only_bytecode", "type_compiler", "namespace", "discard", "aot_stats", "import"
    }
    for _, value_name in ipairs(value_names) do
        if opt[value_name] ~= nil then
            add_values("qt.qml." .. value_name, opt[value_name])
        end
    end

    -- bind the files explicitly, `override` prevents the rules from being added
    -- again by their extensions, because qt.qml sets file extensions
    if #qml_files > 0 then
        add_files(qml_files, { rules = { "qt.qml", override = true } })
    end
    if #res_files > 0 then
        add_files(res_files, { rules = { "qt.qml.resource", override = true } })
    end
    if #unknown > 0 then
        add_files(unknown)
    end
end
