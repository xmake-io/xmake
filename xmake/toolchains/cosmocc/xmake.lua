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

toolchain("cosmocc")
    set_kind("standalone")
    set_homepage("https://github.com/jart/cosmopolitan")
    set_description("build-once run-anywhere c library")

    set_formats("static", "lib$(name).a")
    set_formats("object", "$(name).o")
    set_formats("symbol", "$(name).sym")

    set_toolset("cc",     "cosmocc")
    set_toolset("cxx",    "cosmoc++", "cosmocc")
    set_toolset("cpp",    "cosmocc -E")
    set_toolset("as",     "cosmocc")
    set_toolset("ld",     "cosmoc++", "cosmocc")
    set_toolset("sh",     "cosmoc++", "cosmocc")
    set_toolset("ar",     "cosmoar")

    on_check("check")

    on_load(function (toolchain)
        if toolchain:is_arch("x86_64", "x64") then
            toolchain:set("toolset", "ranlib", "x86_64-linux-cosmo-ranlib")
            toolchain:set("toolset", "strip", "x86_64-linux-cosmo-strip")
        else
            toolchain:set("toolset", "ranlib", "aarch64-linux-cosmo-ranlib")
            toolchain:set("toolset", "strip", "aarch64-linux-cosmo-strip")
        end
        -- @see https://github.com/xmake-io/xmake/issues/5552
        local envs = toolchain:config("envs")
        if envs then
            for k, v in pairs(envs) do
                toolchain:add("runenvs", k, v)
            end
        end
    end)

