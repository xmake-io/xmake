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
toolchain("tinyc")

    -- set homepage
    set_homepage("https://bellard.org/tcc/")
    set_description("Tiny C Compiler")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- set toolset
    set_toolset("cc",     "tcc")
    set_toolset("ld",     "tcc")
    set_toolset("sh",     "tcc")
    set_toolset("ar",     "tcc")

    -- check toolchain
    on_check(function (toolchain)

        -- imports
        import("core.project.config")
        import("lib.detect.find_tool")

        -- find tcc
        local sdkdir = config.get("sdk")
        if not sdkdir and is_host("windows") then
            local winenv_tccsdk = path.join(os.programdir(), "winenv", "tcc")
            if os.isdir(winenv_tccsdk) then
                sdkdir = winenv_tccsdk
            end
        end
        if find_tool("tcc", {paths = config.get("bin") or sdkdir}) then
            config.set("__tcc_sdkdir", sdkdir)
            return true
        end
    end)

    -- on load
    on_load(function (toolchain)

        -- imports
        import("core.project.config")

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

        -- init linkdirs and includedirs
        local sdkdir = config.get("__tcc_sdkdir") or toolchain:sdkdir()
        if sdkdir then
            local includedir = path.join(sdkdir, "include")
            if os.isdir(includedir) then
                toolchain:add("includedirs", includedir)
            end
            local winenv_tcc_winapi = path.join(os.programdir(), "winenv", "tcc", "winapi", "include")
            if is_host("windows") and os.isdir(winenv_tcc_winapi) then
                toolchain:add("includedirs", winenv_tcc_winapi)
                toolchain:add("includedirs", path.join(winenv_tcc_winapi, "winapi"))
            end
            local linkdir = path.join(sdkdir, "lib")
            if os.isdir(linkdir) then
                toolchain:add("linkdirs", linkdir)
            end
        end
    end)
