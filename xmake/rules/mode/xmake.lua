--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: debug mode
rule("mode.debug")
    on_load(function (target)

        -- is debug mode now? xmake f -m debug
        if is_mode("debug") then
 
            -- enable the debug symbols
            target:set("symbols", "debug")

            -- disable optimization
            target:set("optimize", "none")
        end
    end)

-- define rule: release mode
rule("mode.release")
    on_load(function (target)

        -- is release mode now? xmake f -m release
        if is_mode("release") then
 
            -- set the symbols visibility: hidden
            target:set("symbols", "hidden")

            -- enable fastest optimization
            target:set("optimize", "fastest")

            -- strip all symbols
            target:set("strip", "all")
        end
    end)

-- define rule: profile mode
rule("mode.profile")
    on_load(function (target)

        -- is profile mode now? xmake f -m profile
        if is_mode("profile") then
 
            -- set the symbols visibility: debug
            target:set("symbols", "debug")

            -- enable fastest optimization
            target:set("optimize", "fastest")

            -- enable gprof 
            target:add("cxflags", "-pg")
            target:add("mxflags", "-pg")
            target:add("ldflags", "-pg")
        end
    end)

-- define rule: check mode
rule("mode.check")
    on_load(function (target)

        -- is check mode now? xmake f -m check
        if is_mode("check") then
 
            -- enable the debug symbols
            target:set("symbols", "debug")

            -- disable optimization
            target:set("optimize", "none")

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
    on_load(function (target)

        -- is coverage mode now? xmake f -m coverage
        if is_mode("coverage") then
 
            -- enable the debug symbols
            target:set("symbols", "debug")

            -- disable optimization
            target:set("optimize", "none")

            -- enable coverage
            target:add("cxflags", "--coverage")
            target:add("mxflags", "--coverage")
            target:add("ldflags", "--coverage")
        end
    end)
