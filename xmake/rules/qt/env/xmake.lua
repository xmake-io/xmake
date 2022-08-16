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
-- @file        xmake.lua
--

rule("qt.env")
    on_load(function (target)

        -- imports
        import("detect.sdks.find_qt")

        -- find qt sdk
        local qt = target:data("qt")
        if not qt then
            qt = assert(find_qt(nil, {verbose = true}), "Qt SDK not found!")
            target:data_set("qt", qt)
        end

        local qmlimportpath = target:values("qt.env.qmlimportpath") or {}
        if target:is_plat("windows") or (target:is_plat("mingw") and is_host("windows")) then
            target:add("runenvs", "PATH", qt.bindir)
            table.insert(qmlimportpath, qt.qmldir)
            -- add targetdir in QML2_IMPORT_PATH in case of the user have qml plugins
            table.insert(qmlimportpath, target:targetdir())
            target:set("runenv", "QML_IMPORT_TRACE", "1")
        elseif target:is_plat("msys", "cygwin") then
            raise("please run `xmake f -p mingw --mingw=/mingw64` to support Qt/Mingw64 on Msys!")
        end
        target:set("runenv", "QML2_IMPORT_PATH", qmlimportpath)
    end)


