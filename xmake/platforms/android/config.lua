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
import("detect.sdks.find_ndk")
import("detect.sdks.find_android_sdk")
import("private.platform.toolchain")
import("private.platform.check_arch")
import("private.platform.check_toolchain")

-- check the ndk toolchain
function _check_ndk()
    local ndk = find_ndk(config.get("ndk"), {force = true, verbose = true})
    if ndk then
        config.set("ndk", ndk.sdkdir, {force = true, readonly = true}) -- maybe to global
        config.set("bin", ndk.bindir, {force = true, readonly = true})
        config.set("cross", ndk.cross, {force = true, readonly = true})
        config.set("gcc_toolchain", ndk.gcc_toolchain, {force = true, readonly = true})
    else
        -- failed
        cprint("${bright color.error}please run:")
        cprint("    - xmake config --ndk=xxx")
        cprint("or  - xmake global --ndk=xxx")
        raise()
    end
end

-- check the android sdk
function _check_android_sdk()
    local sdk = find_android_sdk(config.get("android_sdk"), {force = true, verbose = true})
    if sdk then
        config.set("sdk", sdk.sdkdir, {force = true, readonly = true}) -- maybe to global
    end
end

-- get toolchains
function _toolchains()

    -- get cross
    local cross = config.get("cross") 

    -- get gcc toolchain bin directory
    local gcc_toolchain_bin = nil
    local gcc_toolchain = config.get("gcc_toolchain")
    if gcc_toolchain then
        gcc_toolchain_bin = path.join(gcc_toolchain, "bin")
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
    local rc         = toolchain("the rust compiler")
    local rc_ld      = toolchain("the rust linker")
    local rc_sh      = toolchain("the rust shared library linker")
    local rc_ar      = toolchain("the rust static library archiver")
    local toolchains = {cc = cc, cxx = cxx, cpp = cpp, as = as, ld = ld, sh = sh, ar = ar, ex = ex, ranlib = ranlib, 
                        rc = rc, ["rc-ld"] = rc_ld, ["rc-sh"] = rc_sh, ["rc-ar"] = rc_ar}

    -- init the c compiler
    cc:add({name = "gcc", cross = cross}, "clang")

    -- init the c++ compiler
    cxx:add({name = "g++", cross = cross}, "clang++")

    -- init the c preprocessor
    cpp:add({name = "gcc -E", cross = cross}, "clang -E")

    -- init the assember
    as:add({name = "gcc", cross = cross}, "clang")

    -- init the linker
    ld:add({name = "gcc", cross = cross})
    ld:add({name = "g++", cross = cross})
    ld:add("clang", "clang++")

    -- init the shared library linker
    sh:add({name = "gcc", cross = cross})
    sh:add({name = "g++", cross = cross})
    sh:add("clang", "clang++")

    -- init the static library archiver
    ar:add({name = "ar", cross = cross, pathes = gcc_toolchain_bin}, "llvm-ar")

    -- init the static library extractor
    ex:add({name = "ar", cross = cross, pathes = gcc_toolchain_bin}, "llvm-ar")

    -- init the static library index generator
    ranlib:add({name = "ranlib", cross = cross, pathes = gcc_toolchain_bin}, "ranlib")

    -- init the rust compiler and linker
    rc:add("$(env RC)", "rustc")
    rc_ld:add("$(env RC)", "rustc")
    rc_sh:add("$(env RC)", "rustc")
    rc_ar:add("$(env RC)", "rustc")

    return toolchains
end

-- check it
function main(platform, name)

    -- only check the given config name?
    if name then
        local toolchain = singleton.get("android.toolchains", _toolchains)[name]
        if toolchain then
            check_toolchain(config, name, toolchain)
        end
    else

        -- check arch
        check_arch(config, "armv7-a")

        -- check ndk
        _check_ndk()

        -- check android sdk
        _check_android_sdk()

        -- check ld and sh, @note toolchains must be initialized after calling check_ndk()
        local toolchains = singleton.get("android.toolchains", _toolchains)
        check_toolchain(config, "ld", toolchains.ld)
        check_toolchain(config, "sh", toolchains.sh)
    end
end

