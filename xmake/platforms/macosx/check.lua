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
    checker.check_toolchain(config, "dg",   "xcrun -sdk macosx ",  "lldb",      "the debugger") 

    -- check without xcrun
    checker.check_toolchain(config, "cc",   "",  "clang",           "the c compiler") 
    checker.check_toolchain(config, "cxx",  "",  "clang",           "the c++ compiler") 
    checker.check_toolchain(config, "cxx",  "",  "clang++",         "the c++ compiler") 
    checker.check_toolchain(config, "mm",   "",  "clang",           "the objc compiler") 
    checker.check_toolchain(config, "mxx",  "",  "clang++",         "the objc++ compiler") 
    checker.check_toolchain(config, "mxx",  "",  "clang",           "the objc++ compiler") 
    checker.check_toolchain(config, "sc",   "",  "swiftc",          "the swift compiler") 
    checker.check_toolchain(config, "as",   "",  "clang",           "the assember") 
    checker.check_toolchain(config, "ld",   "",  "clang++",         "the linker") 
    checker.check_toolchain(config, "ld",   "",  "clang",           "the linker") 
    checker.check_toolchain(config, "ar",   "",  "ar",              "the static library archiver") 
    checker.check_toolchain(config, "ex",   "",  "ar",              "the static library extractor") 
    checker.check_toolchain(config, "sh",   "",  "clang++",         "the shared library linker") 
    checker.check_toolchain(config, "sh",   "",  "clang",           "the shared library linker") 
    checker.check_toolchain(config, "dg",   "",  "lldb",            "the debugger") 

    -- check for golang tools
    checker.check_toolchain(config, "go",       "",  "go",          "the golang compiler") 
    checker.check_toolchain(config, "go",       "",  "gccgo",       "the golang compiler") 
    checker.check_toolchain(config, "go-ar",    "",  "go",          "the golang static library archiver") 
    checker.check_toolchain(config, "go-ar",    "",  "gccgo",       "the golang static library archiver") 
    checker.check_toolchain(config, "go-ld",    "",  "go",          "the golang linker") 
    checker.check_toolchain(config, "go-ld",    "",  "gccgo",       "the golang linker") 

    -- check for dlang tools
    checker.check_toolchain(config, "dd",       "",  "dmd",         "the dlang compiler") 
    checker.check_toolchain(config, "dd",       "",  "ldc2",        "the dlang compiler") 
    checker.check_toolchain(config, "dd",       "",  "gdc",         "the dlang compiler") 
    checker.check_toolchain(config, "dd-ar",    "",  "dmd",         "the dlang static library archiver") 
    checker.check_toolchain(config, "dd-ar",    "",  "ldc2",        "the dlang static library archiver") 
    checker.check_toolchain(config, "dd-ar",    "",  "gdc",         "the dlang static library archiver") 
    checker.check_toolchain(config, "dd-sh",    "",  "dmd",         "the dlang shared library linker") 
    checker.check_toolchain(config, "dd-sh",    "",  "ldc2",        "the dlang shared library linker") 
    checker.check_toolchain(config, "dd-sh",    "",  "gdc",         "the dlang shared library linker") 
    checker.check_toolchain(config, "dd-ld",    "",  "dmd",         "the dlang linker") 
    checker.check_toolchain(config, "dd-ld",    "",  "ldc2",        "the dlang linker") 
    checker.check_toolchain(config, "dd-ld",    "",  "gdc",         "the dlang linker") 
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

