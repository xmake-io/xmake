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
-- @file        checker.lua
--

-- imports
import("core.tool.tool")
import("platforms.checker", {rootdir = os.programdir()})

-- check the as
function _check_as(shellname)

    -- make an empty tmp.S
    local tmpfile = path.join(os.tmpdir(), "xmake.checker.as.S")
    io.write(tmpfile, "")

    -- check it
    os.run("%s -arch armv7 -o %s -c %s", shellname, os.nuldev(), tmpfile)

    -- remove this tmp.S
    os.rm(tmpfile)
end

-- check the toolchains
function _check_toolchains(config)

    -- watchos or watchsimulator?
    local arch = config.get("arch")
    if arch == "i386" then
        checker.check_toolchain(config, "cc",   "xcrun -sdk watchsimulator ", "clang",    "the c compiler") 
        checker.check_toolchain(config, "cxx",  "xcrun -sdk watchsimulator ", "clang",    "the c++ compiler") 
        checker.check_toolchain(config, "cxx",  "xcrun -sdk watchsimulator ", "clang++",  "the c++ compiler") 
        checker.check_toolchain(config, "mm",   "xcrun -sdk watchsimulator ", "clang",    "the objc compiler") 
        checker.check_toolchain(config, "mxx",  "xcrun -sdk watchsimulator ", "clang++",  "the objc++ compiler") 
        checker.check_toolchain(config, "mxx",  "xcrun -sdk watchsimulator ", "clang",    "the objc++ compiler") 
        checker.check_toolchain(config, "as",   "xcrun -sdk watchsimulator ", "clang",     "the assember") 
        checker.check_toolchain(config, "ld",   "xcrun -sdk watchsimulator ", "clang++",  "the linker") 
        checker.check_toolchain(config, "ld",   "xcrun -sdk watchsimulator ", "clang",    "the linker") 
        checker.check_toolchain(config, "ar",   "xcrun -sdk watchsimulator ", "ar",       "the static library archiver") 
        checker.check_toolchain(config, "ex",   "xcrun -sdk watchsimulator ", "ar",       "the static library extractor") 
        checker.check_toolchain(config, "sh",   "xcrun -sdk watchsimulator ", "clang++",  "the shared library linker") 
        checker.check_toolchain(config, "sh",   "xcrun -sdk watchsimulator ", "clang",    "the shared library linker") 
        checker.check_toolchain(config, "sc",   "xcrun -sdk watchsimulator ", "swiftc",   "the swift compiler") 
    else
        checker.check_toolchain(config, "cc",   "xcrun -sdk watchos ", "clang",    "the c compiler") 
        checker.check_toolchain(config, "cxx",  "xcrun -sdk watchos ", "clang",    "the c++ compiler") 
        checker.check_toolchain(config, "cxx",  "xcrun -sdk watchos ", "clang++",  "the c++ compiler") 
        checker.check_toolchain(config, "mm",   "xcrun -sdk watchos ", "clang",    "the objc compiler") 
        checker.check_toolchain(config, "mxx",  "xcrun -sdk watchos ", "clang++",  "the objc++ compiler") 
        checker.check_toolchain(config, "mxx",  "xcrun -sdk watchos ", "clang",    "the objc++ compiler") 
        checker.check_toolchain(config, "as",   path.join(os.toolsdir(), "utils/gas-preprocessor.pl xcrun -sdk watchos "), "clang", "the assember", _check_as)
        checker.check_toolchain(config, "ld",   "xcrun -sdk watchos ", "clang++",  "the linker") 
        checker.check_toolchain(config, "ld",   "xcrun -sdk watchos ", "clang",    "the linker") 
        checker.check_toolchain(config, "ar",   "xcrun -sdk watchos ", "ar",       "the static library archiver") 
        checker.check_toolchain(config, "ex",   "xcrun -sdk watchos ", "ar",       "the static library extractor") 
        checker.check_toolchain(config, "sh",   "xcrun -sdk watchos ", "clang++",  "the shared library linker") 
        checker.check_toolchain(config, "sh",   "xcrun -sdk watchos ", "clang",    "the shared library linker") 
        checker.check_toolchain(config, "sc",   "xcrun -sdk watchos ", "swiftc",   "the swift compiler") 
    end
end

-- init it
function init()

    -- init the check list of config
    _g.config = 
    {
        { checker.check_arch, "armv7k" }
    ,   checker.check_xcode
    ,   checker.check_xcode_sdkver
    ,   checker.check_target_minver
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

