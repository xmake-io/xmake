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
        if is_arch("x86_64") then
            cross = "x86_64-w64-mingw32-"
        elseif is_arch("i386") then
            cross = "i686-w64-mingw32-"
        else
            cross = config.get("cross") or ""
        end

        -- add bin search library for loading some dependent .dll files windows 
        local bindir = toolchain:bindir()
        if bindir and is_host("windows") then
            toolchain:add("runenvs", "PATH", bindir)
        end

        -- set toolsets
        if is_host("windows") and bindir then
            -- @note we uses bin/ar.exe instead of bin/cross-gcc-ar.exe, @see https://github.com/xmake-io/xmake/issues/807#issuecomment-635779210
            toolchain:add("toolsets", "ar", path.join(bindir, "ar"))
            toolchain:add("toolsets", "ex", path.join(bindir, "ar"))
            toolchain:add("toolsets", "strip", path.join(bindir, "strip"))
            toolchain:add("toolsets", "ranlib", path.join(bindir, "ranlib"))
        end
        toolchain:add("toolsets", "cc", cross .. "gcc")
        toolchain:add("toolsets", "cxx", cross .. "gcc", cross .. "g++")
        toolchain:add("toolsets", "cpp", cross .. "gcc -E")
        toolchain:add("toolsets", "as", cross .. "gcc")
        toolchain:add("toolsets", "ld", cross .. "g++", cross .. "gcc")
        toolchain:add("toolsets", "sh", cross .. "g++", cross .. "gcc")
        toolchain:add("toolsets", "ar", cross .. "ar")
        toolchain:add("toolsets", "ex", cross .. "ar")
        toolchain:add("toolsets", "strip", cross .. "strip")
        toolchain:add("toolsets", "ranlib", cross .. "ranlib")
        toolchain:add("toolsets", "mrc", cross .. "windres")

        -- init flags for architecture
        local archflags = nil
        local arch = config.get("arch")
        if arch then
            if arch == "x86_64" then archflags = "-m64"
            elseif arch == "i386" then archflags = "-m32"
            else archflags = "-arch " .. arch
            end
        end
        if archflags then
            toolchain:add("cxflags", archflags)
            toolchain:add("asflags", archflags)
            toolchain:add("ldflags", archflags)
            toolchain:add("shflags", archflags)
        end
    end)
