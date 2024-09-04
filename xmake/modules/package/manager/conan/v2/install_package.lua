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
-- @author      ruki
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.project.config")
import("core.tool.toolchain")
import("core.platform.platform")
import("lib.detect.find_tool")
import("devel.git")
import("net.fasturl")

-- get build env
function _conan_get_build_env(name, plat)
    local value = config.get(name)
    if value == nil then
        value = platform.toolconfig(name, plat)
    end
    if value == nil then
        value = platform.tool(name, plat)
    end
    value = table.unique(table.wrap(value))
    if #value > 0 then
        value = table.unwrap(value)
        return value
    end
end

-- get build directory
function _conan_get_build_directory(name)
    return path.absolute(path.join(config.buildir() or os.tmpdir(), ".conan", name))
end

-- generate conanfile.txt
function _conan_generate_conanfile(name, configs, opt)

    -- trace
    dprint("generate %s ..", path.join(_conan_get_build_directory(name), "conanfile.txt"))

    -- get conan options, imports and build_requires
    local options        = table.wrap(configs.options)
    local build_requires = table.wrap(configs.build_requires)

    -- @see https://docs.conan.io/1/migrating_to_2.0/recipes.html
    -- https://docs.conan.io/en/latest/systems_cross_building/cross_building.html
    -- generate it
    local conanfile = io.open("conanfile.txt", "w")
    if conanfile then
        conanfile:print("[requires]")
        local require_version = opt.require_version
        if require_version ~= nil and require_version ~= "latest" then
            conanfile:print("%s/%s", name, require_version)
        else
            conanfile:print("%s", name)
        end
        if #options > 0 then
            conanfile:print("[options]")
            for _, item in ipairs(options) do
                if not item:find(":", 1, true) then
                    item = name .. "/*:" .. item
                end
                conanfile:print("%s", item)
            end
        end
        if #build_requires > 0 then
            conanfile:print("[tool_requires]")
            conanfile:print("%s", table.concat(build_requires, "\n"))
        end
        conanfile:close()
    end
end

-- get conan home directory
function _conan_get_homedir(conan)
    local homedir = _g.homedir
    if homedir == nil then
        homedir = try {function () return os.iorunv(conan.program, {"config", "home"}) end}
        _g.homedir = homedir
    end
    return homedir
end

-- install xmake generator
-- @see https://github.com/conan-io/conan/pull/13718
--
function _conan_install_xmake_generator(conan)
    local homedir = assert(_conan_get_homedir(conan), "cannot get conan home")
    local scriptfile_now = path.join(os.programdir(), "scripts", "conan", "extensions", "generators", "xmake_generator.py")
    local scriptfile_installed = path.join(homedir, "extensions", "generators", "xmake_generator.py")
    if not os.isfile(scriptfile_installed) or os.mtime(scriptfile_now) > os.mtime(scriptfile_installed) then
        os.vrunv(conan.program, {"config", "install", path.join(os.programdir(), "scripts", "conan")})
    end
end

-- get arch
function _conan_get_arch(arch)
    local map = {x86_64          = "x86_64",
                 x64             = "x86_64",
                 i386            = "x86",
                 x86             = "x86",
                 armv7           = "armv7",
                 ["armv7-a"]     = "armv7",  -- for android, deprecated
                 ["armeabi"]     = "armv7",  -- for android, removed in ndk r17
                 ["armeabi-v7a"] = "armv7",  -- for android
                 armv7s          = "armv7s", -- for iphoneos
                 arm64           = "armv8",  -- for iphoneos
                 ["arm64-v8a"]   = "armv8",  -- for android
                 mips            = "mips",
                 mips64          = "mips64"}
    return assert(map[arch], "unknown arch(%s)!", arch)
end

-- get os
function _conan_get_os(plat)
    local map = {macosx   = "Macos",
                 windows  = "Windows",
                 mingw    = "Windows",
                 linux    = "Linux",
                 cross    = "Linux",
                 iphoneos = "iOS",
                 android  = "Android"}
    return assert(map[plat], "unknown os(%s)!", plat)
end

-- get build type
function _conan_get_build_type(mode)
    if mode == "debug" then
        return "Debug"
    else
        return "Release"
    end
end

-- get compiler version
--
-- https://github.com/conan-io/conan/blob/353c63b16c31c90d370305b5cbb5dc175cf8a443/conan/tools/microsoft/visual.py#L13
-- https://github.com/xmake-io/xmake/issues/5338
function _conan_get_compiler_version(name, opt)
    opt = opt or {}
    local version
    local result = find_tool(name, {program = opt.program, version = true, envs = opt.envs})
    if result and result.version then
        local v = semver.try_parse(result.version)
        if v then
            if name == "cl" then
                version = tostring(v:major()) .. tostring(v:minor()):sub(1, 1)
            else
                version = tostring(v:major())
            end
        end
    end
    return version
end

