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

    -- init architecture
    local arch = config.get("arch") or os.arch()
    local simulator = (arch == "i386" or arch == "x86_64")

    -- init cross
    local cross = simulator and "xcrun -sdk iphonesimulator " or "xcrun -sdk iphoneos "

    -- init toolchains
    local cc         = toolchain("the c compiler")
    local cpp        = toolchain("the c preprocessor")
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
    local toolchains = {cc = cc, cpp = cpp, cxx = cxx, as = as, ld = ld, sh = sh, ar = ar, ex = ex, 
                        mm = mm, mxx = mxx, sc = sc, ["sc-ld"] = sc_ld, ["sc-sh"] = sc_sh}

    -- init the c compiler
    cc:add({name = "clang", cross = cross})

    -- init the c preprocessor
    cpp:add({name = "clang -arch " .. arch .. " -E", cross = cross})

    -- init the c++ compiler
    cxx:add({name = "clang", cross = cross})
    cxx:add({name = "clang++", cross = cross})

    -- init the assember
    if simulator then
        as:add({name = "clang", cross = cross})
    else
        as:add({name = "clang", cross = path.join(os.programdir(), "scripts", "gas-preprocessor.pl " .. cross)})
    end

    -- init the linker
    ld:add({name = "clang++", cross = cross})
    ld:add({name = "clang", cross = cross})

    -- init the shared library linker
    sh:add({name = "clang++", cross = cross})
    sh:add({name = "clang", cross = cross})

    -- init the static library archiver
    ar:add({name = "ar", cross = cross})

    -- init the static library extractor
    ex:add({name = "ar", cross = cross})

    -- init the objc compiler
    mm:add({name = "clang", cross = cross})

    -- init the objc++ compiler
    mxx:add({name = "clang", cross = cross})
    mxx:add({name = "clang++", cross = cross})

    -- init the swift compiler and linker
    sc:add({name = "swiftc", cross = cross})
    sc_ld:add({name = "swiftc", cross = cross})
    sc_sh:add({name = "swiftc", cross = cross})

    return toolchains
end

-- check it
function main(platform, name)

    -- only check the given config name?
    if name then
        local toolchain = singleton.get("iphoneos.toolchains." .. (config.get("arch") or os.arch()), _toolchains)[name]
        if toolchain then
            check_toolchain(config, name, toolchain)
        end
    else

        -- check arch
        check_arch(config, "arm64")

        -- check xcode 
        check_xcode(config)
    end
end

