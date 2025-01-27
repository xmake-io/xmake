--!A cross-toolchain build utility based on Lua
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
-- @file        load.lua
--

-- imports
import("core.base.hashset")
import("core.project.config")

-- get triple
function _get_triple(arch)
    local triples =
    {
        ["armv5te"]     = "arm-linux-androideabi"   -- deprecated
    ,   ["armv7-a"]     = "arm-linux-androideabi"   -- deprecated
    ,   ["armeabi"]     = "arm-linux-androideabi"   -- removed in ndk r17
    ,   ["armeabi-v7a"] = "arm-linux-androideabi"
    ,   ["arm64-v8a"]   = "aarch64-linux-android"
    ,   ["riscv64"]     = "riscv64-linux-android"
    ,   i386            = "i686-linux-android"      -- deprecated
    ,   x86             = "i686-linux-android"
    ,   x86_64          = "x86_64-linux-android"
    ,   mips            = "mips-linux-android"      -- removed in ndk r17
    ,   mips64          = "mips64-linux-android"    -- removed in ndk r17
    }
    return triples[arch]
end

-- get target
function _get_target(arch, ndk_sdkver)
    local targets =
    {
        ["armv5te"]     = "armv5te-none-linux-androideabi"  -- deprecated
    ,   ["armeabi"]     = "armv5te-none-linux-androideabi"  -- removed in ndk r17
    ,   ["armv7-a"]     = "armv7-none-linux-androideabi"    -- deprecated
    ,   ["armeabi-v7a"] = "armv7-none-linux-androideabi"
    ,   ["arm64-v8a"]   = "aarch64-none-linux-android"
    ,   ["riscv64"]     = "riscv64-none-linux-android"
    ,   ["i386"]        = "i686-none-linux-android"         -- deprecated
    ,   ["x86"]         = "i686-none-linux-android"
    ,   ["x86_64"]      = "x86_64-none-linux-android"
    ,   ["mips"]        = "mipsel-none-linux-android"       -- removed in ndk r17
    ,   ["mips64"]      = "mips64el-none-linux-android"     -- removed in ndk r17
    }
    assert(targets[arch], "unknown arch(%s) for android!", arch)
    return targets[arch] .. (ndk_sdkver or "")
end

