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

-- get target
function _get_target(arch)
    local targets = {
        ["armeabi-v7a"] = "armv7-linux-ohos"
    ,   ["arm64-v8a"]   = "aarch64-linux-ohos"
    ,   ["x86_64"]      = "x86_64-linux-ohos"
    }
    assert(targets[arch], "unknown arch(%s) for harmony!", arch)
    return targets[arch]
end

-- load hdk toolchain
function main(toolchain)

    -- get gcc toolchain bin directory
    local gcc_toolchain_bin = nil
    local gcc_toolchain = toolchain:config("gcc_toolchain")
    if gcc_toolchain then
        gcc_toolchain_bin = path.join(gcc_toolchain, "bin")
    end

    -- get sdk directory
    local sdkdir = toolchain:sdkdir()

    -- set toolset
    toolchain:set("toolset", "cc", "clang")
    toolchain:set("toolset", "cxx", "clang++")
    toolchain:set("toolset", "cpp", "clang -E")
    toolchain:set("toolset", "as", "clang")
    toolchain:set("toolset", "ld", "clang++", "clang")
    toolchain:set("toolset", "sh", "clang++", "clang")
    toolchain:set("toolset", "ar", "llvm-ar")
    toolchain:set("toolset", "ranlib", "llvm-ranlib")
    toolchain:set("toolset", "strip", "llvm-strip")

    -- add hdk target
    local arch = toolchain:arch()
    local target = _get_target(arch)
    toolchain:add("cxflags", "--target=" .. target)
    toolchain:add("asflags", "--target=" .. target)
    toolchain:add("ldflags", "--target=" .. target)
    toolchain:add("shflags", "--target=" .. target)

    -- add sysroot
    local sysroot = toolchain:config("sysroot")
    if sysroot then
        toolchain:add("cxflags", "--sysroot=" .. sysroot)
        toolchain:add("asflags", "--sysroot=" .. sysroot)
        toolchain:add("ldflags", "--sysroot=" .. sysroot)
        toolchain:add("shflags", "--sysroot=" .. sysroot)
    end

    -- init cxflags for the target kind: binary
    toolchain:add("binary.cxflags", "-fPIE", "-pie")

    -- add "-fPIE -pie" to ldflags
    toolchain:add("ldflags", "-fPIE")
    toolchain:add("ldflags", "-pie")

    -- add some builtin flags
    toolchain:add("cxflags", "-D__MUSL__")
end
