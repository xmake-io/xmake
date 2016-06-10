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

-- check the toolchains
function _check_toolchains(config)

    -- get toolchains
    local toolchains = config.get("toolchains")
    if not toolchains then
        local sdkdir = config.get("sdk")
        if sdkdir then
            toolchains = path.join(sdkdir, "bin")
        end
    end

    -- get cross
    local cross = ""
    if toolchains then
        local ldpathes = os.match(path.join(toolchains, "*-ld"))
        for _, ldpath in ipairs(ldpathes) do
            local ldname = path.basename(ldpath)
            if ldname then
                cross = ldname:sub(1, -3)
            end
        end
    end

    -- done
    checker.check_toolchain(config, "cc",   cross, "gcc",       "the c compiler") 
    checker.check_toolchain(config, "cxx",  cross, "g++",       "the c++ compiler") 
    checker.check_toolchain(config, "cxx",  cross, "gcc",       "the c++ compiler") 
    checker.check_toolchain(config, "as",   cross, "gcc",       "the assember")
    checker.check_toolchain(config, "ld",   cross, "g++",       "the linker") 
    checker.check_toolchain(config, "ld",   cross, "gcc",       "the linker") 
    checker.check_toolchain(config, "ar",   cross, "ar",        "the static library linker") 
    checker.check_toolchain(config, "sh",   cross, "g++",       "the shared library linker") 
    checker.check_toolchain(config, "sh",   cross, "gcc",       "the shared library linker") 
    checker.check_toolchain(config, "sc",   cross, "swiftc",    "the swift compiler") 
end

-- init it
function init()

    -- init the check list of config
    _g.config = 
    {
        { checker.check_arch, "i386" }
    ,   checker.check_ccache
    ,   _check_toolchains
    }

    -- init the check list of global
    _g.global = 
    {
        checker.check_ccache
    }

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