-- load ndk toolchain
--
-- some extra configuration for target
-- e.g.
--   set_values("ndk.arm_mode", "arm") -- or thumb
--
function main(toolchain)

    -- get cross
    local cross = toolchain:cross() or ""

    -- get gcc toolchain bin directory
    local gcc_toolchain_bin = nil
    local gcc_toolchain = toolchain:config("gcc_toolchain")
    if gcc_toolchain then
        gcc_toolchain_bin = path.join(gcc_toolchain, "bin")
    end

    -- get ndk and version
    local ndk = toolchain:config("ndk")
    local ndkver = toolchain:config("ndkver")
    local ndk_sdkver = toolchain:config("ndk_sdkver")

    -- set toolset
    toolchain:set("toolset", "cc", "clang", cross .. "gcc")
    toolchain:set("toolset", "cxx", "clang++", cross .. "g++")
    toolchain:set("toolset", "cpp", "clang -E", cross .. "gcc -E")
    toolchain:set("toolset", "as", "clang", cross .. "gcc")
    toolchain:set("toolset", "ld", "clang++", "clang", cross .. "g++", cross .. "gcc")
    toolchain:set("toolset", "sh", "clang++", "clang", cross .. "g++", cross .. "gcc")
    toolchain:set("toolset", "ar", gcc_toolchain_bin and path.join(gcc_toolchain_bin, cross .. "ar") or (cross .. "ar"), "llvm-ar")
    toolchain:set("toolset", "ranlib", gcc_toolchain_bin and path.join(gcc_toolchain_bin, cross .. "ranlib") or (cross .. "ranlib"))
    toolchain:set("toolset", "strip", gcc_toolchain_bin and path.join(gcc_toolchain_bin, cross .. "strip") or (cross .. "strip"), "llvm-strip")

    -- gnustl and stlport have been removed in ndk r18 (deprecated in ndk r17)
    -- https://github.com/android/ndk/wiki/Changelog-r18
    local old_runtimes = {"gnustl_static", "gnustl_shared", "stlport_static", "stlport_shared"}
    if ndkver and ndkver < 18 then
        toolchain:add("runtimes", table.unpack(old_runtimes))
    end

    -- init flags
    local arm32 = false
    local arch = toolchain:arch()
    toolchain:add("ldflags", "-llog")
    toolchain:add("shflags", "-llog")
    if arch and (arch == "armeabi" or arch == "armeabi-v7a" or arch == "armv5te" or arch == "armv7-a") then -- armv5te/armv7-a are deprecated
        arm32 = true
    end

    -- use llvm directory? e.g. android-ndk/toolchains/llvm/prebuilt/darwin-x86_64/bin
    local isllvm = false
    local bindir = toolchain:bindir()
    if bindir and bindir:find("llvm", 1, true) then
        isllvm = true
    end

    -- init architecture
    if isllvm then

        -- add ndk target
        local ndk_target = _get_target(arch, ndk_sdkver)
        toolchain:add("cxflags", "--target=" .. ndk_target)
        toolchain:add("asflags", "--target=" .. ndk_target)
        toolchain:add("ldflags", "--target=" .. ndk_target)
        toolchain:add("shflags", "--target=" .. ndk_target)

        -- add gcc toolchain
        local gcc_toolchain = toolchain:config("gcc_toolchain")
        if gcc_toolchain then
            toolchain:add("cxflags", "--gcc-toolchain=" .. gcc_toolchain)
            toolchain:add("asflags", "--gcc-toolchain=" .. gcc_toolchain)
            toolchain:add("ldflags", "--gcc-toolchain=" .. gcc_toolchain)
            toolchain:add("shflags", "--gcc-toolchain=" .. gcc_toolchain)
        end
    else
        local march = arch
        if arch == "arm64-v8a" then
            march = "armv8-a"
        else
            march = "armv5te"
        end
        -- old version ndk
        toolchain:add("cxflags", "-march=" .. march)
        toolchain:add("asflags", "-march=" .. march)
        toolchain:add("ldflags", "-march=" .. march)
        toolchain:add("shflags", "-march=" .. march)
    end

    -- init cxflags for the target kind: binary
    toolchain:add("binary.cxflags", "-fPIE", "-pie")

    -- add flags for the sdk directory of ndk
    if ndk and ndk_sdkver then

        -- the sysroot archs
        local sysroot_archs =
        {
            ["armv5te"]     = "arch-arm"    -- deprecated
        ,   ["armv7-a"]     = "arch-arm"    -- deprecated
        ,   ["armeabi"]     = "arch-arm"    -- removed in ndk r17
        ,   ["armeabi-v7a"] = "arch-arm"
        ,   ["arm64-v8a"]   = "arch-arm64"
        ,   ["riscv64"]     = "arch-riscv64"
        ,   i386            = "arch-x86"    -- deprecated
        ,   x86             = "arch-x86"
        ,   x86_64          = "arch-x86_64"
        ,   mips            = "arch-mips"   -- removed in ndk r17
        ,   mips64          = "arch-mips64" -- removed in ndk r17
        }
        local sysroot_arch = sysroot_archs[arch]

        -- add sysroot flags
        local ndk_sysroot = toolchain:config("ndk_sysroot")
        if ndk_sysroot and os.isdir(ndk_sysroot) then
            local triple = _get_triple(arch)
            if ndkver and tonumber(ndkver) < 22 then
                toolchain:add("cxflags", "-D__ANDROID_API__=" .. ndk_sdkver)
                toolchain:add("asflags", "-D__ANDROID_API__=" .. ndk_sdkver)
            end
            local flag_sysroot = "--sysroot=" .. os.args(ndk_sysroot)
            local flag_isystem = "-isystem " .. os.args(path.join(ndk_sysroot, "usr", "include", triple))
            toolchain:add("cflags",   flag_sysroot)
            toolchain:add("cxxflags", flag_sysroot)
            toolchain:add("asflags",  flag_sysroot)
            toolchain:add("cflags",   flag_isystem)
            toolchain:add("cxxflags", flag_isystem)
            toolchain:add("asflags",  flag_isystem)
        else
            local ndk_sdkdir = path.translate(format("%s/platforms/android-%d", ndk, ndk_sdkver))
            if os.isdir(ndk_sdkdir) then
                if sysroot_arch then
                    local flag_sysroot = "--sysroot=" .. os.args(path.join(ndk_sdkdir, sysroot_arch))
                    toolchain:add("cflags",   flag_sysroot)
                    toolchain:add("cxxflags", flag_sysroot)
                    toolchain:add("asflags",  flag_sysroot)
                    toolchain:add("ldflags",  flag_sysroot)
                    toolchain:add("shflags",  flag_sysroot)
                end
            end
        end

        -- add "-fPIE -pie" to ldflags
        toolchain:add("ldflags", "-fPIE")
        toolchain:add("ldflags", "-pie")

        -- get llvm c++ stl sdk directory
        local cxxstl_sdkdir_llvmstl = path.translate(format("%s/sources/cxx-stl/llvm-libc++", ndk))

        -- get gnu c++ stl sdk directory
        local cxxstl_sdkdir_gnustl = nil
        if toolchain:config("ndk_toolchains_ver") then
            cxxstl_sdkdir_gnustl = path.translate(format("%s/sources/cxx-stl/gnu-libstdc++/%s", ndk, toolchain:config("ndk_toolchains_ver")))
        end

        -- get stlport c++ sdk directory
        local cxxstl_sdkdir_stlport = path.translate(format("%s/sources/cxx-stl/stlport", ndk))

        -- get c++ stl sdk directory
        local cxxstl_sdkdir = nil
        local ndk_cxxstl = config.get("runtimes") or config.get("ndk_cxxstl")
        if ndk_cxxstl then
            if (ndkver and ndkver >= 18) and table.contains(old_runtimes, ndk_cxxstl)  then
                utils.warning("%s is was removed in ndk v%s", ndk_cxxstl, ndk_sdkver)
            end

            if ndk_cxxstl:find(",", 1, true) then
                local runtimes_supported = hashset.from(toolchain:get("runtimes"))
                for _, item in ipairs(ndk_cxxstl:split(",")) do
                    if runtimes_supported:has(item) then
                        ndk_cxxstl = item
                        break
                    end
                end
            end
            -- we uses c++_static/c++_shared instead of llvmstl_static/llvmstl_shared
            if ndk_cxxstl:startswith("c++") or ndk_cxxstl:startswith("llvmstl") then
                cxxstl_sdkdir = cxxstl_sdkdir_llvmstl
            elseif ndk_cxxstl:startswith("gnustl") then
                cxxstl_sdkdir = cxxstl_sdkdir_gnustl
            elseif ndk_cxxstl:startswith("stlport") then
                cxxstl_sdkdir = cxxstl_sdkdir_stlport
            end
        else
            if isllvm then
                ndk_cxxstl = "c++_static"
                cxxstl_sdkdir = cxxstl_sdkdir_llvmstl
            end
            if (cxxstl_sdkdir == nil or not os.isdir(cxxstl_sdkdir)) and cxxstl_sdkdir_gnustl then -- <= ndk r16
                ndk_cxxstl = "gnustl_static"
                cxxstl_sdkdir = cxxstl_sdkdir_gnustl
            end
        end

        -- only for c++ stl
        if config.get("ndk_stdcxx") then
            if cxxstl_sdkdir and os.isdir(cxxstl_sdkdir) then

                -- the toolchains archs
                local toolchains_archs =
                {
                    ["armv5te"]     = "armeabi"         -- deprecated
                ,   ["armv7-a"]     = "armeabi-v7a"     -- deprecated
                ,   ["armeabi"]     = "armeabi"         -- removed in ndk r17
                ,   ["armeabi-v7a"] = "armeabi-v7a"
                ,   ["arm64-v8a"]   = "arm64-v8a"
                ,   ["riscv64"]     = "riscv64"
                ,   i386            = "x86"             -- deprecated
                ,   x86             = "x86"
                ,   x86_64          = "x86_64"
                ,   mips            = "mips"            -- removed in ndk r17
                ,   mips64          = "mips64"          -- removed in ndk r17
                }
                local toolchains_arch = toolchains_archs[arch]

                -- add c++ stl include and link directories
                if toolchains_arch then
                    toolchain:add("linkdirs", format("%s/libs/%s", cxxstl_sdkdir, toolchains_arch))
                end
                if ndk_cxxstl:startswith("c++") or ndk_cxxstl:startswith("llvmstl") then
                    toolchain:add("cxxflags", "-nostdinc++")
                    toolchain:add("sysincludedirs", format("%s/include", cxxstl_sdkdir))
                    if toolchains_arch then
                        toolchain:add("sysincludedirs", format("%s/libs/%s/include", cxxstl_sdkdir, toolchains_arch))
                    end
                    local abi_path = path.join(ndk, "sources", "cxx-stl", "llvm-libc++abi")
                    local before_r13 = path.join(abi_path, "libcxxabi")
                    local after_r13 = path.join(abi_path, "include")
                    if os.isdir(before_r13) then
                        toolchain:add("sysincludedirs", before_r13)
                    elseif os.isdir(after_r13) then
                        toolchain:add("sysincludedirs", after_r13)
                    end
                elseif ndk_cxxstl:startswith("gnustl") then
                    toolchain:add("cxxflags", "-nostdinc++")
                    toolchain:add("sysincludedirs", format("%s/include", cxxstl_sdkdir))
                    if toolchains_arch then
                        toolchain:add("sysincludedirs", format("%s/libs/%s/include", cxxstl_sdkdir, toolchains_arch))
                    end
                elseif ndk_cxxstl:startswith("stlport") then
                    toolchain:add("cxxflags", "-nostdinc++")
                    toolchain:add("sysincludedirs", format("%s/stlport", cxxstl_sdkdir))
                end

                -- add c++ stl links
                if ndk_cxxstl == "c++_static" or ndk_cxxstl == "llvmstl_static" then
                    toolchain:add("syslinks", "c++_static", "c++abi")
                    if arm32 then
                        toolchain:add("syslinks", "unwind", "atomic")
                    end
                elseif ndk_cxxstl == "c++_shared" or ndk_cxxstl == "llvmstl_shared" then
                    toolchain:add("syslinks", "c++_shared", "c++abi")
                    if arm32 then
                        toolchain:add("syslinks", "unwind", "atomic")
                    end
                elseif ndk_cxxstl == "gnustl_static" then
                    toolchain:add("syslinks", "gnustl_static")
                elseif ndk_cxxstl == "gnustl_shared" then
                    toolchain:add("syslinks", "gnustl_shared")
                elseif ndk_cxxstl == "stlport_static" then
                    toolchain:add("syslinks", "stlport_static")
                elseif ndk_cxxstl == "stlport_shared" then
                    toolchain:add("syslinks", "stlport_shared")
                end

                -- fix 'ld: error: cannot find -lc++' for clang++.exe on r20/windows
                -- @see https://github.com/xmake-io/xmake/issues/684
                if ndkver and ndkver >= 20 and (ndk_cxxstl:startswith("c++") or ndk_cxxstl:startswith("llvmstl")) then
                    toolchain:add("ldflags", "-nostdlib++")
                    toolchain:add("shflags", "-nostdlib++")
                end
            elseif ndkver and ndkver >= 26 then
                -- The NDK's libc++ now comes directly from our LLVM toolchain above 26b
                -- https://github.com/xmake-io/xmake/issues/4614
                if ndk_cxxstl == "c++_static" then
                    toolchain:add("ldflags", "-static-libstdc++", "-lc++abi")
                    toolchain:add("shflags", "-static-libstdc++", "-lc++abi")
                    if arm32 then
                        toolchain:add("syslinks", "unwind", "atomic")
                    end
                elseif ndk_cxxstl == "c++_shared" then
                    if arm32 then
                        toolchain:add("syslinks", "unwind", "atomic")
                    end
                end
            end
        end
    end

    -- init flags for target
    local target_on_xxflags = function (target)
        if arm32 then
            -- @see https://github.com/xmake-io/xmake/issues/927
            if target:values("ndk.arm_mode") == "arm" then
                return "-marm"
            else
                return "-mthumb"
            end
        end
    end
    toolchain:add("target.on_cxflags", target_on_xxflags)
    toolchain:add("target.on_asflags", target_on_xxflags)
    toolchain:add("target.on_ldflags", target_on_xxflags)
    toolchain:add("target.on_shflags", target_on_xxflags)

    local rcshflags = table.copy(toolchain:get("shflags"))
    local rcldflags = table.copy(toolchain:get("ldflags"))
    for _, link in ipairs(toolchain:get("syslinks")) do
        table.insert(rcshflags, "-l" .. link)
        table.insert(rcldflags, "-l" .. link)
    end
    toolchain:add("rcshflags", "-C link-args=\"" .. (table.concat(rcshflags, " "):gsub("%-march=.-%s", "") .. "\""))
    toolchain:add("rcldflags", "-C link-args=\"" .. (table.concat(rcldflags, " "):gsub("%-march=.-%s", "") .. "\""))
    local sh = toolchain:tool("sh") -- @note we cannot use `config.get("sh")`, because we need to check sh first
    if sh then
        toolchain:add("rcshflags", "-C linker=" .. sh)
    end
    local ld = toolchain:tool("ld")
    if ld then
        toolchain:add("rcldflags", "-C linker=" .. ld)
    end
end
