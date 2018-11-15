--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check.lua
--

-- imports
import(".checker")
import("detect.sdks.find_ndk")

-- check the ndk toolchain
function _check_ndk(config)
    local ndk = find_ndk(config.get("ndk"), {force = true, verbose = true})
    if ndk then
        config.set("ndk", ndk.sdkdir, {force = true, readonly = true}) -- maybe to global
        config.set("bin", ndk.bindir, {force = true, readonly = true})
        config.set("cross", ndk.cross, {force = true, readonly = true})
        config.set("gcc_toolchain", ndk.gcc_toolchain, {force = true, readonly = true})
    else
        -- failed
        cprint("${bright red}please run:")
        cprint("${red}    - xmake config --ndk=xxx")
        cprint("${red}or  - xmake global --ndk=xxx")
        raise()
    end
end

-- get toolchains
function _toolchains(config)

    -- attempt to get it from cache first
    if _g.TOOLCHAINS then
        return _g.TOOLCHAINS
    end

    -- get architecture
    local arch = config.get("arch")

    -- get cross
    local cross = config.get("cross") 

    -- init toolchains
    local toolchains = {}

    -- check c/c++ tools to toolchains
    checker.toolchain_insert(toolchains, "cc",       cross,  "gcc",          "the c compiler") 
    checker.toolchain_insert(toolchains, "cxx",      cross,  "g++",          "the c++ compiler") 
    checker.toolchain_insert(toolchains, "as",       cross,  "gcc",          "the assember")
    checker.toolchain_insert(toolchains, "ld",       cross,  "g++",          "the linker") 
    checker.toolchain_insert(toolchains, "ld",       cross,  "gcc",          "the linker") 
    checker.toolchain_insert(toolchains, "ar",       cross,  "ar",           "the static library archiver") 
    checker.toolchain_insert(toolchains, "ex",       cross,  "ar",           "the static library extractor") 
    checker.toolchain_insert(toolchains, "sh",       cross,  "g++",          "the shared library linker") 
    checker.toolchain_insert(toolchains, "sh",       cross,  "gcc",          "the shared library linker") 
    checker.toolchain_insert(toolchains, "cc",       "",     "clang",        "the c compiler") 
    checker.toolchain_insert(toolchains, "cxx",      "",     "clang++",      "the c++ compiler") 
    checker.toolchain_insert(toolchains, "as",       "",     "clang",        "the assember")
    checker.toolchain_insert(toolchains, "ld",       "",     "clang++",      "the linker") 
    checker.toolchain_insert(toolchains, "ld",       "",     "clang",        "the linker") 
    checker.toolchain_insert(toolchains, "sh",       "",     "clang++",      "the shared library linker") 
    checker.toolchain_insert(toolchains, "sh",       "",     "clang",        "the shared library linker") 
    checker.toolchain_insert(toolchains, "ar",       "",     "llvm-ar",      "the static library archiver") 
    checker.toolchain_insert(toolchains, "ex",       "",     "llvm-ar",      "the static library extractor") 

    -- insert rust tools to toolchains
    checker.toolchain_insert(toolchains, "rc",       "",      "rustc",       "the rust compiler") 
    checker.toolchain_insert(toolchains, "rc-ar",    "",      "rustc",       "the rust static library archiver") 
    checker.toolchain_insert(toolchains, "rc-sh",    "",      "rustc",       "the rust shared library linker") 
    checker.toolchain_insert(toolchains, "rc-ld",    "",      "rustc",       "the rust linker") 

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
        { checker.check_arch, "armv7-a" }
    ,   _check_ndk
    ,   { checker.toolchain_check, "sh", _toolchains }
    ,   { checker.toolchain_check, "ld", _toolchains }
    }

    -- init the check list of global
    _g.global = 
    {
        _check_ndk_sdkver
    }

    -- check it
    checker.check(kind, _g)
end


