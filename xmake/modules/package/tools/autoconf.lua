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
-- @file        autoconf.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.tool.toolchain")
import("core.cache.memcache")
import("lib.detect.find_tool")
import("private.utils.toolchain", {alias = "toolchain_utils"})

-- translate paths
function _translate_paths(paths)
    if paths and is_host("windows") then
        if type(paths) == "string" then
            return path.unix(paths)
        elseif type(paths) == "table" then
            local result = {}
            for _, p in ipairs(paths) do
                table.insert(result, path.unix(p))
            end
            return result
        end
    end
    return paths
end

-- translate cygwin paths
function _translate_cygwin_paths(paths)
    if type(paths) == "string" then
        return path.cygwin(paths)
    elseif type(paths) == "table" then
        local result = {}
        for _, p in ipairs(paths) do
            table.insert(result, path.cygwin(p))
        end
        return result
    end
    return paths
end

-- translate windows bin path
function _translate_windows_bin_path(bin_path)
    if bin_path then
        local argv = os.argv(bin_path)
        argv[1] = path.unix(argv[1])
        local path_lower = argv[1]:lower()
        if not path_lower:endswith(".exe") and not path_lower:endswith(".cmd") and not path_lower:endswith(".bat") then
            argv[1] = argv[1] .. ".exe"
        end
        return os.args(argv)
    end
end

-- get msvc
function _get_msvc(package)
    local msvc = package:toolchain("msvc")
    assert(msvc:check(), "vs not found!") -- we need to check vs envs if it has been not checked yet
    return msvc
end

-- get msvc run environments
function _get_msvc_runenvs(package)
    return os.joinenvs(_get_msvc(package):runenvs())
end

-- get memcache
function _memcache()
    return memcache.cache("package.tools.autoconf")
end

-- has `--with-pic`?
function _has_with_pic(package)
    local has_with_pic = _memcache():get2(tostring(package), "with_pic")
    if has_with_pic == nil then
        local result = try {function() return os.iorunv("./configure", {"--help"}, {shell = true}) end}
        if result and result:find("--with-pic", 1, true) then
            has_with_pic = true
        end
        has_with_pic = has_with_pic or false
        _memcache():set2(tostring(package), "with_pic", has_with_pic)
    end
    return has_with_pic
end

-- get configs
function _get_configs(package, configs)
    local configs = configs or {}
    table.insert(configs, "--prefix=" .. _translate_paths(package:installdir()))

    if not configs.host then
        if package:is_plat("iphoneos", "macosx") and package:is_cross() then
            local triples =
            {
                arm64  = "aarch64-apple-darwin",
                arm64e = "aarch64-apple-darwin",
                armv7  = "armv7-apple-darwin",
                armv7s = "armv7s-apple-darwin",
                i386   = "i386-apple-darwin",
                x86_64 = "x86_64-apple-darwin"
            }
            table.insert(configs, "--host=" .. (triples[package:arch()] or triples.arm64))
        elseif package:is_plat("android") then
            -- @see https://developer.android.com/ndk/guides/other_build_systems#autoconf
            local triples =
            {
                ["armv5te"]     = "arm-linux-androideabi",  -- deprecated
                ["armv7-a"]     = "arm-linux-androideabi",  -- deprecated
                ["armeabi"]     = "arm-linux-androideabi",  -- removed in ndk r17
                ["armeabi-v7a"] = "arm-linux-androideabi",
                ["arm64-v8a"]   = "aarch64-linux-android",
                i386            = "i686-linux-android",     -- deprecated
                x86             = "i686-linux-android",
                x86_64          = "x86_64-linux-android",
                mips            = "mips-linux-android",     -- removed in ndk r17
                mips64          = "mips64-linux-android"    -- removed in ndk r17
            }
            table.insert(configs, "--host=" .. (triples[package:arch()] or triples["armeabi-v7a"]))
        elseif package:is_plat("mingw") then -- we always add host for mingw
            local triples =
            {
                i386   = "i686-w64-mingw32",
                x86_64 = "x86_64-w64-mingw32"
            }
            table.insert(configs, "--host=" .. (triples[package:arch()] or triples.i386))
        elseif package:is_plat("linux") and package:is_cross() then
            local triples =
            {
                ["arm64-v8a"] = "aarch64-linux-gnu",
                arm64 = "aarch64-linux-gnu",
                i386   = "i686-linux-gnu",
                x86_64 = "x86_64-linux-gnu",
                armv7 = "arm-linux-gnueabihf",
                mips = "mips-linux-gnu",
                mips64 = "mips64-linux-gnu",
                mipsel = "mipsel-linux-gnu",
                mips64el = "mips64el-linux-gnu",
                loong64 = "loongarch64-linux-gnu"
            }
            table.insert(configs, "--host=" .. (triples[package:arch()] or triples.i386))
        elseif package:is_plat("cross") and package:targetos() then
            local host = package:arch()
            if package:is_arch("arm64") then
                host = "aarch64"
            elseif package:is_arch("arm.*") then
                host = "arm"
            end
            host = host .. "-" .. package:targetos()
            table.insert(configs, "--host=" .. host)
        end
    end
    if not package:is_plat("windows", "mingw") and
        package:config("pic") ~= false and _has_with_pic(package) then
        table.insert(configs, "--with-pic")
    end
    return configs