-- generate compiler profile
function _conan_generate_compiler_profile(profile, configs, opt)
    local conf
    local plat = opt.plat
    local arch = opt.arch
    local runtimes = configs.runtimes
    if plat == "windows" then
        local msvc = toolchain.load("msvc", {plat = plat, arch = arch})
        assert(msvc:check(), "vs not found!")
        local vs = assert(msvc:config("vs"), "vs not found!")
        profile:print("compiler=msvc")
        local version = _conan_get_compiler_version("cl", {envs = msvc:runenvs()})
        if version then
            profile:print("compiler.version=" .. version)
        end
        -- @see https://github.com/conan-io/conan/issues/12387
        if tonumber(vs) >= 2015 then
            profile:print("compiler.cppstd=14")
        end
        if runtimes then
            profile:print("compiler.runtime=" .. (runtimes:startswith("MD") and "dynamic" or "static"))
            profile:print("compiler.runtime_type=" .. (runtimes:endswith("d") and "Debug" or "Release"))
        end
    elseif plat == "iphoneos" then
        local target_minver = nil
        local xcode = toolchain.load("xcode", {plat = plat, arch = arch})
        if xcode then
            target_minver = xcode:config("target_minver")
        end
        if target_minver and tonumber(target_minver) > 10 and (arch == "armv7" or arch == "armv7s" or arch == "x86") then
            target_minver = "10" -- iOS 10 is the maximum deployment target for 32-bit targets
        end
        if target_minver then
            profile:print("os.version=" .. target_minver)
        end
        local simulator = xcode:config("appledev") == "simulator"
        profile:print("os.sdk=" .. (simulator and "iphonesimulator" or "iphoneos"))
        profile:print("compiler=clang")
        local version = _conan_get_compiler_version("clang")
        if version then
            profile:print("compiler.version=" .. version)
        end
    elseif plat == "android" then
        local ndk = toolchain.load("ndk", {plat = plat, arch = arch})
        local ndk_sdkver = ndk:config("ndk_sdkver")
        if ndk_sdkver then
            profile:print("os.api_level=" .. ndk_sdkver)
        end
        if runtimes then
            profile:print("compiler.libcxx=" .. runtimes)
        end
        local program, toolname = ndk:tool("cc")
        local version = _conan_get_compiler_version(toolname, {program = program})
        profile:print("compiler=" .. toolname)
        if version then
            profile:print("compiler.version=" .. version)
        end
        conf = {}
        conf["tools.android:ndk_path"] = ndk:config("ndk")
    else
        local program, toolname = platform.tool("cc", plat, arch)
        if toolname == "gcc" or toolname == "clang" then
            profile:print("compiler=" .. toolname)
            profile:print("compiler.cppstd=gnu17")
            local libcxx = "libstdc++11"
            if runtimes and table.contains(table.wrap(runtimes), "c++_static", "c++_shared") then
                libcxx = "libc++"
            elseif not runtimes and toolname == "clang" then
                libcxx = "libc++"
            end
            profile:print("compiler.libcxx=" .. libcxx)
            local version = _conan_get_compiler_version(toolname, {program = program})
            if version then
                profile:print("compiler.version=" .. version)
            end
        end
    end

    if conf then
        profile:print("")
        profile:print("[conf]")
        for k, v in pairs(conf) do
            profile:print("%s=%s", k, v)
        end
    end
end

-- generate build profile
function _conan_generate_build_profile(configs, opt)
    local profile = io.open("profile_build.txt", "w")
    profile:print("[settings]")
    profile:print("arch=%s", _conan_get_arch(os.arch()))
    profile:print("build_type=%s", _conan_get_build_type(opt.mode))
    profile:print("os=%s", _conan_get_os(os.host()))
    _conan_generate_compiler_profile(profile, configs, {plat = os.host(), arch = os.arch()})
    profile:close()
end

-- generate host profile
function _conan_generate_host_profile(configs, opt)
    local profile = io.open("profile_host.txt", "w")
    profile:print("[settings]")
    profile:print("arch=%s", _conan_get_arch(opt.arch))
    profile:print("build_type=%s", _conan_get_build_type(opt.mode))
    profile:print("os=%s", _conan_get_os(opt.plat))
    _conan_generate_compiler_profile(profile, configs, opt)
    profile:close()
end

-- install package
function main(conan, name, opt)

    -- get configs
    opt = opt or {}
    local configs = opt.configs or {}

    -- get build directory
    local buildir = _conan_get_build_directory(name)

    -- clean the build directory
    os.tryrm(buildir)
    if not os.isdir(buildir) then
        os.mkdir(buildir)
    end

    -- enter build directory
    local oldir = os.cd(buildir)

    -- install xmake generator
    _conan_install_xmake_generator(conan)

    -- generate conanfile.txt
    _conan_generate_conanfile(name, configs, opt)

    -- generate host profile
    _conan_generate_host_profile(configs, opt)

    -- generate build profile
    _conan_generate_build_profile(configs, opt)

    -- install package
    local argv = {"install", ".", "-g", "XmakeGenerator",
        "--profile:build=profile_build.txt", "--profile:host=profile_host.txt"}
    if configs.build then
        if configs.build == "all" then
            table.insert(argv, "--build")
        else
            table.insert(argv, "--build=" .. configs.build)
        end
    end

    -- set custom host settings
    for _, setting in ipairs(configs.settings or configs.settings_host) do
        table.insert(argv, "-s")
        table.insert(argv, setting)
    end

    -- set custom build settings
    for _, setting in ipairs(configs.settings_build) do
        table.insert(argv, "-s:b")
        table.insert(argv, setting)
    end

    -- set remote
    if configs.remote then
        table.insert(argv, "-r")
        table.insert(argv, configs.remote)
    end

    -- do install
    os.vrunv(conan.program, argv)

    -- leave build directory
    os.cd(oldir)
end

