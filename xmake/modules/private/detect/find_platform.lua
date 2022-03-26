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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_platform.lua
--

-- imports
import("core.project.config")
import("core.project.project")
import("detect.sdks.find_cross_toolchain")

-- find platform
function _find_plat(plat)
    plat = plat or config.get("plat")
    if not plat then
        if not plat then
            plat = project.get("defaultplat")
        end
        if not plat then
            plat = os.subhost()
        end
        if plat == "msys" then
            local msystem = os.getenv("MSYSTEM")
            if msystem and msystem:lower():find("mingw", 1, true) then
                plat = "mingw"
            end
        end
    end
    return plat
end

-- find architecture for cross platform
function _find_arch_from_cross()
    local cross  = config.get("cross")
    if not cross then
        local cross_toolchain = find_cross_toolchain(config.get("sdk"), {bindir = config.get("bin")})
        if cross_toolchain then
            cross = cross_toolchain.cross
        end
    end
    local arch = "none"
    if cross then
        if cross:find("aarch64", 1, true) then
            arch = "arm64"
        elseif cross:find("arm", 1, true) then
            arch = "arm"
        elseif cross:find("mips64", 1, true) then
            arch = "mips64"
        elseif cross:find("mips", 1, true) then
            arch = "mips"
        elseif cross:find("riscv64", 1, true) then
            arch = "riscv64"
        elseif cross:find("riscv", 1, true) then
            arch = "riscv"
        elseif cross:find("s390x", 1, true) then
            arch = "s390x"
        elseif cross:find("powerpc64", 1, true) then
            arch = "ppc64"
        elseif cross:find("powerpc", 1, true) then
            arch = "ppc"
        elseif cross:find("sh4", 1, true) then
            arch = "sh4"
        elseif cross:find("x86_64", 1, true) then
            arch = "x86_64"
        elseif cross:find("i386", 1, true) or cross:find("i686", 1, true) then
            arch = "i386"
        end
    end
    return arch
end

-- find architecture
function _find_arch(plat, arch)
    arch = arch or config.get("arch")
    if not arch then
        if not arch then
            arch = project.default_arch(plat)
        end
        if not arch then
            local appledev = config.get("appledev")
            if plat == "android" then
                arch = "armeabi-v7a"
            elseif plat == "iphoneos" or plat == "appletvos" then
                arch = appledev == "simulator" and os.arch() or "arm64"
            elseif plat == "watchos" then
                arch = appledev == "simulator" and os.arch() or "armv7k"
            elseif plat == "wasm" then
                arch = "wasm32"
            elseif plat == "mingw" then
                local mingw_chost = nil
                if is_subhost("msys") then
                    mingw_chost = os.getenv("MINGW_CHOST")
                end
                if mingw_chost == "i686-w64-mingw32" then
                    arch = "i386"
                else
                    arch = "x86_64"
                end
            elseif plat == "cross" then
                arch = _find_arch_from_cross()
            else
                arch = os.subarch()
            end
        end
    end
    return arch
end

-- find default platform and architecture
--
-- @param   opt the argument options, e.g. {plat = "", arch = "", global = true}
--
-- @return  plat, arch
--
-- @code
--
-- find the default platform:
--   local result = find_platform()
--
-- find the default architecture from the given platform:
--   local result = find_platform({plat = "iphoneos"})
--
-- @endcode
--
function main(opt)

    -- find platform
    opt = opt or {}
    local plat = _find_plat(opt.plat)
    if opt.global then
        if not opt.plat and not config.get("plat") then
            config.set("plat", plat)
            cprint("checking for platform ... ${color.success}%s", plat)
        end
    end

    -- find architecture
    local arch = _find_arch(plat, opt.arch)
    if opt.global then
        if not opt.arch and not config.get("arch") then
            config.set("arch", arch)
            cprint("checking for architecture ... ${color.success}%s", arch)
        end
    end
    return plat, arch
end