end

-- get cflags from package deps
function _get_cflags_from_packagedeps(package, opt)
    local values
    for _, depname in ipairs(opt.packagedeps) do
        local dep = type(depname) ~= "string" and depname or package:librarydep(depname)
        if dep then
            local fetchinfo = dep:fetch()
            if fetchinfo then
                if values then
                    values = values .. fetchinfo
                else
                    values = fetchinfo
                end
            end
        end
    end
    -- @see https://github.com/xmake-io/xmake-repo/pull/4973#issuecomment-2295890196
    local result = {}
    if values then
        if values.defines then
            table.join2(result, toolchain_utils.map_compflags_for_package(package, "cxx", "define", values.defines))
        end
        if values.includedirs then
            table.join2(result, _translate_paths(toolchain_utils.map_compflags_for_package(package, "cxx", "includedir", values.includedirs)))
        end
        if values.sysincludedirs then
            table.join2(result, _translate_paths(toolchain_utils.map_compflags_for_package(package, "cxx", "sysincludedir", values.sysincludedirs)))
        end
    end
    return result
end

-- get ldflags from package deps
function _get_ldflags_from_packagedeps(package, opt)
    local values
    for _, depname in ipairs(opt.packagedeps) do
        local dep = type(depname) ~= "string" and depname or package:librarydep(depname)
        if dep then
            local fetchinfo = dep:fetch()
            if fetchinfo then
                if values then
                    values = values .. fetchinfo
                else
                    values = fetchinfo
                end
            end
        end
    end
    local result = {}
    if values then
        if values.linkdirs then
            table.join2(result, _translate_paths(toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "linkdir", values.linkdirs)))
        end
        if values.links then
            table.join2(result, toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "link", values.links))
        end
        if values.syslinks then
            table.join2(result, _translate_paths(toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "syslink", values.syslinks)))
        end
        if values.frameworks then
            table.join2(result, toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "framework", values.frameworks))
        end
    end
    return result
end

