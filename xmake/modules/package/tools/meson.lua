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
-- @file        meson.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.tool.toolchain")
import("lib.detect.find_tool")
import("private.utils.executable_path")
import("private.utils.toolchain", {alias = "toolchain_utils"})

-- get build directory
function _get_buildir(package, opt)
    if opt and opt.buildir then
        return opt.buildir
    else
        _g.buildir = _g.buildir or package:buildir()
        return _g.buildir
    end
end

-- get pkg-config, we need force to find it, because package install environments will be changed
function _get_pkgconfig(package)
    -- meson need fullpath pkgconfig
    -- @see https://github.com/xmake-io/xmake/issues/5474
    local dep = package:dep("pkgconf") or package:dep("pkg-config")
    if dep then
        local suffix = dep:is_plat("windows", "mingw") and ".exe" or ""
        local pkgconf = path.join(dep:installdir("bin"), "pkgconf" .. suffix)
        if os.isfile(pkgconf) then
            return pkgconf
        end
        local pkgconfig = path.join(dep:installdir("bin"), "pkg-config" .. suffix)
        if os.isfile(pkgconfig) then
            return pkgconfig
        end
    end
    if package:is_plat("windows") then
        local pkgconf = find_tool("pkgconf", {force = true})
        if pkgconf then
            return pkgconf.program
        end
    end
    local pkgconfig = find_tool("pkg-config", {force = true})
    if pkgconfig then
        return pkgconfig.program
    end
end

-- translate flags
function _translate_flags(package, flags)
    if package:is_plat("android") then
        local flags_new = {}
        for _, flag in ipairs(flags) do
            if flag:startswith("--gcc-toolchain=") or flag:startswith("--target=") or flag:startswith("-isystem ") then
                table.join2(flags_new, flag:split(" ", {limit = 2}))
            else
                table.insert(flags_new, flag)
            end
        end
        flags = flags_new
    elseif package:is_plat("windows") then
        for idx, flag in ipairs(flags) do
            -- @see https://github.com/xmake-io/xmake/issues/4407
            if flag:startswith("-libpath:") then
                flags[idx] = flag:gsub("%-libpath:", "/libpath:")
            end
        end
    end
    return flags
end

function _insert_cross_configs(package, file, opt)
    -- host machine
    file:print("[host_machine]")
    if opt.host_machine then
        file:print("%s", opt.host_machine)
    elseif package:is_plat("iphoneos", "macosx") then
        local cpu
        local cpu_family
        if package:is_arch("arm64") then
            cpu = "aarch64"
            cpu_family = "aarch64"
        elseif package:is_arch("armv7") then
            cpu = "arm"
            cpu_family = "arm"
        elseif package:is_arch("x64", "x86_64") then
            cpu = "x86_64"
            cpu_family = "x86_64"
        elseif package:is_arch("x86", "i386") then
            cpu = "i686"
            cpu_family = "x86"
        else
            raise("unsupported arch(%s)", package:arch())
        end
        file:print("system = 'darwin'")
        file:print("cpu_family = '%s'", cpu_family)
        file:print("cpu = '%s'", cpu)
        file:print("endian = 'little'")
    elseif package:is_plat("android") then
        local cpu
        local cpu_family
        if package:is_arch("arm64-v8a") then
            cpu = "aarch64"
            cpu_family = "aarch64"
        elseif package:is_arch("armeabi-v7a") then
            cpu = "arm"
            cpu_family = "arm"
        elseif package:is_arch("x64", "x86_64") then
            cpu = "x86_64"
            cpu_family = "x86_64"
        elseif package:is_arch("x86", "i386") then
            cpu = "i686"
            cpu_family = "x86"
        else
            raise("unsupported arch(%s)", package:arch())
        end
        file:print("system = 'android'")
        file:print("cpu_family = '%s'", cpu_family)
        file:print("cpu = '%s'", cpu)
        file:print("endian = 'little'")
    elseif package:is_plat("mingw") then
        local cpu
        local cpu_family
        if package:is_arch("x64", "x86_64") then
            cpu = "x86_64"
            cpu_family = "x86_64"
        elseif package:is_arch("x86", "i386") then
            cpu = "i686"
            cpu_family = "x86"
        else
            raise("unsupported arch(%s)", package:arch())
        end
        file:print("system = 'windows'")
        file:print("cpu_family = '%s'", cpu_family)
        file:print("cpu = '%s'", cpu)
        file:print("endian = 'little'")
    elseif package:is_plat("windows") then
        local cpu
        local cpu_family
        if package:is_arch("arm64", "arm64ec") then
            cpu = "aarch64"
            cpu_family = "aarch64"
        elseif package:is_arch("x86") then
            cpu = "x86"
            cpu_family = "x86"
        elseif package:is_arch("x64") then
            cpu = "x86_64"
            cpu_family = "x86_64"
        else
            raise("unsupported arch(%s)", package:arch())
        end
        file:print("system = 'windows'")
        file:print("cpu_family = '%s'", cpu_family)
        file:print("cpu = '%s'", cpu)
        file:print("endian = 'little'")
    elseif package:is_plat("wasm") then
        file:print("system = 'emscripten'")
        file:print("cpu_family = '%s'", package:arch())
        file:print("cpu = '%s'", package:arch())
        file:print("endian = 'little'")
    else
        local cpu = package:arch()
        if package:is_arch("arm64") or package:is_arch("aarch64") then
            cpu = "aarch64"
        elseif package:is_arch("arm.*") then
            cpu = "arm"
        end
        local cpu_family = cpu
        file:print("system = '%s'", package:targetos() or "linux")
        file:print("cpu_family = '%s'", cpu_family)
        file:print("cpu = '%s'", cpu)
        file:print("endian = 'little'")
    end
