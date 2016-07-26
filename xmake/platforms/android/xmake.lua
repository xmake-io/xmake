--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define platform
platform("android")

    -- set os
    set_os("android")

    -- set hosts
    set_hosts("macosx", "linux", "windows")

    -- set archs
    set_archs("armv5te", "armv6", "armv7-a", "armv8-a", "arm64-v8a")

    -- set checker
    set_checker("checker")

    -- set tooldirs
    set_tooldirs("/usr/bin", "/usr/local/bin", "/opt/bin", "/opt/local/bin")

    -- on load
    on_load(function ()

        -- imports
        import("core.project.config")
       
        -- init the file formats
        _g.formats          = {}
        _g.formats.static   = {"lib", ".a"}
        _g.formats.object   = {"",    ".o"}
        _g.formats.shared   = {"lib", ".so"}
        _g.formats.symbol   = {"",    ".sym"}
    
        -- init flags
        local arch = config.get("arch")
        if arch:startswith("arm64") then
            _g.cxflags      = {}
            _g.asflags      = {}
            _g.ldflags      = {"-llog"}
            _g.shflags      = {"-llog"}
        else
            _g.cxflags      = { "-march=" .. arch, "-mthumb"}
            _g.asflags      = { "-march=" .. arch, "-mthumb"}
            _g.ldflags      = { "-march=" .. arch, "-llog", "-mthumb"}
            _g.shflags      = { "-march=" .. arch, "-llog", "-mthumb"}
        end

        -- add flags for the sdk directory of ndk
        local ndk = config.get("ndk")
        local ndk_sdkver = config.get("ndk_sdkver")
        if ndk and ndk_sdkver then
            local ndk_sdkdir = path.translate(format("%s/platforms/android-%d", ndk, ndk_sdkver)) 
            if arch:startswith("arm64") then
                insert(_g.cxflags, format("--sysroot=%s/arch-arm64", ndk_sdkdir))
                insert(_g.asflags, format("--sysroot=%s/arch-arm64", ndk_sdkdir))
                insert(_g.ldflags, format("--sysroot=%s/arch-arm64", ndk_sdkdir))
                insert(_g.shflags, format("--sysroot=%s/arch-arm64", ndk_sdkdir))
            else
                insert(_g.cxflags, format("--sysroot=%s/arch-arm", ndk_sdkdir))
                insert(_g.asflags, format("--sysroot=%s/arch-arm", ndk_sdkdir))
                insert(_g.ldflags, format("--sysroot=%s/arch-arm", ndk_sdkdir))
                insert(_g.shflags, format("--sysroot=%s/arch-arm", ndk_sdkdir))
            end
        end
    end)

    -- set menu
    set_menu({
                config = 
                {   
                    {}
                ,   {nil, "ndk",            "kv", nil,          "The NDK Directory"             }
                ,   {nil, "ndk_sdkver",     "kv", "auto",       "The SDK Version for NDK"       }
                }

            ,   global = 
                {   
                    {}
                ,   {nil, "ndk",            "kv", nil,          "The NDK Directory"             }
                ,   {nil, "ndk_sdkver",     "kv", "auto",       "The SDK Version for NDK"       }
                }
            })



