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
import("private.platform.toolchain")
import("private.platform.check_arch")
import("private.platform.check_xcode")
import("private.platform.check_toolchain")

-- get toolchains
function _toolchains()

    -- init cross
    local cross = "xcrun -sdk macosx "

    -- init toolchains
    local cc         = toolchain("the c compiler")
    local cxx        = toolchain("the c++ compiler")
    local ld         = toolchain("the linker")
    local sh         = toolchain("the shared library linker")
    local ar         = toolchain("the static library archiver")
    local ex         = toolchain("the static library extractor")
    local mm         = toolchain("the objc compiler")
    local mxx        = toolchain("the objc++ compiler")
    local as         = toolchain("the assember")
    local sc         = toolchain("the swift compiler")
    local sc_ld      = toolchain("the swift linker")
    local sc_sh      = toolchain("the swift shared library linker")
    local gc         = toolchain("the golang compiler")
    local gc_ld      = toolchain("the golang linker")
    local gc_ar      = toolchain("the golang static library archiver")
    local dc         = toolchain("the dlang compiler")
    local dc_ld      = toolchain("the dlang linker")
    local dc_sh      = toolchain("the dlang shared library linker")
    local dc_ar      = toolchain("the dlang static library archiver")
    local rc         = toolchain("the rust compiler")
    local rc_ld      = toolchain("the rust linker")
    local rc_sh      = toolchain("the rust shared library linker")
    local rc_ar      = toolchain("the rust static library archiver")
    local cu         = toolchain("the cuda compiler")
    local cu_ld      = toolchain("the cuda linker")
    local cu_ccbin   = toolchain("the cuda host c++ compiler")
    local toolchains = {cc = cc, cxx = cxx, as = as, ld = ld, sh = sh, ar = ar, ex = ex, 
                        mm = mm, mxx = mxx, sc = sc, ["sc-ld"] = sc_ld, ["sc-sh"] = sc_sh,
                        gc = gc, ["gc-ld"] = gc_ld, ["gc-ar"] = gc_ar,
                        dc = dc, ["dc-ld"] = dc_ld, ["dc-sh"] = dc_sh, ["dc-ar"] = dc_ar,
                        rc = rc, ["rc-ld"] = rc_ld, ["rc-sh"] = rc_sh, ["rc-ar"] = rc_ar,
                        cu = cu, ["cu-ld"] = cu_ld, ["cu-ccbin"] = cu_ccbin}

    -- init the c compiler
    cc:add("$(env CC)", {name = "clang", cross = cross}, "clang", "gcc")

    -- init the c++ compiler
    cxx:add("$(env CXX)")
    cxx:add({name = "clang", cross = cross})
    cxx:add({name = "clang++", cross = cross})
    cxx:add("clang", "clang++", "gcc", "g++")

    -- init the assember
    as:add("$(env AS)", {name = "clang", cross = cross}, "clang", "gcc")

    -- init the linker
    ld:add("$(env LD)", "$(env CXX)")
    ld:add({name = "clang++", cross = cross})
    ld:add({name = "clang", cross = cross})
    ld:add("clang++", "g++", "clang", "gcc")

    -- init the shared library linker
    sh:add("$(env SH)", "$(env CXX)")
    sh:add({name = "clang++", cross = cross})
    sh:add({name = "clang", cross = cross})
    sh:add("clang++", "g++", "clang", "gcc")

    -- init the static library archiver
    ar:add("$(env AR)", {name = "ar", cross = cross}, "ar")

    -- init the static library extractor
    ex:add({name = "ar", cross = cross}, "ar")

    -- init the objc compiler
    mm:add("$(env MM)", {name = "clang", cross = cross}, "clang", "gcc")

    -- init the objc++ compiler
    mxx:add("$(env MXX)")
    mxx:add({name = "clang", cross = cross})
    mxx:add({name = "clang++", cross = cross})
    mxx:add("clang", "clang++", "gcc", "g++")

    -- init the swift compiler and linker
    sc:add("$(env SC)", {name = "swiftc", cross = cross}, "swiftc")
    sc_ld:add("$(env SC)", {name = "swiftc", cross = cross}, "swiftc")
    sc_sh:add("$(env SC)", {name = "swiftc", cross = cross}, "swiftc")

    -- init the golang compiler and linker
    gc:add("$(env GC)", "go", "gccgo")
    gc_ld:add("$(env GC)", "go", "gccgo")
    gc_ar:add("$(env GC)", "go", "gccgo")

    -- init the dlang compiler and linker
    dc:add("$(env DC)", "dmd", "ldc2", "gdc")
    dc_ld:add("$(env DC)", "dmd", "ldc2", "gdc")
    dc_sh:add("$(env DC)", "dmd", "ldc2", "gdc")
    dc_ar:add("$(env DC)", "dmd", "ldc2", "gdc")

    -- init the rust compiler and linker
    rc:add("$(env RC)", "rustc")
    rc_ld:add("$(env RC)", "rustc")
    rc_sh:add("$(env RC)", "rustc")
    rc_ar:add("$(env RC)", "rustc")

    -- init the cuda compiler and linker
    cu:add("nvcc", "clang")
    cu_ld:add("nvcc")
    cu_ccbin:add("$(env CXX)", "$(env CC)", "clang", "gcc")

    return toolchains
end

-- check it
function main(platform, name)

    -- only check the given config name?
    if name then
        local toolchain = singleton.get("macosx.toolchains." .. (config.get("arch") or os.arch()), _toolchains)[name]
        if toolchain then
            check_toolchain(config, name, toolchain)
        end
    else

        -- check arch
        check_arch(config)

        -- check xcode 
        check_xcode(config, true)
    end
end

