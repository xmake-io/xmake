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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define toolchain
toolchain("go")

    -- set homepage
    set_homepage("https://golang.org/")
    set_description("Go Programming Language Compiler")

    -- set toolset
    set_toolset("gc",   "$(env GC)", "go", "gccgo")
    set_toolset("gcld", "$(env GC)", "go", "gccgo")
    set_toolset("gcar", "$(env GC)", "go", "gccgo")

    -- on load
    on_load(function (toolchain)
        if not toolchain:is_plat(os.host()) or not toolchain:is_arch(os.arch()) then
            import("private.tools.go.goenv")
            local goos = goenv.GOOS(toolchain:plat())
            if goos then
                toolchain:add("runenvs", "GOOS", goos)
            end
            local goarch = goenv.GOARCH(toolchain:arch())
            if goarch then
                toolchain:add("runenvs", "GOARCH", goarch)
            end
        end
        toolchain:set("gcldflags", "")
    end)