end

-- is the toolchain compatible with the host?
function _is_toolchain_compatible_with_host(package)
    for _, name in ipairs(package:config("toolchains")) do
        if toolchain_utils.is_compatible_with_host(name) then
            return true
        end
    end
end

-- get cross file
function _get_configs_file(package, opt)
    opt = opt or {}
    local configsfile = path.join(_get_buildir(package, opt), "configs_file.txt")
    if not os.isfile(configsfile) then
        local file = io.open(configsfile, "w")
        -- binaries
        file:print("[binaries]")
        local cc = package:build_getenv("cc")
        if cc then
            file:print("c=['%s']", executable_path(cc))
        end

        local cxx = package:build_getenv("cxx")
        if cxx then
            -- https://github.com/xmake-io/xmake/discussions/4979
            if package:has_tool("cxx", "clang", "gcc") then
                local dir = path.directory(cxx)
                local name = path.filename(cxx)
                name = name:gsub("clang$", "clang++")
                name = name:gsub("clang%-", "clang++-") -- clang-xx
                name = name:gsub("clang%.", "clang++.") -- clang.exe
                name = name:gsub("gcc$", "g++")
                name = name:gsub("gcc%-", "g++-")
                name = name:gsub("gcc%.", "g++.")
                if dir and dir ~= "." then
                    cxx = path.join(dir, name)
                else
                    cxx = name
                end
            end
            file:print("cpp=['%s']", executable_path(cxx))
        end

        local ld = package:build_getenv("ld")
        if ld then
            file:print("ld=['%s']", executable_path(ld))
        end
        -- we cannot pass link.exe to ar for msvc, it will raise `unknown linker`
        if not package:is_plat("windows") then
            local ar = package:build_getenv("ar")
            if ar then
                file:print("ar=['%s']", executable_path(ar))
            end
        end
        local strip = package:build_getenv("strip")
        if strip then
            file:print("strip=['%s']", executable_path(strip))
        end
        local ranlib = package:build_getenv("ranlib")
        if ranlib then
            file:print("ranlib=['%s']", executable_path(ranlib))
        end
        if package:is_plat("mingw") then
            local mrc = package:build_getenv("mrc")
            if mrc then
                file:print("windres=['%s']", executable_path(mrc))
            end
        end
        local cmake = find_tool("cmake")
        if cmake then
            file:print("cmake=['%s']", executable_path(cmake.program))
        end
        local pkgconfig = _get_pkgconfig(package)
        if pkgconfig then
            file:print("pkgconfig=['%s']", executable_path(pkgconfig))
        end
        file:print("")

        -- built-in options
        file:print("[built-in options]")
        local cflags   = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cflags"))
        local cxxflags = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cxxflags"))
        local asflags  = table.wrap(package:build_getenv("asflags"))
        local arflags  = table.wrap(package:build_getenv("arflags"))
        local ldflags  = table.wrap(package:build_getenv("ldflags"))
        local shflags  = table.wrap(package:build_getenv("shflags"))
        table.join2(cflags,   opt.cflags)
        table.join2(cflags,   opt.cxflags)
        table.join2(cxxflags, opt.cxxflags)
        table.join2(cxxflags, opt.cxflags)
        table.join2(asflags,  opt.asflags)
        table.join2(ldflags,  opt.ldflags)
        table.join2(shflags,  opt.shflags)
        table.join2(cflags,   _get_cflags_from_packagedeps(package, opt))
        table.join2(cxxflags, _get_cflags_from_packagedeps(package, opt))
        table.join2(ldflags,  _get_ldflags_from_packagedeps(package, opt))
        table.join2(shflags,  _get_ldflags_from_packagedeps(package, opt))
        -- add runtimes flags
        for _, runtime in ipairs(package:runtimes()) do
            if not runtime:startswith("M") then
                table.join2(cxxflags, toolchain_utils.map_compflags_for_package(package, "cxx", "runtime", {runtime}))
                table.join2(ldflags, toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "runtime", {runtime}))
                table.join2(shflags, toolchain_utils.map_linkflags_for_package(package, "shared", {"cxx"}, "runtime", {runtime}))
            end
        end
        if #cflags > 0 then
            file:print("c_args=['%s']", table.concat(cflags, "', '"))
        end
        if #cxxflags > 0 then
            file:print("cpp_args=['%s']", table.concat(cxxflags, "', '"))
        end
        local linkflags = table.join(ldflags or {}, shflags)
        if #linkflags > 0 then
            file:print("c_link_args=['%s']", table.concat(linkflags, "', '"))
            file:print("cpp_link_args=['%s']", table.concat(linkflags, "', '"))
        end

        if package:is_cross() or opt.cross then
            file:print("")
            _insert_cross_configs(package, file, opt)
            file:print("")
        end
        file:close()
    end
    return configsfile
