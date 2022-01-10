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
    on_build_files("private.action.build.object", {batch = true})

-- define rule: application
rule("win.sdk.application")

    -- before load
    on_load(function (target)
        target:set("kind", "binary")
    end)

    -- after load
    after_load(function (target)

        -- set subsystem: windows
        if is_plat("mingw") then
            target:add("ldflags", "-mwindows", {force = true})
        else
            local subsystem = false
            for _, ldflag in ipairs(target:get("ldflags")) do
                ldflag = ldflag:lower()
                if ldflag:find("[/%-]subsystem:") then
                    subsystem = true
                    break
                end
            end
            if not subsystem then
                target:add("ldflags", "-subsystem:windows", {force = true})
            end
        end

        -- add links
        target:add("syslinks", "kernel32", "user32", "gdi32", "winspool", "comdlg32", "advapi32")
        target:add("syslinks", "shell32", "ole32", "oleaut32", "uuid", "odbc32", "odbccp32", "comctl32")
        target:add("syslinks", "comdlg32", "setupapi", "shlwapi")
        if not is_plat("mingw") then
            target:add("syslinks", "strsafe")
        end
    end)
