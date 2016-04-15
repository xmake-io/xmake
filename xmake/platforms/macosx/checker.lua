--!The Automatic Cross-platform Build Tool
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
-- @file        checker.lua
--

-- imports
import("core.tool.tool")
import("platforms.checker", {rootdir = os.programdir()})

-- check the xcode sdk version
function _check_xcode_sdkver(config)

    -- get the xcode sdk version
    local xcode_sdkver = config.get("xcode_sdkver")
    if not xcode_sdkver then

        -- attempt to match the directory
        if not xcode_sdkver then
            local dirs = os.match(config.get("xcode_dir") .. "/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX*.sdk", true)
            if dirs then
                for _, dir in ipairs(dirs) do
                    xcode_sdkver = string.match(dir, "%d+%.%d+")
                    if xcode_sdkver then break end
                end
            end
        end

        -- check ok? update it
        if xcode_sdkver then
            
            -- save it
            config.set("xcode_sdkver", xcode_sdkver)

            -- trace
            print("checking for the Xcode SDK version for %s ... %s", config.get("plat"), xcode_sdkver)
        else
            -- failed
            print("checking for the Xcode SDK version for %s ... no", config.get("plat"))
            print("please run:")
            print("    - xmake config --xcode_sdkver=xxx")
            print("or  - xmake global --xcode_sdkver=xxx")
            raise()
        end
    end
end

-- check the target minimal version
function _check_target_minver(config)

    -- get the target minimal version
    local target_minver = config.get("target_minver")
    if not target_minver then

        -- init the default target minimal version
        config.set("target_minver", "10.9")

        -- trace
        print("checking for the target minimal version ... %s", config.get("target_minver"))

    end
end

-- check the toolchains
function _check_toolchains(config)

    -- done
    checker.check_toolchain(config, "cc",   "xcrun -sdk macosx ",  "clang",     "the c compiler") 
    checker.check_toolchain(config, "cxx",  "xcrun -sdk macosx ",  "clang",     "the c++ compiler") 
    checker.check_toolchain(config, "cxx",  "xcrun -sdk macosx ",  "clang++",   "the c++ compiler") 
    checker.check_toolchain(config, "mm",   "xcrun -sdk macosx ",  "clang",     "the objc compiler") 
    checker.check_toolchain(config, "mxx",  "xcrun -sdk macosx ",  "clang++",   "the objc++ compiler") 
    checker.check_toolchain(config, "mxx",  "xcrun -sdk macosx ",  "clang",     "the objc++ compiler") 
    checker.check_toolchain(config, "as",   "xcrun -sdk macosx ",  "clang",     "the assember") 
    checker.check_toolchain(config, "ld",   "xcrun -sdk macosx ",  "clang++",   "the linker") 
    checker.check_toolchain(config, "ld",   "xcrun -sdk macosx ",  "clang",     "the linker") 
    checker.check_toolchain(config, "ar",   "xcrun -sdk macosx ",  "ar",        "the static library linker") 
    checker.check_toolchain(config, "sh",   "xcrun -sdk macosx ",  "clang++",   "the shared library linker") 
    checker.check_toolchain(config, "sh",   "xcrun -sdk macosx ",  "clang",     "the shared library linker") 
    checker.check_toolchain(config, "sc",   "xcrun -sdk macosx ",  "swiftc",    "the swift compiler") 

end

-- init it
function init()

    -- init host
    _g.host = "macosx"

    -- init the check list of config
    _g.config = 
    {
        checker.check_arch
    ,   checker.check_xcode
    ,   _check_xcode_sdkver
    ,   _check_target_minver
    ,   checker.check_make
    ,   checker.check_ccache
    ,   _check_toolchains
    }

    -- init the check list of global
    _g.global = 
    {
        checker.check_xcode
    ,   checker.check_ccache
    }

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

