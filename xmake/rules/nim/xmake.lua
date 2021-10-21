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

-- define rule: nim.build
rule("nim.build")
    set_sourcekinds("nc")
    on_load(function (target)
        local cachedir = path.join(target:autogendir(), "nimcache")
        target:add("ncflags", "--nimcache:" .. cachedir, {force = true})
    end)
    on_build("build.target")

-- define rule: nim
rule("nim")

    -- add build rules
    add_deps("nim.build")

    -- inherit links and linkdirs of all dependent targets by default
    add_deps("utils.inherit.links")
