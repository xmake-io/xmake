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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        xmake.lua
--

toolchain("llvm")
    set_kind("standalone")
    set_homepage("https://llvm.org/")
    set_description("A collection of modular and reusable compiler and toolchain technologies")
    set_runtimes("c++_static", "c++_shared", "stdc++_static", "stdc++_shared")

    set_toolset("cc",      "clang")
    set_toolset("cxx",     "clang++", "clang")
    set_toolset("mxx",     "clang++", "clang")
    set_toolset("mm",      "clang")
    set_toolset("cpp",     "clang -E")
    set_toolset("as",      "clang")
    set_toolset("ld",      "clang++", "clang")
    set_toolset("sh",      "clang++", "clang")
    set_toolset("ar",      "llvm-ar")
    set_toolset("strip",   "llvm-strip")
    set_toolset("ranlib",  "llvm-ranlib")
    set_toolset("objcopy", "llvm-objcopy")
    set_toolset("mrc",     "llvm-rc")
    set_toolset("dlltool", "llvm-dlltool")

    set_toolset("sc",   "$(env SC)", "swift-frontend", "swiftc")
    set_toolset("scsh", "$(env SC)", "swiftc")
    set_toolset("scar", "$(env SC)", "swiftc")
    set_toolset("scld", "$(env SC)", "swiftc")

    on_check("check")

    on_load(function (toolchain)

        -- add runtimes
        if toolchain:is_plat("windows") then
            toolchain:add("runtimes", "MT", "MTd", "MD", "MDd")
        end

        -- add target flags
        local target
        if toolchain:is_plat("windows") and not is_host("windows") then
            if toolchain:is_arch("i386", "x86") then
                target = "i386-pc-windows-msvc"
            else
                target = "x86_64-pc-windows-msvc"
            end
        elseif toolchain:is_plat("cross") then
            target = toolchain:cross():gsub("(.*)%-$", "%1")
        end
        local target_flags
        if target then
            target_flags = "--target=" .. target
        elseif toolchain:is_arch("x86_64", "x64") then
            target_flags = "-m64"
        elseif toolchain:is_arch("i386", "x86") then
            target_flags = "-m32"
        end
        if target_flags then
            toolchain:add("cxflags", target_flags)
            toolchain:add("mxflags", target_flags)
            toolchain:add("asflags", target_flags)
            toolchain:add("ldflags", target_flags)
            toolchain:add("shflags", target_flags)
            toolchain:add("scasflags", "--target=" .. target_flags)
            toolchain:add("scldflags", "--target=" .. target_flags)
            toolchain:add("scshflags", "--target=" .. target_flags)
        end

        -- init flags for platform
        if toolchain:is_plat("windows") and not is_host("windows") then
            toolchain:add("ldflags", "-fuse-ld=lld")
            toolchain:add("shflags", "-fuse-ld=lld")
        elseif toolchain:is_plat("macosx") then
            if not toolchain:config("xcode_sysroot") then
                local xcode_dir     = get_config("xcode")
                local xcode_sdkver  = toolchain:config("xcode_sdkver")
                local xcode_sdkdir  = path.join(xcode_dir, "Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX" .. xcode_sdkver .. ".sdk")
                if os.isdir(xcode_sdkdir) then
                    toolchain:config_set("xcode_sysroot", xcode_sdkdir)
                end
            end
            -- load configurations
            import(".xcode.load_" .. toolchain:plat())(toolchain)
            toolchain:add("mxflags", "-fobjc-arc")
        elseif toolchain:is_plat("cross") then
            local sysroot
            local sdkdir = toolchain:sdkdir()
            local bindir = toolchain:bindir()
            local cross = toolchain:cross():gsub("(.*)%-$", "%1")
            if bindir and os.isexec(path.join(bindir, cross .. "-gcc" .. (is_host("windows") and ".exe" or ""))) then
                local gcc_toolchain = path.directory(bindir)
                toolchain:add("cxflags", "--gcc-toolchain=" .. gcc_toolchain)
                toolchain:add("mxflags", "--gcc-toolchain=" .. gcc_toolchain)
                toolchain:add("asflags", "--gcc-toolchain=" .. gcc_toolchain)
                toolchain:add("ldflags", "--gcc-toolchain=" .. gcc_toolchain)
                toolchain:add("shflags", "--gcc-toolchain=" .. gcc_toolchain)
            end
            if sdkdir and os.isdir(path.join(sdkdir, cross, "include")) then
                sysroot = path.join(sdkdir, cross)
            end
            if sysroot then
                if os.isdir(path.join(sysroot, "libc")) then
                    sysroot = path.join(sysroot, "libc")
                end
                toolchain:add("cxflags", "--sysroot=" .. sysroot)
                toolchain:add("mxflags", "--sysroot=" .. sysroot)
                toolchain:add("asflags", "--sysroot=" .. sysroot)
                toolchain:add("ldflags", "--sysroot=" .. sysroot)
                toolchain:add("shflags", "--sysroot=" .. sysroot)
            end
        end

        -- add bin search library for loading some dependent .dll files windows
        local bindir = toolchain:bindir()
        if bindir and is_host("windows") then
            toolchain:add("runenvs", "PATH", bindir)
        end
    end)

