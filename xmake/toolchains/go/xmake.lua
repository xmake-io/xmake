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
-- Copyright (C) 2015-present, Xmake Open Source Community.
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
    -- Modern Go uses "go" command for all operations
    set_toolset("gc",   "$(env GC)", "go")
    set_toolset("gcld", "$(env GC)", "go")
    set_toolset("gcar", "$(env GC)", "go")

    -- on load
    on_load(function (toolchain)
        import("private.tools.go.goenv")

        -- set GOOS and GOARCH for cross-compilation
        local goos = goenv.GOOS(toolchain:plat())
        if goos then
            toolchain:add("runenvs", "GOOS", goos)
        end

        local goarch = goenv.GOARCH(toolchain:arch())
        if goarch then
            toolchain:add("runenvs", "GOARCH", goarch)
        end

        -- Set CGO_ENABLED=0 by default for better cross-compilation support
        -- Users can override this if they need CGO
        if not os.getenv("CGO_ENABLED") then
            toolchain:add("runenvs", "CGO_ENABLED", "0")
        end

        -- Disable Go modules mode to use GOPATH mode
        -- This allows Go to find packages using GOPATH
        if not os.getenv("GO111MODULE") then
            toolchain:add("runenvs", "GO111MODULE", "off")
        end

        -- Set GOPATH to project directory if not already set
        -- This allows Go to find packages in the project
        if not os.getenv("GOPATH") then
            local projectdir = os.projectdir()
            if projectdir then
                toolchain:add("runenvs", "GOPATH", projectdir)
            end
        end

        -- set default flags
        toolchain:set("gcldflags", "")
        toolchain:set("gcarflags", "")
    end)
