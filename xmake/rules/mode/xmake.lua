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
rule("mode:debug")
    on_load(function (target)

        -- is debug mode now? xmake f -m debug
        if val("mode") == "debug" then
 
            -- enable the debug symbols
            target:set("symbols", "debug")

            -- disable optimization
            target:set("optimize", "none")
        end
    end)

-- define rule: release mode
rule("mode:release")
    on_load(function (target)

        -- is release mode now? xmake f -m release
        if val("mode") == "release" then
 
            -- set the symbols visibility: hidden
            target:set("symbols", "hidden")

            -- enable fastest optimization
            target:set("optimize", "fastest")

            -- strip all symbols
            target:set("strip", "all")
        end
    end)

