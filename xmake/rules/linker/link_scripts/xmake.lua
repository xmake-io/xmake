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

rule("linker.link_scripts")
    set_extensions(".ld", ".lds")
    on_config(function (target)
        if not target:is_binary() and not target:is_shared() then
            return
        end
        local scriptfile
        local sourcebatch = target:sourcebatches()["linker.link_scripts"]
        if sourcebatch then
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                scriptfile = sourcefile
                break
            end
        end
        if not scriptfile then
            return
        end
        -- @note apple's linker does not support it
        if target:is_plat("macosx", "iphoneos", "watchos", "appletvos") then
            return
        end
        if target:has_tool("ld", "gcc", "gxx", "clang", "clangxx") or
            target:has_tool("sh", "gcc", "gxx", "clang", "clangxx") then
            target:add(target:is_shared() and "shflags" or "ldflags", "-T " .. scriptfile, {force = true})
        elseif target:has_tool("ld", "ld") or target:has_tool("sh", "ld") then
            target:add(target:is_shared() and "shflags" or "ldflags", "-T " .. scriptfile, {force = true})
        end
    end)

