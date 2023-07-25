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

rule("linker.soname")
    on_config(function (target)
        local soname = target:soname()
        if target:is_shared() and soname then
            if target:has_tool("sh", "gcc", "gxx", "clang", "clangxx") then
                if target:is_plat("macosx", "iphoneos", "watchos", "appletvos") then
                    target:add("shflags", "-Wl,-install_name," .. soname, {force = true})
                else
                    target:add("shflags", "-Wl,-soname," .. soname, {force = true})
                end
            end
        end
    end)

