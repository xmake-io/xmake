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
toolchain("llvm-mingw")

    -- set homepage
    set_homepage("https://github.com/mstorsjo/llvm-mingw")
    set_description("A LLVM based MinGW toolchain")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- check toolchain
    on_check(function (toolchain)

        -- imports
        import("lib.detect.find_tool")
        import("lib.detect.find_path")
        import("core.project.config")

        -- find sdkdir
        local sdkdir = get_config("mingw") or get_config("sdk")
        if not sdkdir then
            local pathes = {}
            if not is_host("windows") then
                table.insert(pathes, "/opt/llvm-mingw")
            end
            if #pathes > 0 then
                sdkdir = find_path("generic-w64-mingw32", pathes)
            end
        end

        -- save the sdk directory
        if sdkdir then
            config.set("mingw", sdkdir, {force = true, readonly = true})
            cprint("checking for the llvm-mingw directory ... ${color.success}%s", sdkdir)
        else
            cprint("checking for the llvm-mingw directory ... ${color.nothing}${text.nothing}")
        end
        return true
    end)

    -- on load
    on_load(function (toolchain)

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
            cross = config.get("cross") or ""
        end

        -- get sdk directory
        local sdkdir = get_config("mingw") or toolchain:sdkdir()

        -- get bin directory
        local bindir = get_config("bin")
        if not bindir and sdkdir then
            bindir = path.join(sdkdir, "bin")
        end

        -- set toolset
        if is_host("windows") and bindir then
            -- @note we uses bin/ar.exe instead of bin/cross-gcc-ar.exe, @see https://github.com/xmake-io/xmake/issues/807#issuecomment-635779210
            toolchain:add("toolset", "ar", path.join(bindir, "ar"))
            toolchain:add("toolset", "ex", path.join(bindir, "ar"))
            toolchain:add("toolset", "strip", path.join(bindir, "strip"))
            toolchain:add("toolset", "ranlib", path.join(bindir, "ranlib"))
            toolchain:add("toolset", "mrc", path.join(bindir, "windres"))
        end
        toolchain:add("toolset", "cc", cross .. "gcc")
        toolchain:add("toolset", "cxx", cross .. "gcc", cross .. "g++")
        toolchain:add("toolset", "cpp", cross .. "gcc -E")
        toolchain:add("toolset", "as", cross .. "gcc")
        toolchain:add("toolset", "ld", cross .. "g++", cross .. "gcc")
        toolchain:add("toolset", "sh", cross .. "g++", cross .. "gcc")
        toolchain:add("toolset", "ar", cross .. "ar")
        toolchain:add("toolset", "ex", cross .. "ar")
        toolchain:add("toolset", "strip", cross .. "strip")
        toolchain:add("toolset", "ranlib", cross .. "ranlib")
        toolchain:add("toolset", "mrc", cross .. "windres")

        -- init flags
        toolchain:set("cxflags", "")
        toolchain:set("mxflags", "")
        toolchain:set("asflags", "")
        toolchain:set("ldflags", "")
        toolchain:set("shflags", "")

        -- add include directories
        if sdkdir then
            toolchain:add("includedirs", path.join(sdkdir, "generic-w64-mingw32", "include"))
            toolchain:add("includedirs", path.join(sdkdir, "generic-w64-mingw32", "include", "c++", "v1"))
        end
    end)
