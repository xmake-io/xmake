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

-- check the architecture
function _check_arch(config)

    -- get the architecture
    local arch = config.get("arch")
    if not arch then

        -- init the default architecture
        config.set("arch", os.arch())

        -- trace
        print("checking for the architecture ... %s", config.get("arch"))

    end
end

-- check the xcode application directory
function _check_xcode(config)

    -- get the xcode directory
    local xcode_dir = config.get("xcode_dir")
    if not xcode_dir then

        -- attempt to get the default directory 
        if not xcode_dir then
            if os.isdir("/Applications/Xcode.app") then
                xcode_dir = "/Applications/Xcode.app"
            end
        end

        -- attempt to match the other directories
        if not xcode_dir then
            local dirs = os.match("/Applications/Xcode*.app", true)
            if dirs and #dirs ~= 0 then
                xcode_dir = dirs[1]
            end
        end

        -- check ok? update it
        if xcode_dir then

            -- save it
            config.set("xcode_dir", xcode_dir)

            -- trace
            print("checking for the Xcode application directory ... %s", xcode_dir)
        else
            -- failed
            raise("checking for the Xcode application directory ... no\n" ..
                  "    - xmake config --xcode_dir=xxx\n" ..
                  "or  - xmake global --xcode_dir=xxx")
        end
    end
end

-- probe the xcode sdk version
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
            raise("checking for the Xcode SDK version for %s ... no\n" .. 
                  "    - xmake config --xcode_sdkver=xxx" ..
                  "or  - xmake global --xcode_sdkver=xxx", config.get("plat"))
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

-- check the make
function _check_make(config)

    -- ok? 
    local make = config.get("make")
    if not make then 

        -- check the make path
        make = tool.check("make", {"/usr/bin", "/usr/local/bin", "/opt/bin", "/opt/local/bin"})

        -- check ok? update it
        if make then config.set("make", make) end

        -- trace
        print("checking for the make ... %s", ifelse(make, make, "no"))

    end
end

-- check the ccache
function _check_ccache(config)

    -- ok? 
    local ccache = config.get("ccache")
    if ccache ~= nil then

        -- check the ccache path
        local ccache_path = tool.check("ccache", {"/usr/bin", "/usr/local/bin", "/opt/bin", "/opt/local/bin"})

        -- check ok? update it
        if ccache_path then
            config.set("ccache", true)
            config.set("__ccache", ccache_path)
        else
            config.set("ccache", false)
        end

        -- trace
        print("checking for the ccache ... %s", ifelse(ccache_path, ccache_path, "no"))

    end
end

-- check the tool path
function _check_toolpath(config, kind, cross, names, description)

    -- get the cross
    cross = config.get("cross") or cross

    -- done
    local toolpath = nil
    local toolchains = config.get("toolchains") 
    for _, name in ipairs(names) do

        -- attempt to get it from the given cross toolchains
        if toolchains then
            toolpath = tool.check(cross .. (config.get(kind) or name), toolchains)
        end

        -- attempt to get it directly from the configure
        if not toolpath then
            toolpath = config.get(kind)
        end

        -- attempt to run it directly
        if not toolpath then
            toolpath = tool.check(cross .. name)
        end

        -- check ok?
        if toolpath then 

            -- update config
            config.set(kind, toolpath) 

            -- end
            break
        end

    end

    -- trace
    if toolpath then
        print("checking for %s (%s) ... %s", description, kind, path.filename(toolpath))
    else
        print("checking for %s (%s) ... no", description, kind)
    end

end

-- check the toolchains
function _check_toolchains(config)

    -- done
    _check_toolpath(config, "cc", "xcrun -sdk macosx ", "clang", "the c compiler") 
    _check_toolpath(config, "cxx", "xcrun -sdk macosx ", {"clang++", "clang"}, "the c++ compiler") 
    _check_toolpath(config, "mm", "xcrun -sdk macosx ", "clang", "the objc compiler") 
    _check_toolpath(config, "mxx", "xcrun -sdk macosx ", {"clang++", "clang"}, "the objc++ compiler") 
    _check_toolpath(config, "as", "xcrun -sdk macosx ", "clang", "the assember") 
    _check_toolpath(config, "ld", "xcrun -sdk macosx ", {"clang++", "clang"}, "the linker") 
    _check_toolpath(config, "ar", "xcrun -sdk macosx ", "ar", "the static library linker") 
    _check_toolpath(config, "sh", "xcrun -sdk macosx ", {"clang++", "clang"}, "the shared library linker") 
    _check_toolpath(config, "sc", "xcrun -sdk macosx ", "swiftc", "the swift compiler") 
end

-- init it
function init()

    -- init host
    _g.host = "macosx"

    -- init the check list of config
    _g.config = 
    {
        _check_arch
    ,   _check_xcode
    ,   _check_xcode_sdkver
    ,   _check_target_minver
    ,   _check_make
    ,   _check_ccache
    ,   _check_toolchains
    }

    -- init the check list of global
    _g.global = 
    {
        _check_xcode
    ,   _check_ccache
    }

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

