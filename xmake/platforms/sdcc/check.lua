--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check.lua
--

-- imports
import("core.project.config")
import("core.base.singleton")
import("detect.sdks.find_cross_toolchain")
import("private.platform.toolchain")
import("private.platform.check_arch")
import("private.platform.check_toolchain")

-- check the architecture
function _check_arch()

    -- get the architecture
    local arch = config.get("arch")
    if not arch then
        config.set("arch", "stm8")
    end
end

-- check the cross toolchain
function _check_cross_toolchain()
    -- find cross toolchain
    local cross_toolchain = find_cross_toolchain(config.get("sdk") or config.get("bin"), {bindir = config.get("bin"), cross = config.get("cross")})
    if cross_toolchain then
        config.set("cross", cross_toolchain.cross, {readonly = true, force = true})
        config.set("bin", cross_toolchain.bindir, {readonly = true, force = true})

        -- TODO add to environment module
        -- add bin search library for loading some dependent .dll files windows 
        if cross_toolchain.bindir and is_host("windows") then
            os.addenv("PATH", cross_toolchain.bindir)
        end
    end
end

-- get toolchains
function _toolchains()

    -- init toolchains
    local cc         = toolchain("the c compiler")
    local cxx        = toolchain("the c++ compiler")
    local cpp        = toolchain("the c preprocessor")
    local ld         = toolchain("the linker")
    local sh         = toolchain("the shared library linker")
    local ar         = toolchain("the static library archiver")
    local ex         = toolchain("the static library extractor")
    local ranlib     = toolchain("the static library index generator")
    local as         = toolchain("the assember")
    local toolchains = {cc = cc, cxx = cxx, cpp = cpp, as = as, ld = ld, sh = sh, ar = ar, ex = ex, ranlib = ranlib}

    -- init the c compiler
    cc:add("$(env CC)", "sdcc")

    -- init the c preprocessor
    cpp:add("$(env CPP)", "sdcpp")

    -- init the c++ compiler
    cxx:add("$(env CXX)", "sdcc")

    -- init the assember
    as:add("$(env AS)", "sdcc")

    -- init the linker
    ld:add("$(env LD)", "$(env CXX)", "sdcc")

    -- init the shared library linker
    sh:add("$(env SH)", "$(env CXX)", "sdcc")

    -- init the static library archiver
    ar:add("$(env AR)", "sdar")

    -- init the static library extractor
    ex:add("$(env AR)", "sdar")
    return toolchains
end

-- check it
function main(platform, name)

    -- only check the given config name?
    if name then
        local toolchain = singleton.get("cross.toolchains", _toolchains)[name]
        if toolchain then
            check_toolchain(config, name, toolchain)
        end
    else

        -- check arch
        _check_arch()

        -- check cross toolchain
        _check_cross_toolchain()
    end
end

