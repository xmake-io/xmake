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
import("core.platform.environment")
import("private.platform.toolchain")
import("private.platform.check_arch")
import("private.platform.check_vstudio")
import("private.platform.check_toolchain")

-- get toolchains
function _toolchains()

    -- init cross
    local cross = "xcrun -sdk macosx "

    -- init toolchains
    local cc         = toolchain("the c compiler")
    local cxx        = toolchain("the c++ compiler")
    local mrc        = toolchain("the resource compiler")
    local ld         = toolchain("the linker")
    local sh         = toolchain("the shared library linker")
    local ar         = toolchain("the static library archiver")
    local ex         = toolchain("the static library extractor")
    local as         = toolchain("the assember")
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
    local toolchains = {cc = cc, cxx = cxx, mrc = mrc, as = as, ld = ld, sh = sh, ar = ar, ex = ex, 
                        gc = gc, ["gc-ld"] = gc_ld, ["gc-ar"] = gc_ar,
                        dc = dc, ["dc-ld"] = dc_ld, ["dc-sh"] = dc_sh, ["dc-ar"] = dc_ar,
                        rc = rc, ["rc-ld"] = rc_ld, ["rc-sh"] = rc_sh, ["rc-ar"] = rc_ar,
                        cu = cu, ["cu-ld"] = cu_ld}

    -- init the c compiler
    cc:add("cl.exe")

    -- init the c++ compiler
    cxx:add("cl.exe")

    -- init the resource compiler
    mrc:add("rc.exe")

    -- init the assember
    if config.get("arch"):find("64") then
        as:add("ml64.exe")
    else
        as:add("ml.exe")
    end

    -- init the linker
    ld:add("link.exe")

    -- init the shared library linker
    sh:add("link.exe -dll")

    -- init the static library archiver
    ar:add("link.exe -lib")

    -- init the static library extractor
    ex:add("lib.exe")

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

    return toolchains
end

-- check it
function main(platform, name)

    -- only check the given config name?
    if name then
        local toolchain = singleton.get("windows.toolchains." .. (config.get("arch") or os.arch()), _toolchains)[name]
        if toolchain then
            environment.enter("toolchains")
            check_toolchain(config, name, toolchain)
            environment.leave("toolchains")
        end
    else

        -- check arch 
        check_arch(config)

        -- check vstudio
        check_vstudio(config)
    end
end

