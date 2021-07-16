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
-- @file        check.lua
--

-- imports
import("core.project.config")
import("lib.detect.find_path")
import("detect.sdks.find_xcode")
import("detect.sdks.find_cross_toolchain")

-- find xcode on macos
function _find_xcode(toolchain)

    -- find xcode
    local xcode_sdkver = toolchain:config("xcode_sdkver") or config.get("xcode_sdkver")
    local xcode = find_xcode(toolchain:config("xcode") or config.get("xcode"), {force = true, verbose = true,
                                                   find_codesign = false,
                                                   sdkver = xcode_sdkver,
                                                   plat = toolchain:plat(),
                                                   arch = toolchain:arch()})
    if not xcode then
        cprint("checking for Xcode directory ... ${color.nothing}${text.nothing}")
        return
    end

    -- xcode found
    xcode_sdkver = xcode.sdkver
    if toolchain:is_global() then
        config.set("xcode", xcode.sdkdir, {force = true, readonly = true})
        cprint("checking for Xcode directory ... ${color.success}%s", xcode.sdkdir)
    end
    toolchain:config_set("xcode", xcode.sdkdir)
    toolchain:config_set("xcode_sdkver", xcode_sdkver)
    toolchain:configs_save()
    cprint("checking for SDK version of Xcode for %s (%s) ... ${color.success}%s", toolchain:plat(), toolchain:arch(), xcode_sdkver)
end

-- check the cross toolchain
function main(toolchain)

    -- get sdk directory
    local sdkdir = toolchain:sdkdir()
    local bindir = toolchain:bindir()
    if not sdkdir and not bindir then
        if is_host("linux") and os.isfile("/usr/bin/llvm-ar") then
            sdkdir = "/usr"
        elseif is_host("macosx") then
            local bindir = find_path("llvm-ar", "/usr/local/Cellar/llvm/*/bin")
            if bindir then
                sdkdir = path.directory(bindir)
            end
        end
    end

    -- find cross toolchain from external envirnoment
    local cross_toolchain = find_cross_toolchain(sdkdir, {bindir = bindir})
    if not cross_toolchain then
        -- find it from packages
        for _, package in ipairs(toolchain:packages()) do
            local installdir = package:installdir()
            if installdir and os.isdir(installdir) then
                cross_toolchain = find_cross_toolchain(installdir)
                if cross_toolchain then
                    break
                end
            end
        end
    end
    if cross_toolchain then
        toolchain:config_set("cross", cross_toolchain.cross)
        toolchain:config_set("bindir", cross_toolchain.bindir)
        toolchain:configs_save()
    else
        raise("llvm toolchain not found!")
    end

    -- attempt to find xcode to pass `-isysroot` on macos
    if toolchain:is_plat("macosx") then
        _find_xcode(toolchain)
    end
    return cross_toolchain
end
