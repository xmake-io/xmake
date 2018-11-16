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
import("environment")
import("core.base.option")
import("detect.sdks.find_vstudio")
import("lib.detect.find_tool")

-- attempt to check vs environment
function _check_vsenv(config)

    -- have been checked?
    local vs = config.get("vs")
    if vs and config.get("__vcvarsall") then
        return vs
    end

    -- find vstudio
    local vstudio = find_vstudio({vcvars_ver = config.get("vs_toolset"), sdkver = config.get("vs_sdkver")})
    if vstudio then

        -- make order vsver
        local vsvers = {}
        for vsver, _ in pairs(vstudio) do
            if not vs or vs ~= vsver then
                table.insert(vsvers, vsver)
            end
        end
        table.sort(vsvers, function (a, b) return tonumber(a) > tonumber(b) end)
        if vs then
            table.insert(vsvers, 1, vs)
        end

        -- get vcvarsall
        for _, vsver in ipairs(vsvers) do
            local vcvarsall = (vstudio[vsver] or {}).vcvarsall or {}
            local vsenv = vcvarsall[config.get("arch") or ""]
            if vsenv and vsenv.path and vsenv.include and vsenv.lib then

                -- save vsenv
                config.set("__vcvarsall", vcvarsall)

                -- check compiler
                environment.enter("toolchains")
                local program = nil
                local tool = find_tool("cl.exe", {force = true})
                if tool then
                    program = tool.program
                end
                environment.leave("toolchains")

                -- ok?
                if program then
                    return vsver
                end
            end
        end
    end
end

-- clean temporary global configs
function _clean_global(config)
    
    -- clean it for global config (need not it)
    config.set("arch",                  nil)
    config.set("__vcvarsall",           nil)
end

-- check the visual stdio
function _check_vs(config)

    -- attempt to check the given vs version first
    local vs = _check_vsenv(config)
    if vs then

        -- save it
        config.set("vs", vs, {readonly = true, force = true})

        -- trace
        print("checking for the Microsoft Visual Studio (%s) version ... %s", config.get("arch"), vs)
    else
        -- failed
        print("checking for the Microsoft Visual Studio (%s) version ... no", config.get("arch"))
        print("please run:")
        print("    - xmake config --vs=xxx [--vs_toolset=xxx]")
        print("or  - xmake global --vs=xxx")
        raise()
    end
end

-- get toolchains
function _toolchains(config)

    -- attempt to get it from cache first
    if _g.TOOLCHAINS then
        return _g.TOOLCHAINS
    end

    -- init toolchains
    local toolchains = {}

    -- insert c/c++ tools to toolchains
    checker.toolchain_insert(toolchains, "cc",    "", "cl.exe",        "the c compiler")
    checker.toolchain_insert(toolchains, "cxx",   "", "cl.exe",        "the c++ compiler")
    checker.toolchain_insert(toolchains, "mrc",   "", "rc.exe",        "the resource compiler")
    checker.toolchain_insert(toolchains, "ld",    "", "link.exe",      "the linker")
    checker.toolchain_insert(toolchains, "ar",    "", "link.exe -lib", "the static library archiver")
    checker.toolchain_insert(toolchains, "sh",    "", "link.exe -dll", "the shared library linker")
    checker.toolchain_insert(toolchains, "ex",    "", "lib.exe",       "the static library extractor")

    -- insert golang tools to toolchains
    checker.toolchain_insert(toolchains, "gc",    "", "go",            "the golang compiler")
    checker.toolchain_insert(toolchains, "gc",    "", "gccgo",         "the golang compiler")
    checker.toolchain_insert(toolchains, "gc-ar", "", "go",            "the golang static library archiver")
    checker.toolchain_insert(toolchains, "gc-ar", "", "gccgo",         "the golang static library archiver")
    checker.toolchain_insert(toolchains, "gc-ld", "", "go",            "the golang linker")
    checker.toolchain_insert(toolchains, "gc-ld", "", "gccgo",         "the golang linker")

    -- insert dlang tools to toolchains
    checker.toolchain_insert(toolchains, "dc",    "", "dmd",           "the dlang compiler")
    checker.toolchain_insert(toolchains, "dc",    "", "ldc2",          "the dlang compiler")
    checker.toolchain_insert(toolchains, "dc",    "", "gdc",           "the dlang compiler")
    checker.toolchain_insert(toolchains, "dc-ar", "", "dmd",           "the dlang static library archiver")
    checker.toolchain_insert(toolchains, "dc-ar", "", "ldc2",          "the dlang static library archiver")
    checker.toolchain_insert(toolchains, "dc-ar", "", "gdc",           "the dlang static library archiver")
    checker.toolchain_insert(toolchains, "dc-sh", "", "dmd",           "the dlang shared library linker")
    checker.toolchain_insert(toolchains, "dc-sh", "", "ldc2",          "the dlang shared library linker")
    checker.toolchain_insert(toolchains, "dc-sh", "", "gdc",           "the dlang shared library linker")
    checker.toolchain_insert(toolchains, "dc-ld", "", "dmd",           "the dlang linker")
    checker.toolchain_insert(toolchains, "dc-ld", "", "ldc2",          "the dlang linker")
    checker.toolchain_insert(toolchains, "dc-ld", "", "gdc",           "the dlang linker")

    -- insert rust tools to toolchains
    checker.toolchain_insert(toolchains, "rc",    "", "rustc",         "the rust compiler")
    checker.toolchain_insert(toolchains, "rc-ar", "", "rustc",         "the rust static library archiver")
    checker.toolchain_insert(toolchains, "rc-sh", "", "rustc",         "the rust shared library linker")
    checker.toolchain_insert(toolchains, "rc-ld", "", "rustc",         "the rust linker")

    -- insert asm tools to toolchains
    if config.get("arch"):find("64") then
        checker.toolchain_insert(toolchains, "as", "", "ml64.exe", "the assember")
    else
        checker.toolchain_insert(toolchains, "as", "", "ml.exe",   "the assember")
    end

    -- insert cuda tools to toolchains
    checker.toolchain_insert(toolchains, "cu",    "", "nvcc",          "the cuda compiler")
    checker.toolchain_insert(toolchains, "cu-sh", "", "nvcc",          "the cuda shared library linker")
    checker.toolchain_insert(toolchains, "cu-ld", "", "nvcc",          "the cuda linker")

    -- save toolchains
    _g.TOOLCHAINS = toolchains

    -- ok
    return toolchains
end

-- check it
function main(kind, toolkind)

    -- only check the given tool?
    if toolkind then

        -- enter environment
        environment.enter("toolchains")

        -- check it
        checker.toolchain_check(kind, toolkind, _toolchains)

        -- leave environment
        environment.leave("toolchains")

        -- end
        return 
    end

    -- init the check list of config
    _g.config = 
    {
        checker.check_arch
    ,   _check_vs
    ,   checker.check_cuda
    }

    -- init the check list of global
    _g.global = 
    {
        checker.check_arch
    ,   _check_vs
    ,   checker.check_cuda
    ,   _clean_global
    }

    -- check it
    checker.check(kind, _g)
end

