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

-- add *.def for windows/dll
rule("platform.windows.def")
    set_extensions(".def")

    before_buildcmd_file("windows", "mingw", function (target, batchcmds, sourcefile, opt)
        if not target:is_shared() then
            return
        end

        if target:is_plat("windows") and (not target:has_tool("sh", "link")) then
            return
        end

        local flag = path.translate(sourcefile)
        if target:is_plat("windows") then
            flag = "/def:" .. flag
        end
        target:add("shflags", flag, {force = true})

        batchcmds:mkdir(target:targetdir())
        batchcmds:add_depfiles(sourcefile)
        batchcmds:set_depmtime(os.mtime(target:targetfile()))
        batchcmds:set_depcache(target:dependfile(target:targetfile()))
    end)
