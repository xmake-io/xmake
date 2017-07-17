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
import(".checker")

-- get toolchains
function _toolchains(config)

    -- attempt to get it from cache first
    if _g.TOOLCHAINS then
        return _g.TOOLCHAINS
    end

    -- init toolchains
    local toolchains = {}

    -- insert c/c++ tools to toolchains
    checker.toolchain_insert(toolchains, "cc",    "",                   "$(env CC)",  "the c compiler")
    checker.toolchain_insert(toolchains, "cxx",   "",                   "$(env CXX)", "the linker")
    checker.toolchain_insert(toolchains, "ld",    "",                   "$(env LD)",  "the linker")
    checker.toolchain_insert(toolchains, "ld",    "",                   "$(env CXX)", "the linker")
    checker.toolchain_insert(toolchains, "ar",    "",                   "$(env AR)",  "the static library archiver")
    checker.toolchain_insert(toolchains, "sh",    "",                   "$(env SH)",  "the shared library linker")
    checker.toolchain_insert(toolchains, "cc",    "xcrun -sdk macosx ", "clang",      "the c compiler")
    checker.toolchain_insert(toolchains, "cxx",   "xcrun -sdk macosx ", "clang",      "the c++ compiler")
    checker.toolchain_insert(toolchains, "cxx",   "xcrun -sdk macosx ", "clang++",    "the c++ compiler")
    checker.toolchain_insert(toolchains, "ld",    "xcrun -sdk macosx ", "clang++",    "the linker")
    checker.toolchain_insert(toolchains, "ld",    "xcrun -sdk macosx ", "clang",      "the linker")
    checker.toolchain_insert(toolchains, "ar",    "xcrun -sdk macosx ", "ar",         "the static library archiver")
    checker.toolchain_insert(toolchains, "ex",    "xcrun -sdk macosx ", "ar",         "the static library extractor")
    checker.toolchain_insert(toolchains, "sh",    "xcrun -sdk macosx ", "clang++",    "the shared library linker")
    checker.toolchain_insert(toolchains, "sh",    "xcrun -sdk macosx ", "clang",      "the shared library linker")

    -- insert objc/c++ tools to toolchains
    checker.toolchain_insert(toolchains, "mm",    "",                   "$(env MM)",  "the objc compiler")
    checker.toolchain_insert(toolchains, "mxx",   "",                   "$(env MXX)", "the objc++ compiler")
    checker.toolchain_insert(toolchains, "mm",    "xcrun -sdk macosx ", "clang",      "the objc compiler")
    checker.toolchain_insert(toolchains, "mxx",   "xcrun -sdk macosx ", "clang++",    "the objc++ compiler")
    checker.toolchain_insert(toolchains, "mxx",   "xcrun -sdk macosx ", "clang",      "the objc++ compiler")

    -- insert asm tools to toolchains
    checker.toolchain_insert(toolchains, "as",    "",                   "$(env AS)",  "the assember")
    checker.toolchain_insert(toolchains, "as",    "xcrun -sdk macosx ", "clang",      "the assember")

    -- insert swift tools to toolchains
    checker.toolchain_insert(toolchains, "sc",    "",                   "$(env SC)",  "the swift compiler")
    checker.toolchain_insert(toolchains, "sc-ld", "",                   "$(env SC)",  "the swift linker")
    checker.toolchain_insert(toolchains, "sc-sh", "",                   "$(env SC)",  "the swift shared library linker")
    checker.toolchain_insert(toolchains, "sc",    "xcrun -sdk macosx ", "swiftc",     "the swift compiler")
    checker.toolchain_insert(toolchains, "sc-ld", "xcrun -sdk macosx ", "swiftc",     "the swift linker")
    checker.toolchain_insert(toolchains, "sc-sh", "xcrun -sdk macosx ", "swiftc",     "the swift shared library linker")

    -- insert golang tools to toolchains
    checker.toolchain_insert(toolchains, "gc",    "",                   "$(env GC)",  "the golang compiler")
    checker.toolchain_insert(toolchains, "gc-ar", "",                   "$(env GC)",  "the golang static library archiver")
    checker.toolchain_insert(toolchains, "gc-ld", "",                   "$(env GC)",  "the golang linker")
    checker.toolchain_insert(toolchains, "gc",    "",                   "go",         "the golang compiler")
    checker.toolchain_insert(toolchains, "gc",    "",                   "gccgo",      "the golang compiler")
    checker.toolchain_insert(toolchains, "gc-ar", "",                   "go",         "the golang static library archiver")
    checker.toolchain_insert(toolchains, "gc-ar", "",                   "gccgo",      "the golang static library archiver")
    checker.toolchain_insert(toolchains, "gc-ld", "",                   "go",         "the golang linker")
    checker.toolchain_insert(toolchains, "gc-ld", "",                   "gccgo",      "the golang linker")

    -- insert dlang tools to toolchains
    checker.toolchain_insert(toolchains, "dc",    "",                   "$(env DC)",  "the dlang compiler")
    checker.toolchain_insert(toolchains, "dc-ar", "",                   "$(env Dc)",  "the dlang static library archiver")
    checker.toolchain_insert(toolchains, "dc-sh", "",                   "$(env DC)",  "the dlang shared library linker")
    checker.toolchain_insert(toolchains, "dc-ld", "",                   "$(env DC)",  "the dlang linker")
    checker.toolchain_insert(toolchains, "dc",    "",                   "dmd",        "the dlang compiler")
    checker.toolchain_insert(toolchains, "dc",    "",                   "ldc2",       "the dlang compiler")
    checker.toolchain_insert(toolchains, "dc",    "",                   "gdc",        "the dlang compiler")
    checker.toolchain_insert(toolchains, "dc-ar", "",                   "dmd",        "the dlang static library archiver")
    checker.toolchain_insert(toolchains, "dc-ar", "",                   "ldc2",       "the dlang static library archiver")
    checker.toolchain_insert(toolchains, "dc-ar", "",                   "gdc",        "the dlang static library archiver")
    checker.toolchain_insert(toolchains, "dc-sh", "",                   "dmd",        "the dlang shared library linker")
    checker.toolchain_insert(toolchains, "dc-sh", "",                   "ldc2",       "the dlang shared library linker")
    checker.toolchain_insert(toolchains, "dc-sh", "",                   "gdc",        "the dlang shared library linker")
    checker.toolchain_insert(toolchains, "dc-ld", "",                   "dmd",        "the dlang linker")
    checker.toolchain_insert(toolchains, "dc-ld", "",                   "ldc2",       "the dlang linker")
    checker.toolchain_insert(toolchains, "dc-ld", "",                   "gdc",        "the dlang linker")

    -- insert rust tools to toolchains
    checker.toolchain_insert(toolchains, "rc",    "",                   "$(env RC)",  "the rust compiler")
    checker.toolchain_insert(toolchains, "rc-ar", "",                   "$(env RC)",  "the rust static library archiver")
    checker.toolchain_insert(toolchains, "rc-sh", "",                   "$(env RC)",  "the rust shared library linker")
    checker.toolchain_insert(toolchains, "rc-ld", "",                   "$(env RC)",  "the rust linker")
    checker.toolchain_insert(toolchains, "rc",    "",                   "rustc",      "the rust compiler")
    checker.toolchain_insert(toolchains, "rc-ar", "",                   "rustc",      "the rust static library archiver")
    checker.toolchain_insert(toolchains, "rc-sh", "",                   "rustc",      "the rust shared library linker")
    checker.toolchain_insert(toolchains, "rc-ld", "",                   "rustc",      "the rust linker")

    -- save toolchains
    _g.TOOLCHAINS = toolchains

    -- ok
    return toolchains
end

-- check it
function main(kind, toolkind)

    -- only check the given tool?
    if toolkind then
        return checker.toolchain_check(kind, toolkind, _toolchains)
    end

    -- init the check list of config
    _g.config = 
    {
        checker.check_arch
    ,   checker.check_xcode_dir
    ,   checker.check_xcode_sdkver
    }

    -- init the check list of global
    _g.global = 
    {
        checker.check_xcode_dir
    }

    -- check it
    checker.check(kind, _g)
end

