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
    local imports        = table.wrap(configs.imports)
    local build_requires = table.wrap(configs.build_requires)

    -- @see https://docs.conan.io/en/latest/systems_cross_building/cross_building.html
    -- generate it
    local conanfile = io.open("conanfile.txt", "w")
    if conanfile then
        conanfile:print("[generators]")
        conanfile:print("xmake")
        conanfile:print("[requires]")
        local require_version = opt.require_version
        if require_version ~= nil and require_version ~= "latest" then
            conanfile:print("%s/%s", name, require_version)
        else
            conanfile:print("%s", name)
        end
        if #options > 0 then
            conanfile:print("[options]")
            conanfile:print("%s", table.concat(options, "\n"))
        end
        if #imports > 0 then
            conanfile:print("[imports]")
            conanfile:print("%s", table.concat(imports, "\n"))
        end
        if #build_requires > 0 then
            conanfile:print("[build_requires]")
            conanfile:print("%s", table.concat(build_requires, "\n"))
        end
        conanfile:close()
    end
end

-- install xmake generator
function _conan_install_xmake_generator(conan)
    local xmake_generator_localdir = path.join(config.directory(), "conan", "xmake_generator")
    if not os.isdir(xmake_generator_localdir) then

        -- sort main urls
        local mainurls = {"https://github.com/xmake-io/conan-xmake_generator.git",
                          "https://gitlab.com/xmake-io/conan-xmake_generator.git",
                          "https://gitee.com/xmake-io/conan-xmake_generator.git"}
        fasturl.add(mainurls)
        mainurls = fasturl.sort(mainurls)

        -- clone xmake generator repository
        local ok = false
        for _, url in ipairs(mainurls) do
            ok = try { function () git.clone(url, {depth = 1, branch = "0.1.0/testing", outputdir = xmake_generator_localdir}); return true end }
            if ok then
                break
            end
        end
        if ok then
            os.vrunv(conan.program, {"export", xmake_generator_localdir, "bincrafters/testing"})
        end
    end
end

