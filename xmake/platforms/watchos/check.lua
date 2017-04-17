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
    local tmpfile = os.tmpfile() .. ".S"
    io.writefile(tmpfile, "")

    -- check it
    os.run("%s -arch armv7 -o %s -c %s", shellname, os.nuldev(), tmpfile)

    -- remove this tmp.S
    os.rm(tmpfile)
end

-- get toolchains
function _toolchains(config)

    -- attempt to get it from cache first
    if _g.TOOLCHAINS then
        return _g.TOOLCHAINS
    end

    -- init architecture
    local arch = config.get("arch")
    local simulator = (arch == "i386")

    -- init cross
    local cross = ifelse(simulator, "xcrun -sdk watchsimulator ", "xcrun -sdk watchos ")

    -- init toolchains
    local toolchains = {}

    -- insert c/c++ tools to toolchains
    checker.toolchain_insert(toolchains, "cc",       cross,  "clang",        "the c compiler") 
    checker.toolchain_insert(toolchains, "cxx",      cross,  "clang",        "the c++ compiler") 
    checker.toolchain_insert(toolchains, "cxx",      cross,  "clang++",      "the c++ compiler") 
    checker.toolchain_insert(toolchains, "ld",       cross,  "clang++",      "the linker") 
    checker.toolchain_insert(toolchains, "ld",       cross,  "clang",        "the linker") 
    checker.toolchain_insert(toolchains, "ar",       cross,  "ar",           "the static library archiver") 
    checker.toolchain_insert(toolchains, "ex",       cross,  "ar",           "the static library extractor") 
    checker.toolchain_insert(toolchains, "sh",       cross,  "clang++",      "the shared library linker") 
    checker.toolchain_insert(toolchains, "sh",       cross,  "clang",        "the shared library linker") 
    checker.toolchain_insert(toolchains, "dg",       cross,  "lldb",         "the debugger") 

    -- insert objc/c++ tools to toolchains
    checker.toolchain_insert(toolchains, "mm",       cross,  "clang",        "the objc compiler") 
    checker.toolchain_insert(toolchains, "mxx",      cross,  "clang++",      "the objc++ compiler") 
    checker.toolchain_insert(toolchains, "mxx",      cross,  "clang",        "the objc++ compiler") 

    -- insert swift tools to toolchains
    checker.toolchain_insert(toolchains, "sc",       cross,   "swiftc",       "the swift compiler") 
    checker.toolchain_insert(toolchains, "sc-ld",    cross,   "swiftc",       "the swift linker") 
    checker.toolchain_insert(toolchains, "sc-sh",    cross,   "swiftc",       "the swift shared library linker") 

    -- insert asm tools to toolchains
    if simulator then
        checker.toolchain_insert(toolchains, "as",   cross,  "clang",        "the assember") 
    else
        checker.toolchain_insert(toolchains, "as",   path.join(os.toolsdir(), "utils/gas-preprocessor.pl " .. cross), "clang", "the assember", _check_as)
    end

    -- save toolchains
    _g.TOOLCHAINS = toolchains

    -- ok
    return toolchains
end

-- check it
function main(kind, toolkind)

    -- only check the given tool?
    if toolkind then
        return checker.toolchain_check(import("core.project." .. kind), toolkind, _toolchains)
    end

    -- init the check list of config
    _g.config = 
    {
        { checker.check_arch, "armv7k" }
    ,   checker.check_xcode
    ,   checker.check_xcode_sdkver
    ,   checker.check_target_minver
    ,   checker.check_ccache
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

