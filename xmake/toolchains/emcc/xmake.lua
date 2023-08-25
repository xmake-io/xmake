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

toolchain("emcc")

    set_homepage("http://emscripten.org")
    set_description("A toolchain for compiling to asm.js and WebAssembly")

    set_kind("standalone")

    local suffix = is_host("windows") and ".bat" or ""
    set_toolset("cc", "emcc" .. suffix)
    set_toolset("cxx", "emcc" .. suffix, "em++" .. suffix)
    set_toolset("ld", "em++" .. suffix, "emcc" .. suffix)
    set_toolset("sh", "em++" .. suffix, "emcc" .. suffix)
    set_toolset("ar", "emar" .. suffix)
    set_toolset("as", "emcc" .. suffix)
    set_toolset("ranlib", "emranlib" .. suffix)

    on_check(function (toolchain)
        import("lib.detect.find_tool")
        for _, package in ipairs(toolchain:packages()) do
            local installdir = package:installdir()
            if installdir and os.isdir(installdir) then
                local sdkdir = installdir
                local bindir = path.join(sdkdir, "upstream/emscripten")
                local emcc = find_tool("emcc", {force = true, paths = bindir})
                if emcc then
                    toolchain:config_set("bindir", bindir)
                    toolchain:config_set("sdkdir", sdkdir)
                    toolchain:configs_save()
                    return emcc
                end
            end
        end
        return find_tool("emcc")
    end)

    on_load(function (toolchain)
        toolchain:add("cxflags", "")
        toolchain:add("asflags", "")
        toolchain:add("ldflags", "")
        toolchain:add("shflags", "")
    end)

