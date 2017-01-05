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
-- @file        check.lua
--

-- imports
import("core.tool.tool")
import("platforms.checker", {rootdir = os.programdir()})

-- check the toolchains
function _check_toolchains(config)

    -- check from env
    checker.check_toolchain_from_env(config, "cc",   "CC",   "the c compiler") 
    checker.check_toolchain_from_env(config, "cxx",  "CXX",  "the c++ compiler") 
    checker.check_toolchain_from_env(config, "mm",   "MM",   "the objc compiler") 
    checker.check_toolchain_from_env(config, "mxx",  "MXX",  "the objc++ compiler") 
    checker.check_toolchain_from_env(config, "sc",   "SC",   "the swift compiler") 
    checker.check_toolchain_from_env(config, "as",   "AS",   "the assember") 
    checker.check_toolchain_from_env(config, "ld",   "LD",   "the linker") 
    checker.check_toolchain_from_env(config, "ar",   "AR",   "the static library archiver") 
    checker.check_toolchain_from_env(config, "ex",   "AR",   "the static library extractor") 
    checker.check_toolchain_from_env(config, "sh",   "SH",   "the shared library linker") 
    checker.check_toolchain_from_env(config, "dd",   "DD",   "the debugger") 

    -- check with xcrun
    checker.check_toolchain(config, "cc",   "xcrun -sdk macosx ",  "clang",     "the c compiler") 
    checker.check_toolchain(config, "cxx",  "xcrun -sdk macosx ",  "clang",     "the c++ compiler") 
    checker.check_toolchain(config, "cxx",  "xcrun -sdk macosx ",  "clang++",   "the c++ compiler") 
    checker.check_toolchain(config, "mm",   "xcrun -sdk macosx ",  "clang",     "the objc compiler") 
    checker.check_toolchain(config, "mxx",  "xcrun -sdk macosx ",  "clang++",   "the objc++ compiler") 
    checker.check_toolchain(config, "mxx",  "xcrun -sdk macosx ",  "clang",     "the objc++ compiler") 
    checker.check_toolchain(config, "sc",   "xcrun -sdk macosx ",  "swiftc",    "the swift compiler") 
    checker.check_toolchain(config, "as",   "xcrun -sdk macosx ",  "clang",     "the assember") 
    checker.check_toolchain(config, "ld",   "xcrun -sdk macosx ",  "clang++",   "the linker") 
    checker.check_toolchain(config, "ld",   "xcrun -sdk macosx ",  "clang",     "the linker") 
    checker.check_toolchain(config, "ar",   "xcrun -sdk macosx ",  "ar",        "the static library archiver") 
    checker.check_toolchain(config, "ex",   "xcrun -sdk macosx ",  "ar",        "the static library extractor") 
    checker.check_toolchain(config, "sh",   "xcrun -sdk macosx ",  "clang++",   "the shared library linker") 
    checker.check_toolchain(config, "sh",   "xcrun -sdk macosx ",  "clang",     "the shared library linker") 
    checker.check_toolchain(config, "dd",   "xcrun -sdk macosx ",  "lldb",      "the debugger") 

    -- check without xcrun
    checker.check_toolchain(config, "cc",   "",  "clang",     "the c compiler") 
    checker.check_toolchain(config, "cxx",  "",  "clang",     "the c++ compiler") 
    checker.check_toolchain(config, "cxx",  "",  "clang++",   "the c++ compiler") 
    checker.check_toolchain(config, "mm",   "",  "clang",     "the objc compiler") 
    checker.check_toolchain(config, "mxx",  "",  "clang++",   "the objc++ compiler") 
    checker.check_toolchain(config, "mxx",  "",  "clang",     "the objc++ compiler") 
    checker.check_toolchain(config, "go",   "",  "go",        "the golang compiler") 
    checker.check_toolchain(config, "sc",   "",  "swiftc",    "the swift compiler") 
    checker.check_toolchain(config, "as",   "",  "clang",     "the assember") 
    checker.check_toolchain(config, "ld",   "",  "clang++",   "the linker") 
    checker.check_toolchain(config, "ld",   "",  "clang",     "the linker") 
    checker.check_toolchain(config, "ar",   "",  "ar",        "the static library archiver") 
    checker.check_toolchain(config, "ex",   "",  "ar",        "the static library extractor") 
    checker.check_toolchain(config, "sh",   "",  "clang++",   "the shared library linker") 
    checker.check_toolchain(config, "sh",   "",  "clang",     "the shared library linker") 
    checker.check_toolchain(config, "dd",   "",  "lldb",      "the debugger") 
end

-- check it
function main(kind)

    -- init the check list of config
    _g.config = 
    {
        checker.check_arch
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

    -- check it
    checker.check(kind, _g)
end