end

-- get configs
function _get_configs(package, configs, opt)

    -- add prefix
    configs = configs or {}
    table.insert(configs, "--prefix=" .. (opt.prefix or package:installdir()))
    table.insert(configs, "--libdir=lib")

    -- set build type
    table.insert(configs, "-Dbuildtype=" .. (package:debug() and "debug" or "release"))

    -- add -fpic
    if package:is_plat("linux") and package:config("pic") ~= false then
        table.insert(configs, "-Db_staticpic=true")
    end

    -- add lto
    if package:config("lto") then
        table.insert(configs, "-Db_lto=true")
    end

    -- add asan
    if package:config("asan") then
        table.insert(configs, "-Db_sanitize=address")
    end

    -- add vs runtimes flags
    if package:is_plat("windows") then
        table.insert(configs, "--vsenv")
        if package:has_runtime("MT") then
            table.insert(configs, "-Db_vscrt=mt")
        elseif package:has_runtime("MTd") then
            table.insert(configs, "-Db_vscrt=mtd")
        elseif package:has_runtime("MD") then
            table.insert(configs, "-Db_vscrt=md")
        elseif package:has_runtime("MDd") then
            table.insert(configs, "-Db_vscrt=mdd")
        end
    end

    -- add cross file
    if package:is_cross() or package:is_plat("mingw") then
        table.insert(configs, "--cross-file=" .. _get_configs_file(package, opt))
    elseif package:config("toolchains") then
        if _is_toolchain_compatible_with_host(package) then
            table.insert(configs, "--native-file=" .. _get_configs_file(package, opt))
        else
            table.insert(configs, "--cross-file=" .. _get_configs_file(package, table.join2(opt, {cross = true})))
        end
    end

    -- add build directory
    table.insert(configs, _get_buildir(package, opt))
    return configs
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

-- fix libname on windows
function _fix_libname_on_windows(package)
    for _, lib in ipairs(os.files(path.join(package:installdir("lib"), "lib*.a"))) do
        os.mv(lib, (lib:gsub("(.+)\\lib(.-)%.a", "%1\\%2.lib")))
    end
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
            table.join2(result, toolchain_utils.map_compflags_for_package(package, "cxx", "includedir", values.includedirs))
        end
        if values.sysincludedirs then
            table.join2(result, toolchain_utils.map_compflags_for_package(package, "cxx", "sysincludedir", values.sysincludedirs))
        end
    end
    return _translate_flags(package, result)
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
            table.join2(result, toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "linkdir", values.linkdirs))
        end
        if values.links then
            table.join2(result, toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "link", values.links))
        end
        if values.syslinks then
            table.join2(result, toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "syslink", values.syslinks))
        end
        if values.frameworks then
            table.join2(result, toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "framework", values.frameworks))
        end
    end
    return _translate_flags(package, result)
end

