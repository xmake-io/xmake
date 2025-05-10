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

-- define rule: win.sdk.resource
rule("win.sdk.resource")
    set_sourcekinds("mrc")
    on_build_files("private.action.build.object", {jobgraph = true, batch = true})

-- define rule: application
rule("win.sdk.application")
    on_load(function (target)
        target:set("kind", "binary")
    end)

    -- set subsystem: windows
    add_deps("platform.windows.subsystem")

    after_load(function (target)
        -- set windows subsystem
        if not target:values("windows.subsystem") then
            target:values_set("windows.subsystem", "windows")
        end

        -- add links
        target:add("syslinks", "kernel32", "user32", "gdi32", "winspool", "comdlg32", "advapi32")
        target:add("syslinks", "shell32", "ole32", "oleaut32", "uuid", "odbc32", "odbccp32", "comctl32")
        target:add("syslinks", "comdlg32", "setupapi", "shlwapi")
        if not target:is_plat("mingw") then
            target:add("syslinks", "strsafe")
        end
    end)
