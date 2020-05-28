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

        -- TODO add to environment module
        -- add bin search library for loading some dependent .dll files windows 
        local bindir = toolchain:bindir()
        if bindir and is_host("windows") then
            os.addenv("PATH", bindir)
        end

        -- set toolsets
        toolchain:set("toolsets", "cc", cross .. "gcc")
        toolchain:set("toolsets", "cxx", cross .. "gcc", cross .. "g++")
        toolchain:set("toolsets", "cpp", cross .. "gcc -E")
        toolchain:set("toolsets", "as", cross .. "gcc")
        toolchain:set("toolsets", "ld", cross .. "g++", cross .. "gcc")
        toolchain:set("toolsets", "sh", cross .. "g++", cross .. "gcc")
        toolchain:set("toolsets", "ar", cross .. "ar", cross .. "gcc-ar")
        toolchain:set("toolsets", "ex", cross .. "ar", cross .. "gcc-ar")
        toolchain:set("toolsets", "ranlib", cross .. "ranlib", cross .. "gcc-ranlib")
        toolchain:set("toolsets", "mrc", cross .. "windres")

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
