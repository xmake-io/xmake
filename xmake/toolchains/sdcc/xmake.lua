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
toolchain("sdcc")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- set toolsets
    set_toolsets("cc",  "sdcc")
    set_toolsets("cxx", "sdcc")
    set_toolsets("cpp", "sdcpp")
    set_toolsets("as",  "sdcc")
    set_toolsets("ld",  "sdcc")
    set_toolsets("sh",  "sdcc")
    set_toolsets("ar",  "sdar")
    set_toolsets("ex",  "sdar")

    -- set archs
    set_archs("stm8", "mcs51", "z80", "z180", "r2k", "r3ka", "s08", "hc08")

    -- set formats
    set_formats {static = "$(name).lib", object = "$(name).rel", binary = "$(name).bin", symbol = "$(name).sym"}
       
    -- check toolchain
    on_check("check")

    -- on load
    on_load(function (toolchain)

        -- init linkdirs and includedirs
        local sdkdir = toolchain:sdkdir()
        if sdkdir then
            local includedir = path.join(sdkdir, "include")
            if os.isdir(includedir) then
                toolchain:add("includedirs", includedir)
            end
            local linkdir = path.join(sdkdir, "lib")
            if os.isdir(linkdir) then
                toolchain:add("linkdirs", linkdir)
            end
        end

        -- add port flags for arch
        local arch = get_config("arch")
        if arch then
            toolchain:add("cxflags", "-m" .. arch)
            toolchain:add("ldflags", "-m" .. arch)
        end
    end)
