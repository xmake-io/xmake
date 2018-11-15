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
-- @file        load.lua
--

-- imports
import("core.project.config")

-- load it
function main(platform)

    -- init flags
    local arch = config.get("arch")
    if arch:startswith("arm64") then
        platform:add("ldflags", "-llog")
        platform:add("shflags", "-llog")
    else
        platform:add("cxflags", "-mthumb")
        platform:add("asflags", "-mthumb")
        platform:add("ldflags", "-llog", "-mthumb")
        platform:add("shflags", "-llog", "-mthumb")
    end

    -- use llvm directory? e.g. android-ndk/toolchains/llvm/prebuilt/darwin-x86_64/bin
    local isllvm = false
    local bindir = config.get("bin")
    if bindir and bindir:find("llvm", 1, true) then
        isllvm = true
    end

    -- init architecture
    if isllvm then

        -- add target
        local targets = 
        {
            ["armv5te"]     = "armv5te-none-linux-androideabi"
        ,   ["armv7-a"]     = "armv7-none-linux-androideabi"
        ,   ["arm64-v8a"]   = "aarch64-none-linux-android"
        ,   ["i386"]        = "i686-none-linux-android"
        ,   ["x86_64"]      = "x86_64-none-linux-android"
        ,   ["mips"]        = "mipsel-none-linux-android"
        }
        platform:add("cxflags", "-target " .. targets[arch])
        platform:add("asflags", "-target " .. targets[arch])
        platform:add("ldflags", "-target " .. targets[arch])
        platform:add("shflags", "-target " .. targets[arch])
        
        -- add gcc toolchain
        local gcc_toolchain = config.get("gcc_toolchain")
        if gcc_toolchain then
            platform:add("cxflags", "-gcc-toolchain " .. gcc_toolchain)
            platform:add("asflags", "-gcc-toolchain " .. gcc_toolchain)
            platform:add("ldflags", "-gcc-toolchain " .. gcc_toolchain)
            platform:add("shflags", "-gcc-toolchain " .. gcc_toolchain)
        end
    else
        -- old version ndk
        platform:add("cxflags", "-march=" .. arch)
        platform:add("asflags", "-march=" .. arch)
        platform:add("ldflags", "-march=" .. arch)
        platform:add("shflags", "-march=" .. arch)
    end

    -- init cxflags for the target kind: binary 
    platform:add("binary.cxflags", "-fPIE", "-pie")

    -- add flags for the sdk directory of ndk
    local ndk = config.get("ndk")
    local ndk_sdkver = config.get("ndk_sdkver")
    if ndk and ndk_sdkver then

        -- add sysroot
        --
        -- @see https://android.googlesource.com/platform/ndk/+/master/docs/UnifiedHeaders.md
        --
        -- Before NDK r14, we had a set of libc headers for each API version. 
        -- In many cases these headers were incorrect. Many exposed APIs that didn‘t exist, and others didn’t expose APIs that did.
        -- 
        -- In NDK r14 (as an opt in feature) we unified these into a single set of headers, called unified headers. 
        -- This single header path is used for every platform level. API level guards are handled with #ifdef. 
        -- These headers can be found in prebuilts/ndk/headers.
        --
        -- Unified headers are built directly from the Android platform, so they are up to date and correct (or at the very least, 
        -- any bugs in the NDK headers will also be a bug in the platform headers, which means we're much more likely to find them).
        --
        -- In r15 unified headers are used by default. In r16, the old headers have been removed.
        --
        local ndk_sdkdir = path.translate(format("%s/platforms/android-%d", ndk, ndk_sdkver)) 
        local ndk_sysroot_be_r14 = path.join(ndk, "sysroot")
        if os.isdir(ndk_sysroot_be_r14) then

            -- the triples
            local triples = 
            {
                ["armv5te"]     = "arm-linux-androideabi"
            ,   ["armv7-a"]     = "arm-linux-androideabi"
            ,   ["arm64-v8a"]   = "aarch64-linux-android"
            ,   ["i386"]        = "i686-linux-android"
            ,   ["x86_64"]      = "x86_64-linux-android"
            }
            platform:add("cxflags", "-D__ANDROID_API__=" .. ndk_sdkver)
            platform:add("asflags", "-D__ANDROID_API__=" .. ndk_sdkver)
            platform:add("cflags",  "--sysroot=" .. ndk_sysroot_be_r14)
            platform:add("cxxflags","--sysroot=" .. ndk_sysroot_be_r14)
            platform:add("asflags", "--sysroot=" .. ndk_sysroot_be_r14)
            platform:add("cflags",  "-isystem " .. path.join(ndk_sysroot_be_r14, "usr", "include", triples[arch]))
            platform:add("cxxflags","-isystem " .. path.join(ndk_sysroot_be_r14, "usr", "include", triples[arch]))
            platform:add("asflags", "-isystem " .. path.join(ndk_sysroot_be_r14, "usr", "include", triples[arch]))
        else
            if arch:startswith("arm64") then
                platform:add("cflags",   format("--sysroot=%s/arch-arm64", ndk_sdkdir))
                platform:add("cxxflags", format("--sysroot=%s/arch-arm64", ndk_sdkdir))
                platform:add("asflags",  format("--sysroot=%s/arch-arm64", ndk_sdkdir))
            else
                platform:add("cflags",   format("--sysroot=%s/arch-arm", ndk_sdkdir))
                platform:add("cxxflags", format("--sysroot=%s/arch-arm", ndk_sdkdir))
                platform:add("asflags",  format("--sysroot=%s/arch-arm", ndk_sdkdir))
            end
        end
        if arch:startswith("arm64") then
            platform:add("ldflags", format("--sysroot=%s/arch-arm64", ndk_sdkdir))
            platform:add("shflags", format("--sysroot=%s/arch-arm64", ndk_sdkdir))
        else
            platform:add("ldflags", format("--sysroot=%s/arch-arm", ndk_sdkdir))
            platform:add("shflags", format("--sysroot=%s/arch-arm", ndk_sdkdir))
        end

        -- add "-fPIE -pie" to ldflags
        platform:add("ldflags", "-fPIE")
        platform:add("ldflags", "-pie")

        -- get c++ stl sdk directory
        local cxxstl_sdkdir = isllvm and path.translate(format("%s/sources/cxx-stl/llvm-libc++", ndk)) or nil
        if (cxxstl_sdkdir == nil or not os.isdir(cxxstl_sdkdir)) and config.get("ndk_toolchains_ver") then -- <= ndk r16
            cxxstl_sdkdir = path.translate(format("%s/sources/cxx-stl/gnu-libstdc++/%s", ndk, config.get("ndk_toolchains_ver"))) 
        end

        -- only for c++ stl
        if cxxstl_sdkdir and os.isdir(cxxstl_sdkdir) then

            -- the toolchains archs
            local toolchains_archs = 
            {
                ["armv5te"]     = "armeabi"
            ,   ["armv7-a"]     = "armeabi-v7a"
            ,   ["arm64-v8a"]   = "arm64-v8a"
            }

            -- add search directories for c++ stl
            platform:add("cxxflags", format("-I%s/include", cxxstl_sdkdir))
            if toolchains_archs[arch] then
                platform:add("cxxflags", format("-I%s/libs/%s/include", cxxstl_sdkdir, toolchains_archs[arch]))
                platform:add("ldflags", format("-L%s/libs/%s", cxxstl_sdkdir, toolchains_archs[arch]))
                platform:add("shflags", format("-L%s/libs/%s", cxxstl_sdkdir, toolchains_archs[arch]))
                if cxxstl_sdkdir:find("llvm-libc++", 1, true) then
                    platform:add("ldflags", "-lc++_static", "-lc++abi")
                    platform:add("shflags", "-lc++_static", "-lc++abi")
                else
                    platform:add("ldflags", "-lgnustl_static")
                    platform:add("shflags", "-lgnustl_static")
                end
            end
        end
    end

    -- init targets for rust
    local targets = 
    {
        ["armv5te"]     = "arm-linux-androideabi"
    ,   ["armv7-a"]     = "arm-linux-androideabi"
    ,   ["arm64-v8a"]   = "aarch64-linux-android"
    }

    -- init flags for rust
    platform:add("rcflags", "--target=" .. targets[arch])
    platform:add("rc-shflags", "-C link-args=\"" .. (table.concat(platform:get("shflags"), " "):gsub("%-march=.-%s", "") .. "\""))
    platform:add("rc-ldflags", "-C link-args=\"" .. (table.concat(platform:get("ldflags"), " "):gsub("%-march=.-%s", "") .. "\""))
    local sh = config.get("sh")
    if sh then
        platform:add("rc-shflags", "-C linker=" .. sh)
    end
    local ld = config.get("ld")
    if ld then
        platform:add("rc-ldflags", "-C linker=" .. ld)
    end
end


