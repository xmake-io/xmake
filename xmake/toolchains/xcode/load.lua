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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        load.lua
--
-- imports
import("private.utils.toolchain", {alias = "toolchain_utils"})

-- set toolset programs from xcode toolchain bindir/arch/appledev
function _set_toolset(toolchain, bindir, arch, appledev)

    local xc_clang          = bindir and path.join(bindir, "clang") or "clang"
    local xc_clangxx        = bindir and path.join(bindir, "clang++") or "clang++"
    local xc_ar             = bindir and path.join(bindir, "ar") or "ar"
    local xc_strip          = bindir and path.join(bindir, "strip") or "strip"
    local xc_swift_frontend = bindir and path.join(bindir, "swift-frontend") or "swift-frontend"
    local xc_swiftc         = bindir and path.join(bindir, "swiftc") or "swiftc"
    local xc_dsymutil       = bindir and path.join(bindir, "dsymutil") or "dsymutil"

    toolchain:set("toolset", "cc", xc_clang)
    toolchain:set("toolset", "cxx", xc_clangxx, xc_clang)
    toolchain:set("toolset", "ld", xc_clangxx, xc_clang)
    toolchain:set("toolset", "sh", xc_clangxx, xc_clang)
    toolchain:set("toolset", "ar", xc_ar)
    toolchain:set("toolset", "strip", xc_strip)
    toolchain:set("toolset", "dsymutil", xc_dsymutil, "dsymutil")
    toolchain:set("toolset", "mm", xc_clang)
    toolchain:set("toolset", "mxx", xc_clangxx, xc_clang)
    toolchain:set("toolset", "sc", xc_swift_frontend, "swift_frontend", xc_swiftc, "swiftc")
    toolchain:set("toolset", "scld", xc_swiftc, "swiftc")
    toolchain:set("toolset", "scsh", xc_swiftc, "swiftc")
    toolchain:set("toolset", "scar", xc_swiftc, "swiftc")
    if arch then
        toolchain:set("toolset", "cpp", xc_clang .. " -arch " .. arch .. " -E")
    end
    if toolchain:is_plat("macosx") then
        toolchain:set("toolset", "as", xc_clang)
    elseif appledev == "simulator" or appledev == "catalyst" then
        toolchain:set("toolset", "as", xc_clang)
    else
        toolchain:set("toolset", "as", path.join(os.programdir(), "scripts", "gas-preprocessor.pl " .. xc_clang))
    end
end

-- add platform-independent flags for xcode toolchain
function _add_common_flags(toolchain, xcode_sysroot)

    -- init target triple flags
    local targetflag = {"-target", toolchain_utils.get_xcode_target_triple(toolchain)}

    -- init flags for c/c++
    toolchain:add("cxflags", targetflag, "-isysroot", xcode_sysroot)
    if toolchain:is_plat("macosx") then
        toolchain:add("ldflags", targetflag, "-isysroot", xcode_sysroot, "-lz")
        toolchain:add("shflags", targetflag, "-isysroot", xcode_sysroot, "-lz")
    else
        toolchain:add("ldflags", targetflag, "-isysroot", xcode_sysroot, "-ObjC", "-fobjc-link-runtime")
        toolchain:add("shflags", targetflag, "-isysroot", xcode_sysroot, "-ObjC", "-fobjc-link-runtime")
    end

    -- init flags for objc/c++
    toolchain:add("mxflags", targetflag, "-isysroot", xcode_sysroot)

    -- we can use `add_mxflags("-fno-objc-arc")` to override it in xmake.lua
    toolchain:add("mxflags", "-fobjc-arc")

    -- init flags for asm
    toolchain:add("asflags", targetflag, "-isysroot", xcode_sysroot)

    -- init flags for swift
    toolchain:add("scflags", {"-sdk", xcode_sysroot}, targetflag)
    toolchain:add("scshflags", {"-sdk", xcode_sysroot}, targetflag, "-emit-library")
    toolchain:add("scarflags", {"-sdk", xcode_sysroot}, targetflag, "-emit-library", "-static")
    toolchain:add("scldflags", {"-sdk", xcode_sysroot}, targetflag, "-emit-executable")
end

-- add extra headers/libs/frameworks for catalyst (macosx + appledev=catalyst)
function _add_catalyst_support(toolchain, xcode_sysroot)

    toolchain:add("cxflags", {"-I", path.join(xcode_sysroot, "System/iOSSupport/usr/include")})
    toolchain:add("mxflags", {"-I", path.join(xcode_sysroot, "System/iOSSupport/usr/include")})

    toolchain:add("asflags", {"-I", path.join(xcode_sysroot, "System/iOSSupport/usr/include")})
    toolchain:add("ldflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})
    toolchain:add("shflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})

    toolchain:add("scflags", {"-I", path.join(xcode_sysroot, "System/iOSSupport/usr/include")})
    toolchain:add("scldflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})
    toolchain:add("scshflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})
    toolchain:add("scarflags", {"-L", path.join(xcode_sysroot, "System/iOSSupport/usr/lib")})

    toolchain:add("cxflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
    toolchain:add("mxflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})

    toolchain:add("asflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
    toolchain:add("ldflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
    toolchain:add("shflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})

    toolchain:add("scflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
    toolchain:add("scshflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
    toolchain:add("scarflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
    toolchain:add("scldflags", {"-iframework", path.join(xcode_sysroot, "System/iOSSupport/System/Library/Frameworks")})
end

-- main entry
function main(toolchain)

    local bindir = toolchain:bindir()
    local arch = toolchain:arch()
    local appledev = toolchain:config("appledev")
    local xcode_sysroot = toolchain:config("xcode_sysroot")
    if toolchain:is_plat("macosx") then
        assert(appledev ~= "simulator")
    end

    -- init toolset
    _set_toolset(toolchain, bindir, arch, appledev)

    -- init flags
    _add_common_flags(toolchain, xcode_sysroot)

    -- init extra flags for catalyst
    if toolchain:is_plat("macosx") and xcode_sysroot and appledev == "catalyst" then
        _add_catalyst_support(toolchain, xcode_sysroot)
    end
end
