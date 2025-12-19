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
    if is_host("macosx") then
        set_toolset("dsymutil", "dsymutil")
    end

    set_toolset("sc",   "$(env SC)", "swift-frontend", "swiftc")
    set_toolset("scsh", "$(env SC)", "swiftc")
    set_toolset("scar", "$(env SC)", "swiftc")
    set_toolset("scld", "$(env SC)", "swiftc")

    on_check("check")

    on_load(function (toolchain)
        import("private.utils.toolchain", {alias = "toolchain_utils"})

        -- set llvm runtimes
        toolchain_utils.set_llvm_runtimes(toolchain)

        -- add llvm runenvs
        toolchain_utils.add_llvm_runenvs(toolchain)

        -- add target flags
        local flags = toolchain_utils.get_clang_target_flags(toolchain)
        if flags then
            toolchain:add("cxflags", flags)
            toolchain:add("mxflags", flags)
            toolchain:add("asflags", flags)
            toolchain:add("ldflags", flags)
            toolchain:add("shflags", flags)
        end

        -- add target flags for swift
        local target = toolchain_utils.get_clang_target(toolchain)
        if target then
            local flag = "--target=" .. target
            toolchain:add("scasflags", flag)
            toolchain:add("scldflags", flag)
            toolchain:add("scshflags", flag)
        end

        -- init flags for platform
        if toolchain:is_plat("windows") and not is_host("windows") then
            toolchain:add("ldflags", "-fuse-ld=lld")
            toolchain:add("shflags", "-fuse-ld=lld")
        elseif toolchain:is_plat("macosx", "iphoneos", "tvos", "watchos", "xros") then
            if not toolchain:config("xcode_sysroot") and not get_config("xcode_sysroot") then
                local xcode_dir     = toolchain:config("xcode") or get_config("xcode")
                local xcode_sdkver  = toolchain:config("xcode_sdkver") or get_config("xcode_sdkver")
                local sdkdir
                if toolchain:is_plat("macosx") then
                    -- @see https://github.com/xmake-io/xmake/issues/1179
                    local sdkroot = xcode_dir and path.join(xcode_dir, "Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs")
                                              or "/Library/Developer/CommandLineTools/SDKs"
                    sdkdir = xcode_sdkver and path.join(sdkroot, "MacOSX" .. xcode_sdkver .. ".sdk")
                    if not sdkdir or not os.isdir(sdkdir) then
                        sdkdir = path.join(sdkroot, "MacOSX.sdk")
                        sdkdir = os.isdir(sdkdir) and sdkdir or nil
                    end
                else
                    local mapper = {
                        iphoneos = { arm64 = "iPhoneOS", ["x86_64"] = "iPhoneSimulator" },
                        tvos = { arm64 = "AppleTVOS", ["x86_64"] = "AppleTVSimulator" },
                        watchos = { arm64 = "WatchOS", ["x86_64"] = "WatchSimulator" },
                        xros = { arm64 = "XROS", ["x86_64"] = "XRSimulator" }
                    }
                    local plat = mapper[toolchain:plat()][toolchain:arch()]
                    local sdkroot = xcode_dir and path.join(xcode_dir, "Contents/Developer/Platforms/" .. plat ..".platform/Developer/SDKs")
                    if xcode_sdkver and os.isdir(path.join(sdkroot, plat .. xcode_sdkver .. ".sdk")) then
                        sdkdir = path.join(sdkroot, plat .. xcode_sdkver .. ".sdk")
                    elseif os.isdir(path.join(sdkroot, plat .. ".sdk")) then
                        sdkdir = path.join(sdkroot, plat .. ".sdk")
                    end
                    assert(sdkdir and os.isdir(sdkdir), "No xcode sysroot found!")
                end
                toolchain:config_set("xcode_sysroot", sdkdir)
            end
            -- load configurations
            import(".xcode.load_" .. toolchain:plat())(toolchain)
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
    end)

