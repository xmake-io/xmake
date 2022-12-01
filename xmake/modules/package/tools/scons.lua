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
-- @author      PucklaMotzer09
-- @file        scons.lua
--

-- imports
import("core.base.option")
import("core.tool.toolchain")
import("lib.detect.find_tool")

-- get configs
function _get_configs(package, configs)
    local configs = configs or {}
    table.insert(configs, "target=" .. (package:is_debug() and "debug" or "release"))
    table.insert(configs, "use_mingw=" .. (package:is_plat("mingw", "cygwin", "msys") and "yes" or "no"))
    if package:is_plat("android") then
        local scons_android_arch = "armv7"
        if package:is_arch("arm64-v8a") then
            scons_android_arch = "arm64v8"
        end
        table.insert(configs, "platform=android")
        table.insert(configs, "android_arch=" .. scons_android_arch)
    elseif package:is_plat("iphoneos") then
        table.insert(configs, "platform=ios")
        table.insert(configs, "ios_arch=" .. package:arch())
    elseif package:is_plat("macosx") then
        table.insert(configs, "platform=osx")
    elseif package:is_plat("windows", "mingw", "cygwin", "msys") then
        table.insert(configs, "platform=windows")
    elseif package:is_plat("linux") then
        table.insert(configs, "platform=linux")
    elseif package:is_plat("bsd") then
        table.insert(configs, "platform=freebsd")
    end
    if package:is_plat("x86_64", "x86", "i386", "x64") then
        table.insert("bits=" .. (package:is_arch("x86", "i386") and "32" or "64"))
    end
    return configs
end

-- get the build environments
function buildenvs(package, opt)
    opt = opt or {}
    local envs = {}
    if package:is_plat("android") then
        local ndk = toolchain.load("ndk", {plat = package:plat(), arch = package:arch()})
        envs.ANDROID_NDK_ROOT = ndk:config("ndk")
    end
    local ACLOCAL_PATH = {}
    local PKG_CONFIG_PATH = {}
    for _, dep in ipairs(package:librarydeps()) do
        local pkgconfig = path.join(dep:installdir(), "lib", "pkgconfig")
        if os.isdir(pkgconfig) then
            table.insert(PKG_CONFIG_PATH, pkgconfig)
        end
        pkgconfig = path.join(dep:installdir(), "share", "pkgconfig")
        if os.isdir(pkgconfig) then
            table.insert(PKG_CONFIG_PATH, pkgconfig)
        end
        local aclocal = path.join(dep:installdir(), "share", "aclocal")
        if os.isdir(aclocal) then
            table.insert(ACLOCAL_PATH, aclocal)
        end
    end
    envs.ACLOCAL_PATH    = path.joinenv(ACLOCAL_PATH)
    envs.PKG_CONFIG_PATH = path.joinenv(PKG_CONFIG_PATH)
    return envs
end

-- build package
function build(package, configs, opt)
    opt = opt or {}
    local buildir = opt.buildir or os.curdir()
    local njob = opt.jobs or option.get("jobs") or tostring(os.default_njob())
    local scons = assert(find_tool("scons"), "scons not found!")
    local argv = {"-C", buildir, "-j", njob}
    configs = _get_configs(package, configs)
    if configs then
        table.join2(argv, configs)
    end
    os.vrunv(scons.program, argv, {envs = opt.envs or buildenvs(package, opt)})
end
