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
-- Copyright (C) 2015-present, TBOOX Open Sousce Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define toolchain
toolchain("swift")

    -- set homepage
    set_homepage("https://swift.org/")
    set_description("Swift Programming Language Compiler")

    -- set toolset
    set_toolset("sc",   "$(env SC)", "swift-frontend", "swiftc")
    set_toolset("scsh", "$(env SC)", "swiftc")
    set_toolset("scar", "$(env SC)", "swiftc")
    set_toolset("scld", "$(env SC)", "swiftc")

    -- on load
    on_load(function (toolchain)
        if toolchain:is_plat("macosx") then
            if not toolchain:config("xcode_sysroot") then
                local xcode_dir     = get_config("xcode")
                local xcode_sdkver  = toolchain:config("xcode_sdkver")
                local xcode_sdkdir  = path.join(xcode_dir, "Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX" .. xcode_sdkver .. ".sdk")
                if os.isdir(xcode_sdkdir) then
                    toolchain:config_set("xcode_sysroot", xcode_sdkdir)
                end
            end
            -- load configurations
            import(".xcode.load_" .. toolchain:plat())(toolchain)
        end
    end)