-- get the build environments
function buildenvs(package, opt)
    opt = opt or {}
    local envs = {}
    local cross = false
    local cflags, cxxflags, cppflags, asflags, ldflags, shflags, arflags
    if not package:is_cross() and not package:config("toolchains") then
        cppflags = {}
        cflags   = table.join(table.wrap(package:config("cxflags")), package:config("cflags"))
        cxxflags = table.join(table.wrap(package:config("cxflags")), package:config("cxxflags"))
        asflags  = table.copy(table.wrap(package:config("asflags")))
        ldflags  = table.copy(table.wrap(package:config("ldflags")))
        shflags  = table.copy(table.wrap(package:config("shflags")))
        if package:is_plat("linux") and package:is_arch("i386") then
            table.insert(cflags,   "-m32")
            table.insert(cxxflags, "-m32")
            table.insert(asflags,  "-m32")
            table.insert(ldflags,  "-m32")
            table.insert(shflags,  "-m32")
        end
        table.join2(cflags,   opt.cflags)
        table.join2(cflags,   opt.cxflags)
        table.join2(cxxflags, opt.cxxflags)
        table.join2(cxxflags, opt.cxflags)
        table.join2(cppflags, opt.cppflags) -- @see https://github.com/xmake-io/xmake/issues/1688
        table.join2(asflags,  opt.asflags)
        table.join2(ldflags,  opt.ldflags)
        table.join2(shflags,  opt.shflags)
        table.join2(cflags,   _get_cflags_from_packagedeps(package, opt))
        table.join2(cxxflags, _get_cflags_from_packagedeps(package, opt))
        table.join2(cppflags, _get_cflags_from_packagedeps(package, opt))
        table.join2(ldflags,  _get_ldflags_from_packagedeps(package, opt))
        table.join2(shflags,  _get_ldflags_from_packagedeps(package, opt))
    else
        cross = true
        cppflags = {}
        cflags   = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cflags"))
        cxxflags = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cxxflags"))
        asflags  = table.copy(table.wrap(package:build_getenv("asflags")))
        ldflags  = table.copy(table.wrap(package:build_getenv("ldflags")))
        shflags  = table.copy(table.wrap(package:build_getenv("shflags")))
        arflags  = table.copy(table.wrap(package:build_getenv("arflags")))
        local defines        = package:build_getenv("defines")
        local includedirs    = package:build_getenv("includedirs")
        local sysincludedirs = package:build_getenv("sysincludedirs")
        local links          = package:build_getenv("links")
        local syslinks       = package:build_getenv("syslinks")
        local linkdirs       = package:build_getenv("linkdirs")
        table.join2(cflags,   opt.cflags)
        table.join2(cflags,   opt.cxflags)
        table.join2(cxxflags, opt.cxxflags)
        table.join2(cxxflags, opt.cxflags)
        table.join2(cppflags, opt.cppflags) -- @see https://github.com/xmake-io/xmake/issues/1688
        table.join2(asflags,  opt.asflags)
        table.join2(ldflags,  opt.ldflags)
        table.join2(shflags,  opt.shflags)
        table.join2(arflags,  opt.arflags)
        table.join2(cflags,   _get_cflags_from_packagedeps(package, opt))
        table.join2(cxxflags, _get_cflags_from_packagedeps(package, opt))
        table.join2(cppflags, _get_cflags_from_packagedeps(package, opt))
        table.join2(ldflags,  _get_ldflags_from_packagedeps(package, opt))
        table.join2(cflags,   toolchain_utils.map_compflags_for_package(package, "c", "define", defines))
        table.join2(cflags,   toolchain_utils.map_compflags_for_package(package, "c", "includedir", includedirs))
        table.join2(cflags,   toolchain_utils.map_compflags_for_package(package, "c", "sysincludedir", sysincludedirs))
        table.join2(asflags,  toolchain_utils.map_compflags_for_package(package, "as", "define", defines))
        table.join2(asflags,  toolchain_utils.map_compflags_for_package(package, "as", "includedir", includedirs))
        table.join2(asflags,  toolchain_utils.map_compflags_for_package(package, "as", "sysincludedir", sysincludedirs))
        table.join2(cxxflags, toolchain_utils.map_compflags_for_package(package, "cxx", "define", defines))
        table.join2(cxxflags, toolchain_utils.map_compflags_for_package(package, "cxx", "includedir", includedirs))
        table.join2(cxxflags, toolchain_utils.map_compflags_for_package(package, "cxx", "sysincludedir", sysincludedirs))
        table.join2(ldflags,  toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "link", links))
        table.join2(ldflags,  toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "syslink", syslinks))
        table.join2(ldflags,  toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "linkdir", linkdirs))
        table.join2(shflags,  toolchain_utils.map_linkflags_for_package(package, "shared", {"cxx"}, "link", links))
        table.join2(shflags,  toolchain_utils.map_linkflags_for_package(package, "shared", {"cxx"}, "syslink", syslinks))
        table.join2(shflags,  toolchain_utils.map_linkflags_for_package(package, "shared", {"cxx"}, "linkdir", linkdirs))
        envs.CC        = package:build_getenv("cc")
        envs.AS        = package:build_getenv("as")
        envs.AR        = package:build_getenv("ar")
        envs.LD        = package:build_getenv("ld")
        envs.LDSHARED  = package:build_getenv("sh")
        envs.CPP       = package:build_getenv("cpp")
        envs.RANLIB    = package:build_getenv("ranlib")
    end
    if not package:is_plat("windows", "mingw") and
        package:config("pic") ~= false and not _has_with_pic(package) then
        table.insert(cflags, "-fPIC")
        table.insert(cxxflags, "-fPIC")
    end
    if package:config("lto") then
        table.join2(cflags, package:_generate_lto_configs("cc").cflags)
        table.join2(cxxflags, package:_generate_lto_configs("cxx").cxxflags)
        table.join2(ldflags, package:_generate_lto_configs().ldflags)
    end
    local runtimes = package:runtimes()
    if runtimes then
        table.join2(cxxflags, toolchain_utils.map_compflags_for_package(package, "cxx", "runtime", runtimes))
        table.join2(ldflags, toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "runtime", runtimes))
        table.join2(shflags, toolchain_utils.map_linkflags_for_package(package, "shared", {"cxx"}, "runtime", runtimes))
    end
    if package:config("asan") then
        table.join2(cflags, package:_generate_sanitizer_configs("address", "cc").cflags)
        table.join2(cxxflags, package:_generate_sanitizer_configs("address", "cxx").cxxflags)
        table.join2(ldflags, package:_generate_sanitizer_configs("address").ldflags)
        table.join2(shflags, package:_generate_sanitizer_configs("address").shflags)
    end
    if cflags then
        envs.CFLAGS    = table.concat(_translate_paths(cflags), ' ')
    end
    if cxxflags then
        envs.CXXFLAGS  = table.concat(_translate_paths(cxxflags), ' ')
    end
    if cppflags then
        envs.CPPFLAGS  = table.concat(_translate_paths(cppflags), ' ')
    end
    if asflags then
        envs.ASFLAGS   = table.concat(_translate_paths(asflags), ' ')
    end
    if arflags then
        envs.ARFLAGS   = table.concat(_translate_paths(arflags), ' ')
    end
    if ldflags or shflags then
        -- autoconf does not use SHFLAGS
        envs.LDFLAGS   = table.concat(_translate_paths(table.join(ldflags or {}, shflags)), ' ')
    end

    -- cross-compilation? pass the full build environments
    if cross then
        if package:is_plat("mingw") then
            -- fix linker error, @see https://github.com/xmake-io/xmake/issues/574
            -- libtool: line 1855: lib: command not found
            envs.ARFLAGS = nil
            local ld = envs.LD
            if ld then
                if ld:endswith("x86_64-w64-mingw32-g++") then
                    envs.LD = path.join(path.directory(ld), is_host("windows") and "ld" or "x86_64-w64-mingw32-ld")
                elseif ld:endswith("i686-w64-mingw32-g++") then
                    envs.LD = path.join(path.directory(ld), is_host("windows") and "ld" or "i686-w64-mingw32-ld")
                end
            end
        else
            if package:is_plat("macosx") then
                -- force to apply shflags on macosx https://gmplib.org/manual/Known-Build-Problems
                envs.CC = envs.CC .. " -arch " .. package:arch()
            end
            -- android r27 will use llmv-ar instead of ar, https://github.com/xmake-io/xmake/issues/6206
            if package:is_plat("cross") or package:has_tool("ar", "ar", "emar", "llvm_ar") then
                -- only for cross-toolchain
                envs.CXX = package:build_getenv("cxx")
                if not envs.ARFLAGS or envs.ARFLAGS == "" then
                    envs.ARFLAGS = "-cr"
                end
            end
        end

        -- we should use ld as linker
        --
        -- @see
        -- https://github.com/xmake-io/xmake-repo/pull/1043
        -- https://github.com/libexpat/libexpat/issues/312
        -- https://github.com/xmake-io/xmake/issues/2195
        local ld = envs.LD
        if ld and package:has_tool("ld", "clang", "clangxx", "gcc", "gxx") then
            local dir = path.directory(ld)
            local name = path.filename(ld)
            name = name:gsub("clang%+%+$", "ld")
            name = name:gsub("clang%+%+%-%d+", "ld")
            name = name:gsub("clang$", "ld")
            name = name:gsub("clang%-%d+", "ld")
            name = name:gsub("gcc$", "ld")
            name = name:gsub("gcc-%d+", "ld")
            name = name:gsub("g%+%+$", "ld")
            name = name:gsub("g%+%+%-%d+", "ld")
            envs.LD = dir and path.join(dir, name) or name
        end
        -- we need use clang++ as cxx, autoconf will use it as linker
        -- https://github.com/xmake-io/xmake/issues/2170
        local cxx = envs.CXX
        if cxx and package:has_tool("cxx", "clang", "gcc") then
            local dir = path.directory(cxx)
            local name = path.filename(cxx)
            name = name:gsub("clang$", "clang++")
            name = name:gsub("clang%-", "clang++-")
            name = name:gsub("gcc$", "g++")
            name = name:gsub("gcc%-", "g++-")
            envs.CXX = dir and path.join(dir, name) or name
        end
    end
    if package:is_plat("windows") and not package:config("toolchains") then
        envs.PATH = os.getenv("PATH") -- we need to reserve PATH on msys2
        envs = os.joinenvs(envs, _get_msvc(package):runenvs())
    end

    if is_host("windows") then
        envs.CC       = _translate_windows_bin_path(envs.CC)
        envs.AS       = _translate_windows_bin_path(envs.AS)
        envs.AR       = _translate_windows_bin_path(envs.AR)
        envs.LD       = _translate_windows_bin_path(envs.LD)
        envs.LDSHARED = _translate_windows_bin_path(envs.LDSHARED)
        envs.CPP      = _translate_windows_bin_path(envs.CPP)
        envs.RANLIB   = _translate_windows_bin_path(envs.RANLIB)
    end
    local ACLOCAL_PATH = {}
    local PKG_CONFIG_PATH = {}
    for _, dep in ipairs(package:librarydeps({private = true})) do
        local pkgconfig = path.join(dep:installdir(), "lib", "pkgconfig")
        if os.isdir(pkgconfig) then
            table.insert(PKG_CONFIG_PATH, pkgconfig)
        end
        pkgconfig = path.join(dep:installdir(), "share", "pkgconfig")
        if os.isdir(pkgconfig) then
            table.insert(PKG_CONFIG_PATH, pkgconfig)
        end
    end
    -- some binary packages contain it too. e.g. libtool
    for _, dep in ipairs(package:orderdeps()) do
        local aclocal = path.join(dep:installdir(), "share", "aclocal")
        if os.isdir(aclocal) then
            table.insert(ACLOCAL_PATH, aclocal)
        end
    end
    envs.ACLOCAL_PATH = path.joinenv(ACLOCAL_PATH)
    -- fix PKG_CONFIG_PATH for windows/msys2
    -- @see https://github.com/xmake-io/xmake-repo/issues/3442
    if package:is_plat("windows") then
        -- pkg-config can only support for unix path and env seperator on msys/cygwin
        PKG_CONFIG_PATH = _translate_cygwin_paths(PKG_CONFIG_PATH)
        envs.PKG_CONFIG_PATH = path.joinenv(PKG_CONFIG_PATH, ":")
    else
        envs.PKG_CONFIG_PATH = path.joinenv(PKG_CONFIG_PATH)
    end
    return envs
