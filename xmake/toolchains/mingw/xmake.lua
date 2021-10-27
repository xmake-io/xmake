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

-- define toolchain
toolchain("mingw")

    -- set homepage
    set_homepage("http://www.mingw.org/")
    set_description("Minimalist GNU for Windows")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- check toolchain
    on_check("check")

    -- on load
    on_load(function (toolchain)

        -- imports
        import("core.project.config")

        -- get cross
        local cross
        if toolchain:is_arch("x86_64", "x64") then
            cross = "x86_64-w64-mingw32-"
        elseif toolchain:is_arch("i386", "x86", "i686") then
            cross = "i686-w64-mingw32-"
        elseif toolchain:is_arch("arm64", "aarch64") then
            cross = "aarch64-w64-mingw32-"
        elseif toolchain:is_arch("armv7", "arm.*") then
            cross = "armv7-w64-mingw32-"
        else
            cross = toolchain:cross() or ""
        end

        -- add bin search library for loading some dependent .dll files windows
        local bindir = toolchain:bindir()
        if bindir and is_host("windows") then
            toolchain:add("runenvs", "PATH", bindir)
        end

        -- set toolset
        if is_host("windows") and bindir then
            -- @note we uses bin/ar.exe instead of bin/cross-gcc-ar.exe, @see https://github.com/xmake-io/xmake/issues/807#issuecomment-635779210
            toolchain:add("toolset", "ar", path.join(bindir, "ar"))
            toolchain:add("toolset", "strip", path.join(bindir, "strip"))
            toolchain:add("toolset", "ranlib", path.join(bindir, "ranlib"))
        end
        toolchain:add("toolset", "cc", cross .. "gcc")
        toolchain:add("toolset", "cxx", cross .. "g++", cross .. "gcc")
        toolchain:add("toolset", "cpp", cross .. "gcc -E")
        toolchain:add("toolset", "as", cross .. "gcc")
        toolchain:add("toolset", "ld", cross .. "g++", cross .. "gcc")
        toolchain:add("toolset", "sh", cross .. "g++", cross .. "gcc")
        toolchain:add("toolset", "ar", cross .. "ar")
        toolchain:add("toolset", "strip", cross .. "strip")
        toolchain:add("toolset", "ranlib", cross .. "ranlib")
        toolchain:add("toolset", "mrc", cross .. "windres")
        if is_host("windows") and bindir then
            -- we use bin/gcc.exe if cross not found
            -- @see https://github.com/xmake-io/xmake/issues/977#issuecomment-704863677
            toolchain:add("toolset", "cc", path.join(bindir, "gcc"))
            toolchain:add("toolset", "cxx", path.join(bindir, "g++"), path.join(bindir, "gcc"))
            toolchain:add("toolset", "cpp", path.join(bindir, "gcc -E"))
            toolchain:add("toolset", "as", path.join(bindir, "gcc"))
            toolchain:add("toolset", "ld", path.join(bindir, "g++"), path.join(bindir, "gcc"))
            toolchain:add("toolset", "sh", path.join(bindir, "g++"), path.join(bindir, "gcc"))
            toolchain:add("toolset", "mrc", path.join(bindir, "windres"))
        end

        -- init flags for architecture
        local archflags = nil
        local arch = toolchain:arch()
        if arch == "x86_64" then archflags = "-m64"
        elseif arch == "i386" then archflags = "-m32"
        end
        if archflags then
            toolchain:add("cxflags", archflags)
            toolchain:add("asflags", archflags)
            toolchain:add("ldflags", archflags)
            toolchain:add("shflags", archflags)
        end
    end)
