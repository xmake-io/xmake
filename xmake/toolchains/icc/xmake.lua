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
toolchain("icc")

    -- set homepage
    set_homepage("https://software.intel.com/content/www/us/en/develop/tools/compilers/c-compilers.html")
    set_description("Intel C/C++ Compiler")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- check toolchain
    on_check(function (toolchain)
        return import("lib.detect.find_tool")(toolchain:is_plat("windows") and "icl" or "icc")
    end)

    -- on load
    on_load(function (toolchain)

        -- set toolset
        if toolchain:is_plat("windows") then
            toolchain:set("toolset", "cc", "icl.exe")
            toolchain:set("toolset", "cxx", "icl.exe")
            toolchain:set("toolset", "mrc", "rc.exe")
            if toolchain:is_arch("x64") then
                toolchain:set("toolset", "as",  "ml64.exe")
            else
                toolchain:set("toolset", "as",  "ml.exe")
            end
            toolchain:set("toolset", "ld",  "link.exe")
            toolchain:set("toolset", "sh",  "link.exe")
            toolchain:set("toolset", "ar",  "link.exe")
            toolchain:set("toolset", "ex",  "lib.exe")
        else
            toolchain:set("toolset", "cc", "icc")
            toolchain:set("toolset", "cxx", "icpc", "icc")
            toolchain:set("toolset", "ld", "icpc", "icc")
            toolchain:set("toolset", "sh", "icpc", "icc")
            toolchain:set("toolset", "ar", "ar")
            toolchain:set("toolset", "ex", "ar")
            toolchain:set("toolset", "strip", "strip")
            toolchain:set("toolset", "as", "icc")
        end

        -- add march flags
        local march
        if toolchain:is_arch("x86_64", "x64") then
            march = "-m64"
        elseif toolchain:is_arch("i386", "x86") then
            march = "-m32"
        end
        if march then
            toolchain:add("cxflags", march)
            toolchain:add("mxflags", march)
            toolchain:add("asflags", march)
            toolchain:add("ldflags", march)
            toolchain:add("shflags", march)
        end

        -- add includedirs and linkdirs
        if not toolchain:is_plat("windows") and os.isdir("/usr") then
            for _, includedir in ipairs({"/usr/local/include", "/usr/include"}) do
                if os.isdir(includedir) then
                    toolchain:add("includedirs", includedir)
                end
            end
            for _, linkdir in ipairs({"/usr/local/lib", "/usr/lib"}) do
                if os.isdir(linkdir) then
                    toolchain:add("linkdirs", linkdir)
                end
            end
        end
    end)
