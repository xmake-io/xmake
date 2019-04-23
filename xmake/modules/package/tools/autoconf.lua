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
-- @file        autoconf.lua
--

-- get configs
function _get_configs(package, configs)
    local configs = configs or {}
    table.insert(configs, "--prefix=" .. package:installdir())
    if package:is_plat("iphoneos") then
        local hosts = { arm64 = "aarch64-apple-darwin",
                        arm64e = "aarch64-apple-darwin",
                        armv7  = "armv7-apple-darwin",
                        armv7s = "armv7s-apple-darwin",
                        i386   = "i386-apple-darwin",
                        x86_64 = "x86_64-apple-darwin"}
        table.insert(configs, "--host=" .. (hosts[package:arch()] or "aarch64-apple-darwin"))
    elseif package:is_plat("android") then
        -- @see https://developer.android.com/ndk/guides/other_build_systems#autoconf
        local triples = 
        {
            ["armv5te"]     = "arm-linux-androideabi"
        ,   ["armv7-a"]     = "armv7a-linux-androideabi"
        ,   ["arm64-v8a"]   = "aarch64-linux-android"
        ,   i386            = "i686-linux-android"
        ,   x86_64          = "x86_64-linux-android"
        ,   mips            = "mips-linux-android"
        ,   mips64          = "mips64-linux-android"
        }
        table.insert(configs, "--host=" .. (triples[package:arch()] or "armv7a-linux-androideabi"))
    end
    return configs
end

-- enter environments
function _enter_envs(package)
    
    -- get old environments
    local envs           = {}
    envs.CC              = os.getenv("CC")
    envs.AS              = os.getenv("AS")
    envs.AR              = os.getenv("AR")
    envs.LD              = os.getenv("LD")
    envs.CPP             = os.getenv("CPP")
    envs.LDSHARED        = os.getenv("LDSHARED")
    envs.RANLIB          = os.getenv("RANLIB")
    envs.CFLAGS          = os.getenv("CFLAGS")
    envs.CXXFLAGS        = os.getenv("CXXFLAGS")
    envs.ASFLAGS         = os.getenv("ASFLAGS")
    envs.LDFLAGS         = os.getenv("LDFLAGS")
    envs.ARFLAGS         = os.getenv("ARFLAGS")
    envs.SHFLAGS         = os.getenv("SHFLAGS")
    envs.ACLOCAL_PATH    = os.getenv("ACLOCAL_PATH")
    envs.PKG_CONFIG_PATH = os.getenv("PKG_CONFIG_PATH")

    -- set new environments
    if package:is_plat(os.host()) then
        os.addenvp("CFLAGS",   package:config("cflags"), ' ')
        os.addenvp("CFLAGS",   package:config("cxflags"), ' ')
        os.addenvp("CXXFLAGS", package:config("cxflags"), ' ')
        os.addenvp("CXXFLAGS", package:config("cxxflags"), ' ')
        os.addenvp("ASFLAGS",  package:config("asflags"), ' ')
    else
        os.setenv("RANLIB",   "")
        os.setenvp("CC",       package:build_getenv("cc"), ' ')
        os.setenvp("AS",       package:build_getenv("as"), ' ')
        os.setenvp("AR",       package:build_getenv("ar"), ' ')
        os.setenvp("LD",       package:build_getenv("ld"), ' ')
        os.setenvp("LDSHARED", package:build_getenv("sh"), ' ')
        os.setenvp("CPP",      package:build_getenv("cpp"), ' ')
        os.addenvp("CFLAGS",   package:build_getenv("cflags"), ' ')
        os.addenvp("CFLAGS",   package:build_getenv("cxflags"), ' ')
        os.addenvp("CXXFLAGS", package:build_getenv("cxflags"), ' ')
        os.addenvp("CXXFLAGS", package:build_getenv("cxxflags"), ' ')
        os.addenvp("ASFLAGS",  package:build_getenv("asflags"), ' ')
        os.addenvp("ARFLAGS",  package:build_getenv("arflags"), ' ')
        os.addenvp("LDFLAGS",  package:build_getenv("ldflags"), ' ')
        os.addenvp("SHFLAGS",  package:build_getenv("shflags"), ' ')
    end
    for _, dep in ipairs(package:orderdeps()) do
        local pkgconfig = path.join(dep:installdir(), "lib", "pkgconfig")
        if os.isdir(pkgconfig) then
            os.addenv("PKG_CONFIG_PATH", pkgconfig)
        end
        local aclocal = path.join(dep:installdir(), "share", "aclocal")
        if os.isdir(aclocal) then
            os.addenv("ACLOCAL_PATH", aclocal)
        end
    end
    return envs
end

-- leave environments
function _leave_envs(package, envs)
    for k, v in pairs(envs) do
        os.setenv(k, v)
    end
end

-- configure package
function configure(package, configs)

    -- generate configure file
    if not os.isfile("configure") then
        if os.isfile("autogen.sh") then
            os.vrunv("sh", {"./autogen.sh"})
        elseif os.isfile("configure.ac") then
            os.vrun("autoreconf --install --symlink")
        end
    end

    -- pass configurations
    local argv = {}
    for name, value in pairs(_get_configs(package, configs)) do
        value = tostring(value):trim()
        if type(name) == "number" then
            if value ~= "" then
                table.insert(argv, value)
            end
        else
            table.insert(argv, "--" .. name .. "=" .. value)
        end
    end

    -- enter environments
    local envs = _enter_envs(package)

    -- do configure
    os.vrunv("./configure", argv)

    -- leave environments
    _leave_envs(package, envs)
end

-- install package
function install(package, configs)

    -- do configure
    configure(package, configs)

    -- do make and install
    os.vrun("make install -j4")
end

