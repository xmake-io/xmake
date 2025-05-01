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
import("lib.detect.find_tool")
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
    local cross  = toolchain:cross()

    if not bindir then
        bindir = try {function () return os.iorunv("llvm-config", {"--bindir"}) end}
        if not bindir then
            if is_host("macosx") then
                if os.arch() == "arm64" then
                    bindir = find_path("llvm-ar", "/opt/homebrew/opt/llvm/bin")
                else
                    bindir = find_path("llvm-ar", "/usr/local/Cellar/llvm/*/bin")
                end
            elseif is_host("windows") then
                local llvm_ar = find_tool("llvm-ar", {force = true, envs = {PATH = os.getenv("PATH")}})
                if llvm_ar and llvm_ar.program and path.is_absolute(llvm_ar.program) then
                    bindir = path.directory(llvm_ar.program)
                end
            end
        end
        -- trim possible trailing \n
        bindir = bindir:trim()
    end
    
    if not sdkdir then
        if bindir then
            sdkdir = path.directory(bindir)
        elseif is_host("linux") and os.isfile("/usr/bin/llvm-ar") then
            sdkdir = "/usr"
        end
    end

    -- find cross toolchain from external envirnoment
    local cross_toolchain = find_cross_toolchain(sdkdir, {bindir = bindir, cross = cross})
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
    if cross_toolchain and cross_toolchain.cross ~= "" then
        toolchain:config_set("cross", cross_toolchain.cross or cross)
        toolchain:config_set("bindir", cross_toolchain.bindir)
        toolchain:config_set("sdkdir", cross_toolchain.sdkdir)
        toolchain:configs_save()
    end

    -- attempt to find xcode to pass `-isysroot` on macos
    if toolchain:is_plat("macosx") then
        _find_xcode(toolchain)
    end
    return cross_toolchain
end
