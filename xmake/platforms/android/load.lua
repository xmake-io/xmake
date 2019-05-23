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
-- @file        load.lua
--

-- imports
import("core.project.config")

-- load it
function main(platform)

    -- init flags
    local arch = config.get("arch")
    platform:add("ldflags", "-llog")
    platform:add("shflags", "-llog")
    if arch and (arch == "armv5te" or arch == "armv7-a") then
        platform:add("cxflags", "-mthumb")
        platform:add("asflags", "-mthumb")
        platform:add("ldflags", "-mthumb")
        platform:add("shflags", "-mthumb")
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

        -- the sysroot archs
        local sysroot_archs = 
        {
            ["armv5te"]     = "arch-arm"
        ,   ["armv7-a"]     = "arch-arm"
        ,   ["arm64-v8a"]   = "arch-arm64"
        ,   i386            = "arch-x86"
        ,   x86_64          = "arch-x86_64"
        ,   mips            = "arch-mips"
        ,   mips64          = "arch-mips64"
        }
        local sysroot_arch = sysroot_archs[arch]

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
            ,   i386            = "i686-linux-android"
            ,   x86_64          = "x86_64-linux-android"
            ,   mips            = "mips-linux-android"
            ,   mips64          = "mips64-linux-android"
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
            if sysroot_arch then
                platform:add("cflags",   format("--sysroot=%s/%s", ndk_sdkdir, sysroot_arch))
                platform:add("cxxflags", format("--sysroot=%s/%s", ndk_sdkdir, sysroot_arch))
                platform:add("asflags",  format("--sysroot=%s/%s", ndk_sdkdir, sysroot_arch))
            end
        end
        if sysroot_arch then
            platform:add("ldflags", format("--sysroot=%s/%s", ndk_sdkdir, sysroot_arch))
            platform:add("shflags", format("--sysroot=%s/%s", ndk_sdkdir, sysroot_arch))
        end

        -- add "-fPIE -pie" to ldflags
        platform:add("ldflags", "-fPIE")
        platform:add("ldflags", "-pie")

        -- get llvm c++ stl sdk directory
        local cxxstl_sdkdir_llvmstl = path.translate(format("%s/sources/cxx-stl/llvm-libc++", ndk))

        -- get gnu c++ stl sdk directory
        local cxxstl_sdkdir_gnustl = nil
        if config.get("ndk_toolchains_ver") then
            cxxstl_sdkdir_gnustl = path.translate(format("%s/sources/cxx-stl/gnu-libstdc++/%s", ndk, config.get("ndk_toolchains_ver"))) 
        end

        -- get stlport c++ sdk directory
        local cxxstl_sdkdir_stlport = path.translate(format("%s/sources/cxx-stl/stlport", ndk))

        -- get c++ stl sdk directory
        local cxxstl_sdkdir = nil
        local ndk_cxxstl = config.get("ndk_cxxstl")
        if ndk_cxxstl then
            if ndk_cxxstl:startswith("llvmstl") then
                cxxstl_sdkdir = cxxstl_sdkdir_llvmstl
            elseif ndk_cxxstl:startswith("gnustl") then
                cxxstl_sdkdir = cxxstl_sdkdir_gnustl
            elseif ndk_cxxstl:startswith("stlport") then
                cxxstl_sdkdir = cxxstl_sdkdir_stlport
            end
        else
            if isllvm then
                ndk_cxxstl = "llvmstl_static"
                cxxstl_sdkdir = cxxstl_sdkdir_llvmstl
            end
            if (cxxstl_sdkdir == nil or not os.isdir(cxxstl_sdkdir)) and cxxstl_sdkdir_gnustl then -- <= ndk r16
                ndk_cxxstl = "gnustl_static"
                cxxstl_sdkdir = cxxstl_sdkdir_gnustl
            end
        end

        -- only for c++ stl
        if config.get("ndk_stdcxx") and cxxstl_sdkdir and os.isdir(cxxstl_sdkdir) then

            -- the toolchains archs
            local toolchains_archs = 
            {
                ["armv5te"]     = "armeabi"
            ,   ["armv7-a"]     = "armeabi-v7a"
            ,   ["arm64-v8a"]   = "arm64-v8a"
            ,   i386            = "x86"
            ,   x86_64          = "x86_64"
            ,   mips            = "mips"
            ,   mips64          = "mips64"
            }
            local toolchains_arch = toolchains_archs[arch]

            -- add c++ stl include and link directories
            if toolchains_arch then
                platform:add("ldflags", format("-L%s/libs/%s", cxxstl_sdkdir, toolchains_arch))
                platform:add("shflags", format("-L%s/libs/%s", cxxstl_sdkdir, toolchains_arch))
            end
            if ndk_cxxstl:startswith("llvmstl") then
                platform:add("cxxflags", format("-I%s/include", cxxstl_sdkdir))
                if toolchains_arch then
                    platform:add("cxxflags", format("-I%s/libs/%s/include", cxxstl_sdkdir, toolchains_arch))
                end
                local abi_path = path.join(ndk, "sources", "cxx-stl", "llvm-libc++abi")
                local before_r13 = path.join(abi_path, "libcxxabi")
                local after_r13 = path.join(abi_path, "include")
                if os.isdir(before_r13) then
                    platform:add("cxxflags", "-I" .. before_r13)
                elseif os.isdir(after_r13) then
                    platform:add("cxxflags", "-I" .. after_r13)
                end
            elseif ndk_cxxstl:startswith("gnustl") then
                platform:add("cxxflags", format("-I%s/include", cxxstl_sdkdir))
                if toolchains_arch then
                    platform:add("cxxflags", format("-I%s/libs/%s/include", cxxstl_sdkdir, toolchains_arch))
                end
            elseif ndk_cxxstl:startswith("stlport") then
                platform:add("cxxflags", format("-I%s/stlport", cxxstl_sdkdir))
            end

            -- add c++ stl links
            if ndk_cxxstl == "llvmstl_static" then
                platform:add("ldflags", "-lc++_static", "-lc++abi")
                platform:add("shflags", "-lc++_static", "-lc++abi")
            elseif ndk_cxxstl == "llvmstl_shared" then
                platform:add("ldflags", "-lc++_shared", "-lc++")
                platform:add("shflags", "-lc++_shared", "-lc++")
            elseif ndk_cxxstl == "gnustl_static" then
                platform:add("ldflags", "-lgnustl_static")
                platform:add("shflags", "-lgnustl_static")
            elseif ndk_cxxstl == "gnustl_shared" then
                platform:add("ldflags", "-lgnustl_shared")
                platform:add("shflags", "-lgnustl_shared")
            elseif ndk_cxxstl == "stlport_static" then
                platform:add("ldflags", "-lstlport_static")
                platform:add("shflags", "-lstlport_static")
            elseif ndk_cxxstl == "stlport_shared" then
                platform:add("ldflags", "-lstlport_shared")
                platform:add("shflags", "-lstlport_shared")
            end
            
        end
    end

    -- init targets for rust
    local targets_rust = 
    {
        ["armv5te"]     = "arm-linux-androideabi"
    ,   ["armv7-a"]     = "arm-linux-androideabi"
    ,   ["arm64-v8a"]   = "aarch64-linux-android"
    }

    -- init flags for rust
    if targets_rust[arch] then
        platform:add("rcflags", "--target=" .. targets_rust[arch])
    end
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


