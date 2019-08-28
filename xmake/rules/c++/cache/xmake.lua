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

-- define rule: cpp.cache
rule("cpp.cache")

    -- we attempt to use ccache now
    -- maybe we will implement cross-platform cache in the future 
    before_load(function (target)

        -- imports
        import("lib.detect.find_tool")

        -- find ccache
        local ccache = target:data("cpp.ccache")
        if not ccache and config.get("ccache") then
            ccache = find_tool("ccache")
            target:data_set("cpp.ccache", ccache)
        end

        -- add the prefix information of building object  
        --
        -- e.g. 
        -- [  0%]: ccache compiling.release src/xxx.c
        --
        if ccache then
            target:data_set("build.object.prefix", "ccache")
        end
    end)
