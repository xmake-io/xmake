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

    -- set toolset
    set_toolset("cc",     "clang")
    set_toolset("cxx",    "clang", "clang++")
    set_toolset("cpp",    "clang -E")
    set_toolset("as",     "clang")
    set_toolset("ld",     "clang++", "clang")
    set_toolset("sh",     "clang++", "clang")
    set_toolset("ar",     "llvm-ar")
    set_toolset("ex",     "llvm-ar")
    set_toolset("ranlib", "llvm-ranlib")
    set_toolset("strip",  "llvm-strip")
       
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

        -- find clang
        local bindir = get_config("bin")
        if not bindir and sdkdir then
            bindir = path.join(sdkdir, "bin")
        end
        if not find_tool("clang", {pathes = bindir}) then
            return
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

        -- add target flags
        local target
        if toolchain:is_arch("x86_64", "x64") then
            target = "x86_64-w64-mingw32"
        elseif toolchain:is_arch("i386", "x86", "i686") then
            target = "i686-w64-mingw32"
        elseif toolchain:is_arch("arm64", "aarch64") then
            target = "aarch64-w64-mingw32"
        elseif toolchain:is_arch("armv7", "arm.*") then
            target = "armv7-w64-mingw32"
        else
            raise("llvm-mingw: unknown architecture(%s)!", toolchain:arch())
        end
        toolchain:add("cxflags", "-target", target)
        toolchain:add("mxflags", "-target", target)
        toolchain:add("asflags", "-target", target)
        toolchain:add("ldflags", "-target", target)
        toolchain:add("shflags", "-target", target)

        -- get sdk directory
        local sdkdir = get_config("mingw")
        if sdkdir then
            toolchain:add("includedirs", path.join(sdkdir, "generic-w64-mingw32", "include"))
            toolchain:add("includedirs", path.join(sdkdir, "generic-w64-mingw32", "include", "c++", "v1"))
        end
    end)