-- install package
--
-- @param name  the package name, e.g. conan::OpenSSL/1.0.2n@conan/stable
-- @param opt   the options, e.g. { verbose = true, mode = "release", plat = , arch = ,
--                                  configs = {
--                                      remote = "", build = "all", options = {}, imports = {}, build_requires = {},
--                                      settings = {"compiler=Visual Studio", "compiler.version=10", "compiler.runtime=MD"}}}
--
-- @return      true or false
--
function main(name, opt)

    -- get configs
    opt = opt or {}
    local configs = opt.configs or {}

    -- find conan
    local conan = find_tool("conan")
    if not conan then
        raise("conan not found!")
    end

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

    -- install package
    local argv = {"install", "."}
    if configs.build then
        if configs.build == "all" then
            table.insert(argv, "--build")
        else
            table.insert(argv, "--build=" .. configs.build)
        end
    end

    -- set platform
    local plats = {macosx = "Macos", windows = "Windows", mingw = "Windows", linux = "Linux", cross = "Linux", iphoneos = "iOS", android = "Android"}
    table.insert(argv, "-s")
    local plat = plats[opt.plat]
    if plat then
        table.insert(argv, "os=" .. plat)
    else
        raise("cannot install package(%s) on platform(%s)!", name, opt.plat)
    end

    -- set architecture
    local archs = {x86_64          = "x86_64",
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
    table.insert(argv, "-s")
    local arch = archs[opt.arch]
    if arch then
        table.insert(argv, "arch=" .. arch)
    else
        raise("cannot install package(%s) for arch(%s)!", name, opt.arch)
    end

    -- set build mode
    table.insert(argv, "-s")
    if opt.mode == "debug" then
        table.insert(argv, "build_type=Debug")
    else
        table.insert(argv, "build_type=Release")
    end

    -- set compiler settings
    if opt.plat == "windows" then
        local vsvers = {["2022"] = "17",
                        ["2019"] = "16",
                        ["2017"] = "15",
                        ["2015"] = "14",
                        ["2013"] = "12",
                        ["2012"] = "11",
                        ["2010"] = "10",
                        ["2008"] = "9",
                        ["2005"] = "8"}
        local vs = assert(config.get("vs"), "vs not found!")
        table.insert(argv, "-s")
        table.insert(argv, "compiler=Visual Studio")
        table.insert(argv, "-s")
        table.insert(argv, "compiler.version=" .. assert(vsvers[vs], "unknown msvc version!"))
        if configs.vs_runtime then
            table.insert(argv, "-s")
            table.insert(argv, "compiler.runtime=" .. configs.vs_runtime)
        end
    elseif opt.plat == "iphoneos" then
        local target_minver = nil
        local toolchain_xcode = toolchain.load("xcode", {plat = opt.plat, arch = opt.arch})
        if toolchain_xcode then
            target_minver = toolchain_xcode:config("target_minver")
        end
        if target_minver and tonumber(target_minver) > 10 and (arch == "armv7" or arch == "armv7s" or arch == "x86") then
            target_minver = "10" -- iOS 10 is the maximum deployment target for 32-bit targets
        end
        if target_minver then
            table.insert(argv, "-s")
            table.insert(argv, "os.version=" .. target_minver)
        end
    elseif opt.plat == "android" then
        local ndk_sdkver = config.get("ndk_sdkver")
        if ndk_sdkver then
            table.insert(argv, "-s")
            table.insert(argv, "os.api_level=" .. ndk_sdkver)
        end
    end

    -- set custom settings
    for _, setting in ipairs(configs.settings) do
        table.insert(argv, "-s")
        table.insert(argv, setting)
    end

    -- set remote
    if configs.remote then
        table.insert(argv, "-r")
        table.insert(argv, configs.remote)
    end

    -- TODO set environments
    if opt.plat == "android" then
        local envs = {}
        local cflags   = table.join(table.wrap(_conan_get_build_env("cxflags", opt.plat)), _conan_get_build_env("cflags", opt.plat))
        local cxxflags = table.join(table.wrap(_conan_get_build_env("cxflags", opt.plat)), _conan_get_build_env("cxxflags", opt.plat))
        envs.CC        = _conan_get_build_env("cc", opt.plat)
        envs.CXX       = _conan_get_build_env("cxx", opt.plat)
        envs.AS        = _conan_get_build_env("as", opt.plat)
        envs.AR        = _conan_get_build_env("ar", opt.plat)
        envs.LD        = _conan_get_build_env("ld", opt.plat)
        envs.LDSHARED  = _conan_get_build_env("sh", opt.plat)
        envs.CPP       = _conan_get_build_env("cpp", opt.plat)
        envs.RANLIB    = _conan_get_build_env("ranlib", opt.plat)
        envs.CFLAGS    = table.concat(cflags, ' ')
        envs.CXXFLAGS  = table.concat(cxxflags, ' ')
        envs.ASFLAGS   = table.concat(table.wrap(_conan_get_build_env("asflags", opt.plat)), ' ')
        envs.ARFLAGS   = table.concat(table.wrap(_conan_get_build_env("arflags", opt.plat)), ' ')
        envs.LDFLAGS   = table.concat(table.wrap(_conan_get_build_env("ldflags", opt.plat)), ' ')
        envs.SHFLAGS   = table.concat(table.wrap(_conan_get_build_env("shflags", opt.plat)), ' ')
        local toolchain_ndk = toolchain.load("ndk", {plat = opt.plat, arch = opt.arch})
        local ndk_sysroot = toolchain_ndk:config("ndk_sysroot")
        if ndk_sysroot then
            table.insert(argv, "-e")
            table.insert(argv, "CONAN_CMAKE_FIND_ROOT_PATH=" .. ndk_sysroot)
        end
        for k, v in pairs(envs) do
            table.insert(argv, "-e")
            table.insert(argv, k .. "=" .. v)
        end
    end

    -- do install
    os.vrunv(conan.program, argv)

    -- leave build directory
    os.cd(oldir)
end
