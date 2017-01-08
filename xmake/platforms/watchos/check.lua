--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check.lua
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

-- check it
function main(kind)

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

    -- check it
    checker.check(kind, _g)
end

