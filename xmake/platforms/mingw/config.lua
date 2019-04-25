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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        config.lua
--

-- imports
import("core.project.config")
import("core.base.singleton")
import("detect.sdks.find_mingw")
import("private.platform.toolchain")
import("private.platform.check_arch")
import("private.platform.check_toolchain")

-- check the mingw toolchain
function _check_mingw()
    local mingw = find_mingw(config.get("mingw"), {verbose = true, bindir = config.get("bin"), cross = config.get("cross")})
    if mingw then
        config.set("mingw", mingw.sdkdir, {force = true, readonly = true}) 
        config.set("cross", mingw.cross, {readonly = true, force = true})
        config.set("bin", mingw.bindir, {readonly = true, force = true})
    else
        -- failed
        cprint("${bright color.error}please run:")
        cprint("    - xmake config --ndk=xxx")
        cprint("or  - xmake global --ndk=xxx")
        raise()
    end
end

-- get toolchains
function _toolchains()

    -- get cross
    local cross = config.get("cross")

    -- TODO add to environment module
    -- add bin search library for loading some dependent .dll files windows 
    local bindir = config.get("bin")
    if bindir and is_host("windows") then
        os.addenv("PATH", bindir)
    end

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
    local mrc        = toolchain("the resource compiler")
    local toolchains = {cc = cc, cxx = cxx, cpp = cpp, as = as, ld = ld, sh = sh, ar = ar, ex = ex, ranlib = ranlib, mrc = mrc}

    -- init the c compiler
    cc:add("$(env CC)", {name = "gcc", cross = cross})

    -- init the c++ compiler
    cxx:add("$(env CXX)")
    cxx:add({name = "gcc", cross = cross})
    cxx:add({name = "g++", cross = cross})

    -- init the c preprocessor
    cpp:add("$(env CPP)", {name = "gcc -E", cross = cross})

    -- init the assember
    as:add("$(env AS)", {name = "gcc", cross = cross})

    -- init the linker
    ld:add("$(env LD)", "$(env CXX)")
    ld:add({name = "g++", cross = cross})
    ld:add({name = "gcc", cross = cross})

    -- init the shared library linker
    sh:add("$(env SH)", "$(env CXX)")
    sh:add({name = "g++", cross = cross})
    sh:add({name = "gcc", cross = cross})

    -- init the static library archiver
    ar:add("$(env AR)", {name = "ar", cross = cross})

    -- init the static library extractor
    ex:add("$(env AR)", {name = "ar", cross = cross})

    -- init the static library extractor
    ranlib:add("$(env RANLIB)", {name = "ranlib", cross = cross})

    -- init the resource compiler
    mrc:add({name = "windres", cross = cross})

    return toolchains
end

-- check it
function main(platform, name)

    -- only check the given config name?
    if name then
        local toolchain = singleton.get("mingw.toolchains", _toolchains)[name]
        if toolchain then
            check_toolchain(config, name, toolchain)
        end
    else

        -- check arch
        check_arch(config, "x86_64")

        -- check mingw
        _check_mingw()
    end
end

