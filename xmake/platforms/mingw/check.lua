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
import("detect.sdks.find_cross_toolchains")
import(".checker")

-- get toolchains
function _toolchains(config)

    -- attempt to get it from cache first
    if _g.TOOLCHAINS then
        return _g.TOOLCHAINS
    end

    -- init arch
    local arch = config.get("arch")
    if not arch or arch == "i386" then
        arch = "i686"
    end

    -- find cross toolchains
    local cross = ""
    for _, toolchain in ipairs(find_cross_toolchains(config.get("sdk") or config.get("toolchains"), {bin = config.get("toolchains"), cross = config.get("cross")})) do
        if toolchain.bin and toolchain.cross and toolchain.cross:find(arch) then
            config.set("cross", toolchain.cross)
            config.set("toolchains", toolchain.bin)
            cross = toolchain.cross
            break
        end
    end

    -- make toolchains
    local toolchains = {}
    checker.toolchain_insert(toolchains, "cc",  cross, "gcc", "the c compiler")
    checker.toolchain_insert(toolchains, "cxx", cross, "g++", "the c++ compiler")
    checker.toolchain_insert(toolchains, "cxx", cross, "gcc", "the c++ compiler")
    checker.toolchain_insert(toolchains, "as",  cross, "gcc", "the assember")
    checker.toolchain_insert(toolchains, "ld",  cross, "g++", "the linker")
    checker.toolchain_insert(toolchains, "ld",  cross, "gcc", "the linker")
    checker.toolchain_insert(toolchains, "ar",  cross, "ar",  "the static library archiver")
    checker.toolchain_insert(toolchains, "ex",  cross, "ar",  "the static library extractor")
    checker.toolchain_insert(toolchains, "sh",  cross, "g++", "the shared library linker")
    checker.toolchain_insert(toolchains, "sh",  cross, "gcc", "the shared library linker")

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
        { checker.check_arch, "i386" }
    }

    -- init the check list of global
    _g.global = {}

    -- check it
    checker.check(kind, _g)
end

