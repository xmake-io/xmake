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

toolchain("mingw")
    set_kind("standalone")
    set_homepage("http://www.mingw.org/")
    set_description("Minimalist GNU for Windows")
    set_runtimes("stdc++_static", "stdc++_shared")

    on_check("check")
    on_load(function (toolchain)

        -- use clang for llvm-mingw?
        local use_clang = toolchain:config("clang")

        -- get cross
        -- https://github.com/xmake-io/xmake/issues/7196
        local cross = toolchain:cross() or ""
        if cross ~= "" then
            local arch
            if cross:startswith("x86_64") then
                arch = "x86_64"
            elseif cross:startswith("i686") then
                arch = "i386"
            elseif cross:startswith("aarch64") then
                arch = "arm64"
            elseif cross:startswith("arm") then
                arch = "armv7"
            end
            if arch then
                toolchain:arch_set(arch)
            end
        else
            if toolchain:is_arch("x86_64", "x64") then
                cross = "x86_64-w64-mingw32-"
            elseif toolchain:is_arch("i386", "x86", "i686") then
                cross = "i686-w64-mingw32-"
            elseif toolchain:is_arch("arm64", "aarch64") then
                cross = "aarch64-w64-mingw32-"
            elseif toolchain:is_arch("armv7", "arm.*") then
                cross = "armv7-w64-mingw32-"
            end
        end

        -- add bin search library for loading some dependent .dll files windows
        local bindir = toolchain:bindir()
        if bindir and is_host("windows") then
            toolchain:add("runenvs", "PATH", bindir)
        end

        -- set toolset
        local cc = use_clang and "clang" or "gcc"
        local cxx = use_clang and "clang++" or "g++"
        local ar = use_clang and "llvm-ar" or "ar"
        local ranlib = use_clang and "llvm-ranlib" or "ranlib"
        if is_host("windows") and bindir then
            -- @note we uses bin/ar.exe instead of bin/cross-gcc-ar.exe, @see https://github.com/xmake-io/xmake/issues/807#issuecomment-635779210
            toolchain:add("toolset", "ar", path.join(bindir, ar))
            toolchain:add("toolset", "strip", path.join(bindir, "strip"))
            toolchain:add("toolset", "ranlib", path.join(bindir, ranlib))
            toolchain:add("toolset", "objcopy", path.join(bindir, "objcopy"))
        end
        toolchain:add("toolset", "cc", cross .. cc)
        toolchain:add("toolset", "cxx", cross .. cxx, cross .. cc)
        toolchain:add("toolset", "cpp", cross .. cc .. " -E")
        toolchain:add("toolset", "as", cross .. cc)
        toolchain:add("toolset", "ld", cross .. cxx, cross .. cc)
        toolchain:add("toolset", "sh", cross .. cxx, cross .. cc)
        toolchain:add("toolset", "ar", cross .. ar)
        toolchain:add("toolset", "strip", cross .. "strip")
        toolchain:add("toolset", "ranlib", cross .. ranlib)
        toolchain:add("toolset", "objcopy", cross .. "objcopy")
        toolchain:add("toolset", "mrc", cross .. "windres")
        toolchain:add("toolset", "dlltool", cross .. "dlltool")
        if is_host("windows") and bindir then
            -- we use bin/gcc.exe if cross not found
            -- @see https://github.com/xmake-io/xmake/issues/977#issuecomment-704863677
            toolchain:add("toolset", "cc", path.join(bindir, cc))
            toolchain:add("toolset", "cxx", path.join(bindir, cxx), path.join(bindir, cc))
            toolchain:add("toolset", "cpp", path.join(bindir, cc .. " -E"))
            toolchain:add("toolset", "as", path.join(bindir, cc))
            toolchain:add("toolset", "ld", path.join(bindir, cxx), path.join(bindir, cc))
            toolchain:add("toolset", "sh", path.join(bindir, cxx), path.join(bindir, cc))
            toolchain:add("toolset", "mrc", path.join(bindir, "windres"))
            toolchain:add("toolset", "dlltool", path.join(bindir, "dlltool"))
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
