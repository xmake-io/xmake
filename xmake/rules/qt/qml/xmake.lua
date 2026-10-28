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
-- @file        xmake.lua
--

-- define rule: qt.qml
--
-- It packs the QML module resources and compiles them with qmlcachegen/qmltc.
rule("qt.qml")
    add_deps("qt.env", "qt.qrc")
    -- generate the qml qrc before qt.qrc compiles it
    add_orders("qt.qml", "qt.qrc")

    on_load("load")
    on_config("config")
    on_buildcmd_files("build")

-- define rule: qt.qml.resource
--
-- It packs the module resources, the files are compiled by qt.qrc.
rule("qt.qml.resource")
    on_prepare_files("resource")
