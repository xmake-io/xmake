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

-- check the architecture
function __check_arch(config)

    -- get the architecture
    local arch = config.get("arch")
    if not arch then

        -- init the default architecture
        config.set("arch", ifelse(config.get("cross"), "none", os.arch()))

        -- trace
        print("checking for the architecture ... %s", config.get("arch"))
    end
end

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
        local arpathes = os.match(path.join(toolchains, "*-ar"))
        for _, arpath in ipairs(arpathes) do
            local arname = path.basename(arpath)
            if arname then
                cross = arname:sub(1, -3)
            end
        end
    end

    -- done
    checker.check_toolchain(config, "cc",   cross, "gcc",  "the c compiler") 
    checker.check_toolchain(config, "cxx",  cross, "g++",  "the c++ compiler") 
    checker.check_toolchain(config, "as",   cross, "gcc",  "the assember")
    checker.check_toolchain(config, "ld",   cross, "g++",  "the linker") 
    checker.check_toolchain(config, "ar",   cross, "ar",   "the static library linker") 
    checker.check_toolchain(config, "sh",   cross, "g++",  "the shared library linker") 
end

-- init it
function init()

    -- init the check list of config
    _g.config = 
    {
        __check_arch
    ,   checker.check_ccache
    ,   _check_toolchains
    }

    -- init the check list of global
    _g.global = 
    {
        checker.check_ccache
    ,   _check_ndk_sdkver
    }

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

