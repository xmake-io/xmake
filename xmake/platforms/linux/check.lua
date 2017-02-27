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
        local ldpathes = os.match(path.join(toolchains, "*-ld"))
        for _, ldpath in ipairs(ldpathes) do
            local ldname = path.basename(ldpath)
            if ldname then
                cross = ldname:sub(1, -3)
            end
        end
    end

    -- check for c/c++ tools
    checker.check_toolchain(config, "cc",       cross,   "gcc",         "the c compiler") 
    checker.check_toolchain(config, "cc",       cross,   "clang",       "the c compiler") 
    checker.check_toolchain(config, "cxx",      cross,   "gcc",         "the c++ compiler") 
    checker.check_toolchain(config, "cxx",      cross,   "clang",       "the c++ compiler") 
    checker.check_toolchain(config, "cxx",      cross,   "g++",         "the c++ compiler") 
    checker.check_toolchain(config, "cxx",      cross,   "clang++",     "the c++ compiler") 
    checker.check_toolchain(config, "ld",       cross,   "g++",         "the linker") 
    checker.check_toolchain(config, "ld",       cross,   "gcc",         "the linker") 
    checker.check_toolchain(config, "ld",       cross,   "clang++",     "the linker") 
    checker.check_toolchain(config, "ld",       cross,   "clang",       "the linker") 
    checker.check_toolchain(config, "ar",       cross,   "ar",          "the static library archiver") 
    checker.check_toolchain(config, "ex",       cross,   "ar",          "the static library extractor") 
    checker.check_toolchain(config, "sh",       cross,   "g++",         "the shared library linker") 
    checker.check_toolchain(config, "sh",       cross,   "gcc",         "the shared library linker") 
    checker.check_toolchain(config, "sh",       cross,   "clang++",     "the shared library linker") 
    checker.check_toolchain(config, "sh",       cross,   "clang",       "the shared library linker") 
    checker.check_toolchain(config, "dg",       cross,   "gdb",         "the debugger") 
    checker.check_toolchain(config, "dg",       cross,   "lldb",        "the debugger") 

    -- check for objc/c++ tools
    checker.check_toolchain(config, "mm",       cross,   "clang",       "the objc compiler") 
    checker.check_toolchain(config, "mm",       cross,   "gcc",         "the objc compiler") 
    checker.check_toolchain(config, "mxx",      cross,   "clang++",     "the objc++ compiler") 
    checker.check_toolchain(config, "mxx",      cross,   "clang",       "the objc++ compiler") 
    checker.check_toolchain(config, "mxx",      cross,   "g++",         "the objc++ compiler") 
    checker.check_toolchain(config, "mxx",      cross,   "gcc",         "the objc++ compiler") 

    -- check for asm tools
    checker.check_toolchain(config, "as",       cross,   "clang",       "the assember") 
    checker.check_toolchain(config, "as",       cross,   "gcc",         "the assember") 

    -- check for golang tools
    checker.check_toolchain(config, "go",       "",      "go",          "the golang compiler") 
    checker.check_toolchain(config, "go",       "",      "gccgo",       "the golang compiler") 
    checker.check_toolchain(config, "go-ar",    "",      "go",          "the golang static library archiver") 
    checker.check_toolchain(config, "go-ar",    "",      "gccgo",       "the golang static library archiver") 
    checker.check_toolchain(config, "go-ld",    "",      "go",          "the golang linker") 
    checker.check_toolchain(config, "go-ld",    "",      "gccgo",       "the golang linker") 

    -- check for dlang tools
    checker.check_toolchain(config, "dc",       "",      "dmd",         "the dlang compiler") 
    checker.check_toolchain(config, "dc",       "",      "ldc2",        "the dlang compiler") 
    checker.check_toolchain(config, "dc",       "",      "gdc",         "the dlang compiler") 
    checker.check_toolchain(config, "dc-ar",    "",      "dmd",         "the dlang static library archiver") 
    checker.check_toolchain(config, "dc-ar",    "",      "ldc2",        "the dlang static library archiver") 
    checker.check_toolchain(config, "dc-ar",    "",      "gdc",         "the dlang static library archiver") 
    checker.check_toolchain(config, "dc-sh",    "",      "dmd",         "the dlang shared library linker") 
    checker.check_toolchain(config, "dc-sh",    "",      "ldc2",        "the dlang shared library linker") 
    checker.check_toolchain(config, "dc-sh",    "",      "gdc",         "the dlang shared library linker") 
    checker.check_toolchain(config, "dc-ld",    "",      "dmd",         "the dlang linker") 
    checker.check_toolchain(config, "dc-ld",    "",      "ldc2",        "the dlang linker") 
    checker.check_toolchain(config, "dc-ld",    "",      "gdc",         "the dlang linker") 

    -- check for rust tools
    checker.check_toolchain(config, "rc",       "",      "rustc",       "the rust compiler") 
end

-- check it
function main(kind)

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

    -- check it
    checker.check(kind, _g)
end

