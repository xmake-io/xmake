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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: yacc 
rule("yacc")

    -- set externsion
    set_extensions(".y", ".yy")

    -- load yacc/bison
    before_load(function (target)
        import("core.project.config")
        import("lib.detect.find_tool")
        local yacc = config.get("yacc")
        if not yacc then
            yacc = find_tool("bison") or find_tool("yacc")
            if yacc and yacc.program then
                config.set("yacc", yacc.program)
                cprint("checking for the Yacc ... ${color.success}%s", yacc.program)
            else
                cprint("checking for the Yacc ... ${color.nothing}${text.nothing}")
            end
        end
    end)
