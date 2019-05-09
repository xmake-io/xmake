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

-- define rule: debug mode
rule("mode.debug")
    after_load(function (target)

        -- is debug mode now? xmake f -m debug
        if is_mode("debug") then
 
            -- enable the debug symbols
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- disable optimization
            if not target:get("optimize") then
                target:set("optimize", "none")
            end
        end
    end)

-- define rule: release mode
rule("mode.release")
    after_load(function (target)

        -- is release mode now? xmake f -m release
        if is_mode("release") then
 
            -- set the symbols visibility: hidden
            if not target:get("symbols") and target:targetkind() ~= "shared" then
                target:set("symbols", "hidden")
            end

            -- enable fastest optimization
            if not target:get("optimize") then
                target:set("optimize", "fastest")
            end

            -- strip all symbols
            if not target:get("strip") then
                target:set("strip", "all")
            end
        end
    end)

-- define rule: profile mode
rule("mode.profile")
    after_load(function (target)

        -- is profile mode now? xmake f -m profile
        if is_mode("profile") then
 
            -- set the symbols visibility: debug
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- enable fastest optimization
            if not target:get("optimize") then
                target:set("optimize", "fastest")
            end

            -- enable gprof 
            target:add("cxflags", "-pg")
            target:add("mxflags", "-pg")
            target:add("ldflags", "-pg")
        end
    end)

-- define rule: check mode
rule("mode.check")
    after_load(function (target)

        -- is check mode now? xmake f -m check
        if is_mode("check") then
 
            -- enable the debug symbols
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- disable optimization
            if not target:get("optimize") then
                target:set("optimize", "none")
            end

            -- attempt to enable some checkers for pc
            if is_mode("check") and is_arch("i386", "x86_64") then
                target:add("cxflags", "-fsanitize=address", "-ftrapv")
                target:add("mxflags", "-fsanitize=address", "-ftrapv")
                target:add("ldflags", "-fsanitize=address")
            end
        end
    end)

-- define rule: coverage mode
rule("mode.coverage")
    after_load(function (target)

        -- is coverage mode now? xmake f -m coverage
        if is_mode("coverage") then
 
            -- enable the debug symbols
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end

            -- disable optimization
            if not target:get("optimize") then
                target:set("optimize", "none")
            end

            -- enable coverage
            target:add("cxflags", "--coverage")
            target:add("mxflags", "--coverage")
            target:add("ldflags", "--coverage")
        end
    end)