end

-- get the autogen environments
function autogen_envs(package, opt)
    opt = opt or {}
    local envs = {NOCONFIGURE = "yes"}
    local ACLOCAL_PATH = {}
    local PKG_CONFIG_PATH = {}
    for _, dep in ipairs(package:librarydeps({private = true})) do
        local pkgconfig = path.join(dep:installdir(), "lib", "pkgconfig")
        if os.isdir(pkgconfig) then
            table.insert(PKG_CONFIG_PATH, pkgconfig)
        end
        pkgconfig = path.join(dep:installdir(), "share", "pkgconfig")
        if os.isdir(pkgconfig) then
            table.insert(PKG_CONFIG_PATH, pkgconfig)
        end
    end
    -- some binary packages contain it too. e.g. libtool
    for _, dep in ipairs(package:orderdeps()) do
        local aclocal = path.join(dep:installdir(), "share", "aclocal")
        if os.isdir(aclocal) then
            table.insert(ACLOCAL_PATH, aclocal)
        end
    end
    envs.ACLOCAL_PATH    = path.joinenv(ACLOCAL_PATH)
    envs.PKG_CONFIG_PATH = path.joinenv(PKG_CONFIG_PATH)
    return envs
end

-- configure package
function configure(package, configs, opt)

    -- init options
    opt = opt or {}

    -- generate configure file
    if not os.isfile("configure") then
        if os.isfile("autogen.sh") then
            os.vrunv("./autogen.sh", {}, {shell = true, envs = autogen_envs(package, opt)})
        elseif os.isfile("configure.ac") or os.isfile("configure.in") then
            local autoreconf = find_tool("autoreconf")
            assert(autoreconf, "autoreconf not found!")
            os.vrunv(autoreconf.program, {"--install", "--symlink"}, {shell = true, envs = autogen_envs(package, opt)})
        end
    end

    -- get envs
    local envs = opt.envs or buildenvs(package, opt)

    -- pass configurations
    local argv = {}
    for name, value in pairs(_get_configs(package, configs)) do
        value = tostring(value):trim()
        if value ~= "" then
            if type(name) == "number" then
                table.insert(argv, value)
            else
                table.insert(argv, "--" .. name .. "=" .. value)
            end
        end
    end

    -- do configure
    os.vrunv("./configure", argv, {shell = true, envs = envs})
