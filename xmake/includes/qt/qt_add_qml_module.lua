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
--              - discard      do not pack the qml file contents into the qrc
--              - import       the extra QML import directories
--
--              The files are dispatched by the extensions of the rules: the qt.qml rule
--              handles .qml/.js/.mjs and the qt.qml.resource rule handles the common QML
--              resource formats. Extra import directories are passed with the `import`
--              option.
--
-- @code
-- includes("@builtin/qt")
-- target("myapp")
--     add_rules("qt.quickapp")
--     qt_add_qml_module("*.qml", "*.js", "assets/*.svg", {uri = "MyApp"})
-- @endcode
--
function qt_add_qml_module(...)
    add_rules("qt.qml", "qt.qml.resource", "qt.qrc")

    -- the last argument table contains the options
    local args = table.pack(...)
    local opt = {}
    if args.n > 0 and table.is_dictionary(args[args.n]) then
        opt = table.remove(args)
        args.n = args.n - 1
    end

    -- inject the module settings
    local value_names = { "uri", "cachegen", "only_bytecode", "discard", "import" }
    for _, value_name in ipairs(value_names) do
        if opt[value_name] ~= nil then
            add_values("qt.qml." .. value_name, opt[value_name])
        end
    end
    add_files(args)
end
