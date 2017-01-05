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

    -- set tooldirs
    set_tooldirs("/usr/bin", "/usr/local/bin", "/opt/bin", "/opt/local/bin")

    -- on check
    on_check("check")

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
            _g.cxxflags     = {}
        else
            _g.cxflags      = { "-march=" .. arch, "-mthumb"}
            _g.asflags      = { "-march=" .. arch, "-mthumb"}
            _g.ldflags      = { "-march=" .. arch, "-llog", "-mthumb"}
            _g.shflags      = { "-march=" .. arch, "-llog", "-mthumb"}
            _g.cxxflags     = {}
        end

        -- add flags for the sdk directory of ndk
        local ndk = config.get("ndk")
        local ndk_sdkver = config.get("ndk_sdkver")
        if ndk and ndk_sdkver then

            -- get ndk sdk directory
            local ndk_sdkdir = path.translate(format("%s/platforms/android-%d", ndk, ndk_sdkver)) 

            -- add sysroot
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

            -- only for c++ stl
            local toolchains_ver = config.get("toolchains_ver")
            if toolchains_ver then

                -- get c++ stl sdk directory
                local cxxstl_sdkdir = path.translate(format("%s/sources/cxx-stl/gnu-libstdc++/%s", ndk, toolchains_ver)) 

                -- the toolchains archs
                local toolchains_archs = 
                {
                    ["armv5te"]     = "armeabi"
                ,   ["armv6"]       = "armeabi"
                ,   ["armv7-a"]     = "armeabi-v7a"
                ,   ["armv8-a"]     = "armeabi-v8a"
                ,   ["arm64-v8a"]   = "arm64-v8a"
                }

                -- add search directories for c++ stl
                insert(_g.cxxflags, format("-I%s/include", cxxstl_sdkdir))
                if toolchains_archs[arch] then
                    insert(_g.cxxflags, format("-I%s/libs/%s/include", cxxstl_sdkdir, toolchains_archs[arch]))
                    insert(_g.ldflags, format("-L%s/libs/%s", cxxstl_sdkdir, toolchains_archs[arch]))
                    insert(_g.shflags, format("-L%s/libs/%s", cxxstl_sdkdir, toolchains_archs[arch]))
                    insert(_g.ldflags, format("-lgnustl_static"))
                    insert(_g.shflags, format("-lgnustl_static"))
                end
            end
        end

        -- ok
        return _g
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