end

-- do make
function make(package, argv, opt)
    opt = opt or {}
    local program
    if package:is_plat("mingw") and is_subhost("windows") then
        local mingw = assert(package:build_getenv("mingw") or package:build_getenv("sdk"), "mingw not found!")
        program = path.join(mingw, "bin", "mingw32-make.exe")
    else
        local tool = find_tool("make")
        if tool then
            program = tool.program
        end
    end
    assert(program, "make not found!")

    if package:is_plat("windows") then
        local envs = opt.envs or buildenvs(package, opt)
        os.vrunv(program, argv, {envs = envs})
    else
        os.vrunv(program, argv)
    end
end

-- build package
function build(package, configs, opt)

    -- do configure
    configure(package, configs, opt)

    -- do make and install
    opt = opt or {}
    local njob = opt.jobs or option.get("jobs") or tostring(os.default_njob())
    local argv = {"-j" .. njob}
    if option.get("diagnosis") then
        table.insert(argv, "V=1")
    end
    if opt.makeconfigs then
        for name, value in pairs(opt.makeconfigs) do
            value = tostring(value):trim()
            if value ~= "" then
                if type(name) == "number" then
                    table.insert(argv, value)
                else
                    table.insert(argv, name .. "=" .. value)
                end
            end
        end
    end
    make(package, argv, opt)
end

-- install package
function install(package, configs, opt)

    -- do build
    opt = opt or {}
    build(package, configs, opt)

    -- do install
    local argv = {"install"}
    if option.get("diagnosis") then
        table.insert(argv, "V=1")
    end
    if opt.makeconfigs then
        for name, value in pairs(opt.makeconfigs) do
            value = tostring(value):trim()
            if value ~= "" then
                if type(name) == "number" then
                    table.insert(argv, value)
                else
                    table.insert(argv, name .. "=" .. value)
                end
            end
        end
    end
    make(package, argv, opt)
end
