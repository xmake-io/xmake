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

-- define rule: lex 
rule("lex")

    -- set externsion
    set_extensions(".l", ".ll")

    -- load lex/flex
    before_load(function (target)
        import("core.project.config")
        import("lib.detect.find_tool")
        local lex = config.get("lex")
        if not lex then
            lex = find_tool("flex") or find_tool("lex")
            if lex and lex.program then
                config.set("lex", lex.program)
                cprint("checking for the Lex ... ${color.success}%s", lex.program)
            else
                cprint("checking for the Lex ... ${color.nothing}${text.nothing}")
            end
        end
    end)

    -- build lex file
    on_build_file(function (target, sourcefile_lex, opt)
    end)