-- get the build environments
function buildenvs(package, opt)
    local envs = {}
    opt = opt or {}
    if package:is_plat(os.host()) then
        local cflags   = table.join(table.wrap(package:config("cxflags")), package:config("cflags"))
        local cxxflags = table.join(table.wrap(package:config("cxflags")), package:config("cxxflags"))
        local asflags  = table.wrap(package:config("asflags"))
        local ldflags  = table.wrap(package:config("ldflags"))
        local shflags  = table.wrap(package:config("shflags"))
        table.join2(cflags,   opt.cflags)
        table.join2(cflags,   opt.cxflags)
        table.join2(cxxflags, opt.cxxflags)
        table.join2(cxxflags, opt.cxflags)
        table.join2(asflags,  opt.asflags)
        table.join2(ldflags,  opt.ldflags)
        table.join2(shflags,  opt.shflags)
        table.join2(cflags,   _get_cflags_from_packagedeps(package, opt))
        table.join2(cxxflags, _get_cflags_from_packagedeps(package, opt))
        table.join2(ldflags,  _get_ldflags_from_packagedeps(package, opt))
        table.join2(shflags,  _get_ldflags_from_packagedeps(package, opt))
        envs.CFLAGS    = table.concat(cflags, ' ')
        envs.CXXFLAGS  = table.concat(cxxflags, ' ')
        envs.ASFLAGS   = table.concat(asflags, ' ')
        envs.LDFLAGS   = table.concat(ldflags, ' ')
        envs.SHFLAGS   = table.concat(shflags, ' ')
        if package:is_plat("windows") then
            envs = os.joinenvs(envs, _get_msvc_runenvs(package))
            local pkgconf = _get_pkgconfig(package)
            if pkgconf then
                envs.PKG_CONFIG = pkgconf
            end
        end
    end
    local ACLOCAL_PATH = {}
    local PKG_CONFIG_PATH = {}
    local CMAKE_LIBRARY_PATH = {}
    local CMAKE_INCLUDE_PATH = {}
    local CMAKE_PREFIX_PATH  = {}
    for _, dep in ipairs(package:librarydeps({private = true})) do
        local pkgconfig = path.join(dep:installdir(), "lib", "pkgconfig")
        if os.isdir(pkgconfig) then
            table.insert(PKG_CONFIG_PATH, pkgconfig)
        end
        pkgconfig = path.join(dep:installdir(), "share", "pkgconfig")
        if os.isdir(pkgconfig) then
            table.insert(PKG_CONFIG_PATH, pkgconfig)
        end
        -- meson may also use cmake to find dependencies
        if dep:is_system() then
            local fetchinfo = dep:fetch()
            if fetchinfo then
                table.join2(CMAKE_LIBRARY_PATH, fetchinfo.linkdirs)
                table.join2(CMAKE_INCLUDE_PATH, fetchinfo.includedirs)
                table.join2(CMAKE_INCLUDE_PATH, fetchinfo.sysincludedirs)
            end
        else
            table.join2(CMAKE_PREFIX_PATH, dep:installdir())
        end
    end
    -- some binary packages contain it too. e.g. libtool
    for _, dep in ipairs(package:orderdeps()) do
        local aclocal = path.join(dep:installdir(), "share", "aclocal")
        if os.isdir(aclocal) then
            table.insert(ACLOCAL_PATH, aclocal)
        end
    end
    envs.ACLOCAL_PATH       = path.joinenv(ACLOCAL_PATH)
    envs.CMAKE_LIBRARY_PATH = path.joinenv(CMAKE_LIBRARY_PATH)
    envs.CMAKE_INCLUDE_PATH = path.joinenv(CMAKE_INCLUDE_PATH)
    envs.CMAKE_PREFIX_PATH  = path.joinenv(CMAKE_PREFIX_PATH)
    envs.PKG_CONFIG_PATH    = path.joinenv(PKG_CONFIG_PATH)
    return envs
end

-- generate build files for ninja
function generate(package, configs, opt)

    -- init options
    opt = opt or {}

    -- pass configurations
    -- TODO: support more backends https://mesonbuild.com/Commands.html#setup
    local argv = {"setup"}
    for name, value in pairs(_get_configs(package, configs, opt)) do
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
    local meson = assert(find_tool("meson"), "meson not found!")
    os.vrunv(meson.program, argv, {envs = opt.envs or buildenvs(package, opt)})
end

-- build package
function build(package, configs, opt)

    -- generate build files
    opt = opt or {}
    generate(package, configs, opt)

    -- configurate build
    local buildir = _get_buildir(package, opt)
    local njob = opt.jobs or option.get("jobs") or tostring(os.default_njob())
    local argv = {"compile", "-C", buildir}
    if option.get("diagnosis") then
        table.insert(argv, "-v")
    end
    table.insert(argv, "-j")
    table.insert(argv, njob)

    -- do build
    local meson = assert(find_tool("meson"), "meson not found!")
    os.vrunv(meson.program, argv, {envs = opt.envs or buildenvs(package, opt)})
end

-- install package
function install(package, configs, opt)

    -- do build
    opt = opt or {}
    build(package, configs, opt)

    -- configure install
    local buildir = _get_buildir(package, opt)
    local argv = {"install", "-C", buildir}

    -- do install
    local meson = assert(find_tool("meson"), "meson not found!")
    os.vrunv(meson.program, argv, {envs = opt.envs or buildenvs(package, opt)})

    -- fix static libname on windows
    if package:is_plat("windows") and not package:config("shared") then
        _fix_libname_on_windows(package)
    end
end
