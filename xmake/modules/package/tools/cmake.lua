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
-- @file        cmake.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.base.hashset")
import("core.tool.toolchain")
import("core.project.config")
import("core.project.project")
import("lib.detect.find_file")
import("lib.detect.find_tool")
import("package.tools.ninja")
import("package.tools.msbuild")
import("detect.sdks.find_emsdk")
import("private.utils.toolchain", {alias = "toolchain_utils"})

-- get the number of parallel jobs
function _get_parallel_njobs(opt)
    return opt.jobs or option.get("jobs") or tostring(os.default_njob())
end

-- translate paths
function _translate_paths(paths)
    if is_host("windows") then
        if type(paths) == "string" then
            return (paths:gsub("\\", "/"))
        elseif type(paths) == "table" then
            local result = {}
            for _, p in ipairs(paths) do
                table.insert(result, (p:gsub("\\", "/")))
            end
            return result
        end
    end
    return paths
end

-- translate bin path
function _translate_bin_path(bin_path)
    if is_host("windows") and bin_path then
        bin_path = bin_path:gsub("\\", "/")
        if not os.isfile(bin_path) and
           not bin_path:find(string.ipattern("%.exe$")) and
           not bin_path:find(string.ipattern("%.cmd$")) and
           not bin_path:find(string.ipattern("%.bat$")) then
            bin_path = bin_path .. ".exe"
        end
    end
    return bin_path
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

-- is the toolchain compatible with the host?
function _is_toolchain_compatible_with_host(package)
    for _, name in ipairs(package:config("toolchains")) do
        if toolchain_utils.is_compatible_with_host(name) then
            return true
        end
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

-- get cflags
function _get_cflags(package, opt)
    opt = opt or {}
    local result = {}
    if opt.cross then
        table.join2(result, package:build_getenv("cflags"))
        table.join2(result, package:build_getenv("cxflags"))
        table.join2(result, toolchain_utils.map_compflags_for_package(package, "c", "define", package:build_getenv("defines")))
        table.join2(result, toolchain_utils.map_compflags_for_package(package, "c", "includedir", package:build_getenv("includedirs")))
        table.join2(result, toolchain_utils.map_compflags_for_package(package, "c", "sysincludedir", package:build_getenv("sysincludedirs")))
    end
    table.join2(result, package:config("cflags"))
    table.join2(result, package:config("cxflags"))
    if opt.cflags then
        table.join2(result, opt.cflags)
    end
    if opt.cxflags then
        table.join2(result, opt.cxflags)
    end
    if package:config("lto") then
        table.join2(result, package:_generate_lto_configs("cc").cflags)
    end
    if package:config("asan") then
        table.join2(result, package:_generate_sanitizer_configs("address", "cc").cflags)
    end
    table.join2(result, _get_cflags_from_packagedeps(package, opt))
    if #result > 0 then
        return os.args(_translate_paths(result))
    end
end

-- get cxxflags
function _get_cxxflags(package, opt)
    opt = opt or {}
    local result = {}
    if opt.cross then
        table.join2(result, package:build_getenv("cxxflags"))
        table.join2(result, package:build_getenv("cxflags"))
        table.join2(result, toolchain_utils.map_compflags_for_package(package, "cxx", "define", package:build_getenv("defines")))
        table.join2(result, toolchain_utils.map_compflags_for_package(package, "cxx", "includedir", package:build_getenv("includedirs")))
        table.join2(result, toolchain_utils.map_compflags_for_package(package, "cxx", "sysincludedir", package:build_getenv("sysincludedirs")))
    end
    table.join2(result, package:config("cxxflags"))
    table.join2(result, package:config("cxflags"))
    if opt.cxxflags then
        table.join2(result, opt.cflags)
    end
    if opt.cxflags then
        table.join2(result, opt.cxflags)
    end
    if package:config("lto") then
        table.join2(result, package:_generate_lto_configs("cxx").cxxflags)
    end
    if package:config("asan") then
        table.join2(result, package:_generate_sanitizer_configs("address", "cxx").cxxflags)
    end
    table.join2(result, _get_cflags_from_packagedeps(package, opt))
    if #result > 0 then
        return os.args(_translate_paths(result))
    end
end

-- get asflags
function _get_asflags(package, opt)
    opt = opt or {}
    local result = {}
    if opt.cross then
        table.join2(result, package:build_getenv("asflags"))
        table.join2(result, toolchain_utils.map_compflags_for_package(package, "as", "define", package:build_getenv("defines")))
        table.join2(result, toolchain_utils.map_compflags_for_package(package, "as", "includedir", package:build_getenv("includedirs")))
        table.join2(result, toolchain_utils.map_compflags_for_package(package, "as", "sysincludedir", package:build_getenv("sysincludedirs")))
    end
    table.join2(result, package:config("asflags"))
    if opt.asflags then
        table.join2(result, opt.asflags)
    end
    if #result > 0 then
        return os.args(_translate_paths(result))
    end
end

-- get ldflags
function _get_ldflags(package, opt)
    opt = opt or {}
    local result = {}
    if opt.cross then
        table.join2(result, package:build_getenv("ldflags"))
        table.join2(result, toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "link", package:build_getenv("links")))
        table.join2(result, toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "syslink", package:build_getenv("syslinks")))
        table.join2(result, toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "linkdir", package:build_getenv("linkdirs")))
    end
    table.join2(result, package:config("ldflags"))
    if package:config("lto") then
        table.join2(result, package:_generate_lto_configs().ldflags)
    end
    if package:config("asan") then
        table.join2(result, package:_generate_sanitizer_configs("address").ldflags)
    end
    table.join2(result, _get_ldflags_from_packagedeps(package, opt))
    if opt.ldflags then
        table.join2(result, opt.ldflags)
    end
    if #result > 0 then
        return os.args(_translate_paths(result))
    end
end

-- get shflags
function _get_shflags(package, opt)
    opt = opt or {}
    local result = {}
    if opt.cross then
        table.join2(result, package:build_getenv("shflags"))
        table.join2(result, toolchain_utils.map_linkflags_for_package(package, "shared", {"cxx"}, "link", package:build_getenv("links")))
        table.join2(result, toolchain_utils.map_linkflags_for_package(package, "shared", {"cxx"}, "syslink", package:build_getenv("syslinks")))
        table.join2(result, toolchain_utils.map_linkflags_for_package(package, "shared", {"cxx"}, "linkdir", package:build_getenv("linkdirs")))
    end
    table.join2(result, package:config("shflags"))
    if package:config("lto") then
        table.join2(result, package:_generate_lto_configs().shflags)
    end
    if package:config("asan") then
        table.join2(result, package:_generate_sanitizer_configs("address").shflags)
    end
    table.join2(result, _get_ldflags_from_packagedeps(package, opt))
    if opt.shflags then
        table.join2(result, opt.shflags)
    end
    if #result > 0 then
        return os.args(_translate_paths(result))
    end
end

-- get cmake version
function _get_cmake_version()
    local cmake_version = _g.cmake_version
    if not cmake_version then
        local cmake = find_tool("cmake", {version = true})
        if cmake and cmake.version then
            cmake_version = semver.new(cmake.version)
        end
        _g.cmake_version = cmake_version
    end
    return cmake_version
end

function _get_cmake_system_processor(package)
    -- on Windows, CMAKE_SYSTEM_PROCESSOR comes from PROCESSOR_ARCHITECTURE
    -- on other systems it's the output of uname -m
    if package:is_plat("windows") then
        local archs = {
            x86 = "x86",
            x64 = "AMD64",
            x86_64 = "AMD64",
            arm = "ARM",
            arm64 = "ARM64",
            arm64ec = "ARM64EC"
        }
        return archs[package:arch()] or package:arch()
    end
    return package:arch()
end

-- get mingw32 make
function _get_mingw32_make(package)
    local mingw = package:build_getenv("mingw") or package:build_getenv("sdk")
    if mingw then
        local mingw_make = _translate_bin_path(path.join(mingw, "bin", "mingw32-make.exe"))
        if os.isfile(mingw_make) then
            return mingw_make
        end
    end
end

-- get ninja
function _get_ninja(package)
    local ninja = find_tool("ninja")
    if ninja then
        return ninja.program
    end
end

-- https://github.com/xmake-io/xmake-repo/pull/1096
function _fix_cxx_compiler_cmake(package, envs)
    local cxx = envs.CMAKE_CXX_COMPILER
    if cxx and package:has_tool("cxx", "clang", "gcc") then
        local dir = path.directory(cxx)
        local name = path.filename(cxx)
        name = name:gsub("clang$", "clang++")
        name = name:gsub("clang%-", "clang++-")
        name = name:gsub("clang%.", "clang++.")
        name = name:gsub("gcc$", "g++")
        name = name:gsub("gcc%-", "g++-")
        name = name:gsub("gcc%.", "g++.")
        if dir and dir ~= "." then
            cxx = path.join(dir, name)
        else
            cxx = name
        end
        envs.CMAKE_CXX_COMPILER = _translate_bin_path(cxx)
    end
end

-- insert configs from envs
function _insert_configs_from_envs(configs, envs, opt)
    opt = opt or {}
    local configs_str = opt._configs_str
    for k, v in pairs(envs) do
        if configs_str and configs_str:find("-D" .. k .. "=", 1, true) then
            -- use user custom configuration
        else
            table.insert(configs, "-D" .. k .. "=" .. v)
        end
    end
end

-- get configs for generic
function _get_configs_for_generic(package, configs, opt)
    local cflags = _get_cflags(package, opt)
    if cflags then
        table.insert(configs, "-DCMAKE_C_FLAGS=" .. cflags)
    end
    local cxxflags = _get_cxxflags(package, opt)
    if cxxflags then
        table.insert(configs, "-DCMAKE_CXX_FLAGS=" .. cxxflags)
    end
    local asflags = _get_asflags(package, opt)
    if asflags then
        table.insert(configs, "-DCMAKE_ASM_FLAGS=" .. asflags)
    end
    local ldflags = _get_ldflags(package, opt)
    if ldflags then
        table.insert(configs, "-DCMAKE_EXE_LINKER_FLAGS=" .. ldflags)
    end
    local shflags = _get_shflags(package, opt)
    if shflags then
        table.insert(configs, "-DCMAKE_SHARED_LINKER_FLAGS=" .. shflags)
        table.insert(configs, "-DCMAKE_MODULE_LINKER_FLAGS=" .. shflags)
    end
    if not package:is_plat("windows", "mingw") and package:config("pic") ~= false then
        table.insert(configs, "-DCMAKE_POSITION_INDEPENDENT_CODE=ON")
    end
    if not package:use_external_includes() then
        table.insert(configs, "-DCMAKE_NO_SYSTEM_FROM_IMPORTED=ON")
    end
end

-- get configs for windows
function _get_configs_for_windows(package, configs, opt)
    local cmake_generator = opt.cmake_generator
    if not cmake_generator or cmake_generator:find("Visual Studio", 1, true) then
        table.insert(configs, "-A")
        if package:is_arch("x86", "i386") then
            table.insert(configs, "Win32")
        elseif package:is_arch("arm64") then
            table.insert(configs, "ARM64")
        elseif package:is_arch("arm64ec") then
            table.insert(configs, "ARM64EC")
        elseif package:is_arch("arm.*") then
            table.insert(configs, "ARM")
        else
            table.insert(configs, "x64")
        end
        local vs_toolset = toolchain_utils.get_vs_toolset_ver(_get_msvc(package):config("vs_toolset") or config.get("vs_toolset"))
        if vs_toolset then
            table.insert(configs, "-DCMAKE_GENERATOR_TOOLSET=" .. vs_toolset)
        end
    end

    -- use clang-cl
    if package:has_tool("cc", "clang_cl") then
        table.insert(configs, "-DCMAKE_C_COMPILER=" .. _translate_bin_path(package:build_getenv("cc")))
    end
    if package:has_tool("cxx", "clang_cl") then
        table.insert(configs, "-DCMAKE_CXX_COMPILER=" .. _translate_bin_path(package:build_getenv("cxx")))
    end

    -- we maybe need patch `cmake_policy(SET CMP0091 NEW)` to enable this argument for some packages
    -- @see https://cmake.org/cmake/help/latest/policy/CMP0091.html#policy:CMP0091
    -- https://github.com/xmake-io/xmake-repo/pull/303
    if package:has_runtime("MT") then
        table.insert(configs, "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded")
    elseif package:has_runtime("MTd") then
        table.insert(configs, "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDebug")
    elseif package:has_runtime("MD") then
        table.insert(configs, "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL")
    elseif package:has_runtime("MDd") then
        table.insert(configs, "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDebugDLL")
    end

    local pdb_dir = path.unix(path.join(os.curdir(), "pdb"))
    if not opt._configs_str:find("CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY", 1, true) then
        table.insert(configs, "-DCMAKE_COMPILE_PDB_OUTPUT_DIRECTORY=" .. pdb_dir)
    end
    if not opt._configs_str:find("CMAKE_PDB_OUTPUT_DIRECTORY", 1, true) then
        table.insert(configs, "-DCMAKE_PDB_OUTPUT_DIRECTORY=" .. pdb_dir)
    end

    if package:is_cross() then
        _get_configs_for_cross(package, configs, opt)
    else
        _get_configs_for_generic(package, configs, opt)
    end
end

-- get configs for android
-- https://developer.android.google.cn/ndk/guides/cmake
function _get_configs_for_android(package, configs, opt)
    opt = opt or {}
    local ndk = get_config("ndk")
    if ndk and os.isdir(ndk) then
        local ndk_sdkver = get_config("ndk_sdkver")
        table.insert(configs, "-DCMAKE_TOOLCHAIN_FILE=" .. path.join(ndk, "build/cmake/android.toolchain.cmake"))
        table.insert(configs, "-DANDROID_USE_LEGACY_TOOLCHAIN_FILE=OFF")
        table.insert(configs, "-DANDROID_ABI=" .. package:arch())
        if ndk_sdkver then
            table.insert(configs, "-DANDROID_PLATFORM=android-" .. ndk_sdkver)
            table.insert(configs, "-DANDROID_NATIVE_API_LEVEL=" .. ndk_sdkver)
        end
        -- https://cmake.org/cmake/help/latest/variable/CMAKE_ANDROID_STL_TYPE.html
        local runtime = package:runtimes()
        if runtime then
            table.insert(configs, "-DCMAKE_ANDROID_STL_TYPE=" .. runtime)
        end
        if is_host("windows") and opt.cmake_generator ~= "Ninja" then
            local make = path.join(ndk, "prebuilt", "windows-x86_64", "bin", "make.exe")
            if os.isfile(make) then
                table.insert(configs, "-DCMAKE_MAKE_PROGRAM=" .. make)
            end
        end

        -- avoid find and add system include/library path
        -- @see https://github.com/xmake-io/xmake/issues/2037
        table.insert(configs, "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH")
        table.insert(configs, "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH")
        table.insert(configs, "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH")
        table.insert(configs, "-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER")
    end
    _get_configs_for_generic(package, configs, opt)
end

-- get configs for appleos
function _get_configs_for_appleos(package, configs, opt)
    opt = opt or {}
    local envs                     = {}
    opt.cross                      = true
    envs.CMAKE_C_FLAGS             = _get_cflags(package, opt)
    envs.CMAKE_CXX_FLAGS           = _get_cxxflags(package, opt)
    envs.CMAKE_ASM_FLAGS           = _get_asflags(package, opt)
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = _get_ldflags(package, opt)
    envs.CMAKE_SHARED_LINKER_FLAGS = _get_shflags(package, opt)
    envs.CMAKE_MODULE_LINKER_FLAGS = _get_shflags(package, opt)
    -- https://cmake.org/cmake/help/v3.17/manual/cmake-toolchains.7.html#id25
    if package:is_plat("watchos") then
        envs.CMAKE_SYSTEM_NAME = "watchOS"
        if package:is_arch("x86_64", "i386") then
            envs.CMAKE_OSX_SYSROOT = "watchsimulator"
        end
    elseif package:is_plat("iphoneos") then
        envs.CMAKE_SYSTEM_NAME = "iOS"
        if package:is_arch("x86_64", "i386") then
            envs.CMAKE_OSX_SYSROOT = "iphonesimulator"
        end
    elseif package:is_cross() then
        envs.CMAKE_SYSTEM_NAME = "Darwin"
        envs.CMAKE_SYSTEM_PROCESSOR = _get_cmake_system_processor(package)
    end
    envs.CMAKE_OSX_ARCHITECTURES = package:arch()
    envs.CMAKE_FIND_ROOT_PATH_MODE_PACKAGE   = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY   = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE   = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_FRAMEWORK = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_PROGRAM   = "NEVER"
    -- avoid install bundle targets
    envs.CMAKE_MACOSX_BUNDLE       = "NO"
    _insert_configs_from_envs(configs, envs, opt)
end

-- get configs for mingw
function _get_configs_for_mingw(package, configs, opt)
    opt = opt or {}
    opt.cross                      = true
    local envs                     = {}
    local sdkdir                   = package:build_getenv("mingw") or package:build_getenv("sdk")
    envs.CMAKE_C_COMPILER          = _translate_bin_path(package:build_getenv("cc"))
    envs.CMAKE_CXX_COMPILER        = _translate_bin_path(package:build_getenv("cxx"))
    envs.CMAKE_ASM_COMPILER        = _translate_bin_path(package:build_getenv("as"))
    envs.CMAKE_AR                  = _translate_bin_path(package:build_getenv("ar"))
    envs.CMAKE_RANLIB              = _translate_bin_path(package:build_getenv("ranlib"))
    envs.CMAKE_RC_COMPILER         = _translate_bin_path(package:build_getenv("mrc"))
    envs.CMAKE_C_FLAGS             = _get_cflags(package, opt)
    envs.CMAKE_CXX_FLAGS           = _get_cxxflags(package, opt)
    envs.CMAKE_ASM_FLAGS           = _get_asflags(package, opt)
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = _get_ldflags(package, opt)
    envs.CMAKE_SHARED_LINKER_FLAGS = _get_shflags(package, opt)
    envs.CMAKE_MODULE_LINKER_FLAGS = _get_shflags(package, opt)
    -- @see https://cmake.org/cmake/help/latest/variable/CMAKE_CROSSCOMPILING.html
    -- https://github.com/xmake-io/xmake/pull/5888
    if not is_host("windows") then
        envs.CMAKE_SYSTEM_NAME = "Windows"
    end
    envs.CMAKE_SYSTEM_PROCESSOR    = _get_cmake_system_processor(package)
    -- avoid find and add system include/library path
    -- @see https://github.com/xmake-io/xmake/issues/2037
    envs.CMAKE_FIND_ROOT_PATH      = sdkdir
    envs.CMAKE_FIND_ROOT_PATH_MODE_PACKAGE = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_PROGRAM = "NEVER"
    -- avoid add -isysroot on macOS
    envs.CMAKE_OSX_SYSROOT = ""
    -- Avoid cmake to add the flags -search_paths_first and -headerpad_max_install_names on macOS
    envs.HAVE_FLAG_SEARCH_PATHS_FIRST = "0"
    -- CMAKE_MAKE_PROGRAM may be required for some CMakeLists.txt (libcurl)
    if is_subhost("windows") and opt.cmake_generator ~= "Ninja" then
        envs.CMAKE_MAKE_PROGRAM = _get_mingw32_make(package)
    end
    _fix_cxx_compiler_cmake(package, envs)
    _insert_configs_from_envs(configs, envs, opt)
end

-- get configs for wasm
function _get_configs_for_wasm(package, configs, opt)
    opt = opt or {}
    local envs = {}
    local emsdk = find_emsdk()
    assert(emsdk and emsdk.emscripten, "emscripten not found!")
    local emscripten_cmakefile = find_file("Emscripten.cmake", path.join(emsdk.emscripten, "cmake/Modules/Platform"))
    assert(emscripten_cmakefile, "Emscripten.cmake not found!")
    table.insert(configs, "-DCMAKE_TOOLCHAIN_FILE=" .. emscripten_cmakefile)
    if is_subhost("windows") then
        if opt.cmake_generator ~= "Ninja" then
            local mingw_make = _get_mingw32_make(package)
            if mingw_make then
                table.insert(configs, "-DCMAKE_MAKE_PROGRAM=" .. mingw_make)
            end
        end
    end

    -- avoid find and add system include/library path
    -- @see https://github.com/xmake-io/xmake/issues/5577
    -- https://github.com/emscripten-core/emscripten/issues/13310
    envs.CMAKE_FIND_ROOT_PATH_MODE_PACKAGE = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_PROGRAM = "NEVER"
    _get_configs_for_generic(package, configs, opt)
    _insert_configs_from_envs(configs, envs, opt)
end

-- get configs for cross
function _get_configs_for_cross(package, configs, opt)
    opt = opt or {}
    opt.cross                      = true
    local envs                     = {}
    local sdkdir                   = _translate_paths(package:build_getenv("sdk"))
    envs.CMAKE_C_COMPILER          = _translate_bin_path(package:build_getenv("cc"))
    envs.CMAKE_CXX_COMPILER        = _translate_bin_path(package:build_getenv("cxx"))
    envs.CMAKE_ASM_COMPILER        = _translate_bin_path(package:build_getenv("as"))
    envs.CMAKE_AR                  = _translate_bin_path(package:build_getenv("ar"))
    if package:is_plat("windows") and package:has_tool("cxx", "cl") then
        envs.CMAKE_AR = path.join(path.directory(envs.CMAKE_CXX_COMPILER), "lib.exe")
    end
    _fix_cxx_compiler_cmake(package, envs)
    -- @note The link command line is set in Modules/CMake{C,CXX,Fortran}Information.cmake and defaults to using the compiler, not CMAKE_LINKER,
    -- so we need to set CMAKE_CXX_LINK_EXECUTABLE to use CMAKE_LINKER as linker.
    --
    -- https://github.com/xmake-io/xmake-repo/pull/1039
    -- https://stackoverflow.com/questions/1867745/cmake-use-a-custom-linker/25274328#25274328
    -- https://github.com/xmake-io/xmake-repo/pull/2134#issuecomment-1573195810
    local ld = _translate_bin_path(package:build_getenv("ld"))
    if package:has_tool("ld", "gxx", "clangxx") then
        envs.CMAKE_CXX_LINK_EXECUTABLE = ld .. " <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
    end
    envs.CMAKE_RANLIB              = _translate_bin_path(package:build_getenv("ranlib"))
    envs.CMAKE_C_FLAGS             = _get_cflags(package, opt)
    envs.CMAKE_CXX_FLAGS           = _get_cxxflags(package, opt)
    envs.CMAKE_ASM_FLAGS           = _get_asflags(package, opt)
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = _get_ldflags(package, opt)
    envs.CMAKE_SHARED_LINKER_FLAGS = _get_shflags(package, opt)
    envs.CMAKE_MODULE_LINKER_FLAGS = _get_shflags(package, opt)
    -- we don't need to set it as cross compilation if we just pass toolchain
    -- https://github.com/xmake-io/xmake/issues/2170
    if package:is_cross() then
        local system_name = package:targetos() or "Linux"
        if system_name == "linux" then
            system_name = "Linux"
        elseif system_name == "windows" then
            system_name = "Windows"
        end
        envs.CMAKE_SYSTEM_NAME = system_name
        envs.CMAKE_SYSTEM_PROCESSOR = _get_cmake_system_processor(package)
    end
    if not package:is_plat("windows", "mingw") and package:config("pic") ~= false then
        table.insert(configs, "-DCMAKE_POSITION_INDEPENDENT_CODE=ON")
    end
    -- avoid find and add system include/library path
    -- @see https://github.com/xmake-io/xmake/issues/2037
    envs.CMAKE_FIND_ROOT_PATH              = sdkdir
    envs.CMAKE_FIND_ROOT_PATH_MODE_PACKAGE = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_PROGRAM = "NEVER"
    -- avoid add -isysroot on macOS
    envs.CMAKE_OSX_SYSROOT = ""
    -- avoid cmake to add the flags -search_paths_first and -headerpad_max_install_names on macOS
    envs.HAVE_FLAG_SEARCH_PATHS_FIRST = "0"
    -- avoids finding host include/library path
    envs.CMAKE_FIND_USE_CMAKE_SYSTEM_PATH = "0"
    envs.CMAKE_FIND_USE_INSTALL_PREFIX = "0"
    _insert_configs_from_envs(configs, envs, opt)
end

-- get configs for host toolchain
function _get_configs_for_host_toolchain(package, configs, opt)
    opt = opt or {}
    opt.cross                      = true
    local envs                     = {}
    local sdkdir                   = _translate_paths(package:build_getenv("sdk"))
    envs.CMAKE_C_COMPILER          = _translate_bin_path(package:build_getenv("cc"))
    envs.CMAKE_CXX_COMPILER        = _translate_bin_path(package:build_getenv("cxx"))
    envs.CMAKE_ASM_COMPILER        = _translate_bin_path(package:build_getenv("as"))
    envs.CMAKE_RC_COMPILER         = _translate_bin_path(package:build_getenv("mrc"))
    envs.CMAKE_AR                  = _translate_bin_path(package:build_getenv("ar"))
    _fix_cxx_compiler_cmake(package, envs)
    -- @note The link command line is set in Modules/CMake{C,CXX,Fortran}Information.cmake and defaults to using the compiler, not CMAKE_LINKER,
    -- so we need set CMAKE_CXX_LINK_EXECUTABLE to use CMAKE_LINKER as linker.
    --
    -- https://github.com/xmake-io/xmake-repo/pull/1039
    -- https://stackoverflow.com/questions/1867745/cmake-use-a-custom-linker/25274328#25274328
    -- https://github.com/xmake-io/xmake-repo/pull/2134#issuecomment-1573195810
    local ld = _translate_bin_path(package:build_getenv("ld"))
    if package:has_tool("ld", "gxx", "clangxx") then
        envs.CMAKE_CXX_LINK_EXECUTABLE = ld .. " <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
    end
    envs.CMAKE_RANLIB              = _translate_bin_path(package:build_getenv("ranlib"))
    envs.CMAKE_C_FLAGS             = _get_cflags(package, opt)
    envs.CMAKE_CXX_FLAGS           = _get_cxxflags(package, opt)
    envs.CMAKE_ASM_FLAGS           = _get_asflags(package, opt)
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = _get_ldflags(package, opt)
    envs.CMAKE_SHARED_LINKER_FLAGS = _get_shflags(package, opt)
    envs.CMAKE_MODULE_LINKER_FLAGS = _get_shflags(package, opt)
    -- we don't need to set it as cross compilation if we just pass toolchain
    -- https://github.com/xmake-io/xmake/issues/2170
    if package:is_cross() then
        envs.CMAKE_SYSTEM_NAME     = "Linux"
    end
    if not package:is_plat("windows", "mingw") and package:config("pic") ~= false then
        table.insert(configs, "-DCMAKE_POSITION_INDEPENDENT_CODE=ON")
    end
    _insert_configs_from_envs(configs, envs, opt)
end

-- get cmake generator for msvc
function _get_cmake_generator_for_msvc(package)
    local vsvers =
    {
        ["2022"] = "17",
        ["2019"] = "16",
        ["2017"] = "15",
        ["2015"] = "14",
        ["2013"] = "12",
        ["2012"] = "11",
        ["2010"] = "10",
        ["2008"] = "9"
    }
    local vs = _get_msvc(package):config("vs") or config.get("vs")
    assert(vsvers[vs], "Unknown Visual Studio version: '" .. tostring(vs) .. "' set in project.")
    return "Visual Studio " .. vsvers[vs] .. " " .. vs
end

-- get configs for cmake generator
function _get_configs_for_generator(package, configs, opt)
    opt     = opt or {}
    configs = configs or {}
    local cmake_generator = opt.cmake_generator
    if cmake_generator then
        if cmake_generator:find("Visual Studio", 1, true) then
            cmake_generator = _get_cmake_generator_for_msvc(package)
        end
        table.insert(configs, "-G")
        table.insert(configs, cmake_generator)
        if cmake_generator:find("Ninja", 1, true) then
            local jobs = _get_parallel_njobs(opt)
            local linkjobs = opt.linkjobs or option.get("linkjobs")
            if linkjobs then
                table.insert(configs, "-DCMAKE_JOB_POOL_COMPILE:STRING=compile")
                table.insert(configs, "-DCMAKE_JOB_POOL_LINK:STRING=link")
                table.insert(configs, ("-DCMAKE_JOB_POOLS:STRING=compile=%s;link=%s"):format(jobs, linkjobs))
            end
            local ninja = _get_ninja(package)
            if ninja then
                table.insert(configs, "-DCMAKE_MAKE_PROGRAM=" .. ninja)
            end
        end
    elseif package:is_plat("mingw") and is_subhost("msys") then
        table.insert(configs, "-G")
        table.insert(configs, "MSYS Makefiles")
    elseif package:is_plat("mingw") and is_subhost("windows") then
        table.insert(configs, "-G")
        table.insert(configs, "MinGW Makefiles")
    elseif package:is_plat("windows") then
        table.insert(configs, "-G")
        table.insert(configs, _get_cmake_generator_for_msvc(package))
    elseif package:is_plat("wasm") and is_subhost("windows") then
        table.insert(configs, "-G")
        table.insert(configs, "MinGW Makefiles")
    else
        table.insert(configs, "-G")
        table.insert(configs, "Unix Makefiles")
    end
end

-- get configs for installation
function _get_configs_for_install(package, configs, opt)
    -- @see https://cmake.org/cmake/help/v3.14/module/GNUInstallDirs.html
    -- LIBDIR: object code libraries (lib or lib64 or lib/<multiarch-tuple> on Debian)
    --
    table.insert(configs, "-DCMAKE_INSTALL_PREFIX=" .. package:installdir())
    if not opt._configs_str:find("CMAKE_INSTALL_LIBDIR") then
        table.insert(configs, "-DCMAKE_INSTALL_LIBDIR:PATH=lib")
    end
end

function _get_default_flags(package, configs, buildtype, opt)
    -- The default flags are different for different platforms
    -- @see https://github.com/xmake-io/xmake-repo/pull/4038#issuecomment-2116489448
    local cachekey = buildtype .. package:plat() .. package:arch()
    local cmake_default_flags = _g.cmake_default_flags and _g.cmake_default_flags[cachekey]
    if not cmake_default_flags then
        local tmpdir = path.join(os.tmpfile() .. ".dir", package:displayname(), package:mode())
        local dummy_cmakelist = path.join(tmpdir, "CMakeLists.txt")

        -- About the minimum cmake version requirement
        -- @see https://github.com/xmake-io/xmake/pull/6032
        io.writefile(dummy_cmakelist, format([[
    cmake_minimum_required(VERSION 3.15)
    project(XMakeDummyProject)

    message(STATUS "CMAKE_C_FLAGS is ${CMAKE_C_FLAGS}")
    message(STATUS "CMAKE_C_FLAGS_%s is ${CMAKE_C_FLAGS_%s}")

    message(STATUS "CMAKE_CXX_FLAGS is ${CMAKE_CXX_FLAGS}")
    message(STATUS "CMAKE_CXX_FLAGS_%s is ${CMAKE_CXX_FLAGS_%s}")

    message(STATUS "CMAKE_EXE_LINKER_FLAGS is ${CMAKE_EXE_LINKER_FLAGS}")
    message(STATUS "CMAKE_EXE_LINKER_FLAGS_%s is ${CMAKE_EXE_LINKER_FLAGS_%s}")

    message(STATUS "CMAKE_SHARED_LINKER_FLAGS is ${CMAKE_SHARED_LINKER_FLAGS}")
    message(STATUS "CMAKE_SHARED_LINKER_FLAGS_%s is ${CMAKE_SHARED_LINKER_FLAGS_%s}")

    message(STATUS "CMAKE_STATIC_LINKER_FLAGS is ${CMAKE_STATIC_LINKER_FLAGS}")
    message(STATUS "CMAKE_STATIC_LINKER_FLAGS_%s is ${CMAKE_STATIC_LINKER_FLAGS_%s}")
        ]], buildtype, buildtype, buildtype, buildtype, buildtype, buildtype, buildtype, buildtype, buildtype, buildtype))

        local runenvs = opt.envs or buildenvs(package)
        local cmake = find_tool("cmake")
        local _configs = table.join(configs, "-S " .. path.directory(dummy_cmakelist), "-B " .. tmpdir)
        local outdata = try{ function() return os.iorunv(cmake.program, _configs, {envs = runenvs}) end}
        if outdata then
            cmake_default_flags = {}
            cmake_default_flags.cflags = outdata:match("CMAKE_C_FLAGS is (.-)\n") or " "
            cmake_default_flags.cflags = cmake_default_flags.cflags .. " " .. outdata:match(format("CMAKE_C_FLAGS_%s is (.-)\n", buildtype)):replace("/MDd", ""):replace("/MD", "")
            cmake_default_flags.cxxflags = outdata:match("CMAKE_CXX_FLAGS is (.-)\n") or " "
            cmake_default_flags.cxxflags = cmake_default_flags.cxxflags .. " " .. outdata:match(format("CMAKE_CXX_FLAGS_%s is (.-)\n", buildtype)):replace("/MDd", ""):replace("/MD", "")
            cmake_default_flags.ldflags = outdata:match("CMAKE_EXE_LINKER_FLAGS is (.-)\n") or " "
            cmake_default_flags.ldflags = cmake_default_flags.ldflags .. " " .. outdata:match(format("CMAKE_EXE_LINKER_FLAGS_%s is (.-)\n", buildtype))
            cmake_default_flags.shflags = outdata:match("CMAKE_SHARED_LINKER_FLAGS is (.-)\n") or " "
            cmake_default_flags.shflags = cmake_default_flags.shflags .. " " .. outdata:match(format("CMAKE_SHARED_LINKER_FLAGS_%s is (.-)\n", buildtype))
            cmake_default_flags.arflags = outdata:match("CMAKE_STATIC_LINKER_FLAGS is (.-)\n") or " "
            cmake_default_flags.arflags = cmake_default_flags.arflags .. " " ..outdata:match(format("CMAKE_STATIC_LINKER_FLAGS_%s is (.-)\n", buildtype))

            _g.cmake_default_flags = _g.cmake_default_flags or {}
            _g.cmake_default_flags[cachekey] = cmake_default_flags
        end
        os.rm(tmpdir)
    end
    return cmake_default_flags
end

function _get_cmake_buildtype(package)
    local cmake_buildtype_map = {
        debug = "DEBUG",
        release = "RELEASE",
        releasedbg = "RELWITHDEBINFO"
    }
    local buildtype = package:mode()
    return cmake_buildtype_map[buildtype] or "RELEASE"
end

function _get_envs_for_default_flags(package, configs, opt)
    local buildtype = _get_cmake_buildtype(package)
    local envs = {}
    local default_flags = _get_default_flags(package, configs, buildtype, opt)
    if default_flags then
        if not opt.cxxflags and not opt.cxflags then
            envs[format("CMAKE_CXX_FLAGS_%s", buildtype)] = default_flags.cxxflags
        end
        if not opt.cflags and not opt.cxflags then
            envs[format("CMAKE_C_FLAGS_%s", buildtype)] = default_flags.cflags
        end
        if not opt.ldflags then
            envs[format("CMAKE_EXE_LINKER_FLAGS_%s", buildtype)] = default_flags.ldflags
        end
        if not opt.arflags then
            envs[format("CMAKE_STATIC_LINKER_FLAGS_%s", buildtype)] = default_flags.arflags
        end
        if not opt.shflags then
            envs[format("CMAKE_SHARED_LINKER_FLAGS_%s", buildtype)] = default_flags.shflags
        end
    end
    return envs
end

function _get_envs_for_runtime_flags(package, configs, opt)
    local buildtype = _get_cmake_buildtype(package)
    local envs = {}
    local runtimes = package:runtimes()
    if runtimes then
        envs[format("CMAKE_C_FLAGS_%s", buildtype)]             = toolchain_utils.map_compflags_for_package(package, "c", "runtime", runtimes)
        envs[format("CMAKE_CXX_FLAGS_%s", buildtype)]           = toolchain_utils.map_compflags_for_package(package, "cxx", "runtime", runtimes)
        envs[format("CMAKE_EXE_LINKER_FLAGS_%s", buildtype)]    = toolchain_utils.map_linkflags_for_package(package, "binary", {"cxx"}, "runtime", runtimes)
        envs[format("CMAKE_STATIC_LINKER_FLAGS_%s", buildtype)] = toolchain_utils.map_linkflags_for_package(package, "static", {"cxx"}, "runtime", runtimes)
        envs[format("CMAKE_SHARED_LINKER_FLAGS_%s", buildtype)] = toolchain_utils.map_linkflags_for_package(package, "shared", {"cxx"}, "runtime", runtimes)
        envs[format("CMAKE_MODULE_LINKER_FLAGS_%s", buildtype)] = toolchain_utils.map_linkflags_for_package(package, "shared", {"cxx"}, "runtime", runtimes)
    end
    return envs
end

function _get_configs(package, configs, opt)
    configs = configs or {}
    opt._configs_str = string.serialize(configs, {indent = false, strip = true})
    _get_configs_for_install(package, configs, opt)
    _get_configs_for_generator(package, configs, opt)
    if package:is_plat("windows") then
        _get_configs_for_windows(package, configs, opt)
    elseif package:is_plat("android") then
        _get_configs_for_android(package, configs, opt)
    elseif package:is_plat("iphoneos", "watchos") or
        -- for cross-compilation on macOS, @see https://github.com/xmake-io/xmake/issues/2804
        (package:is_plat("macosx") and (get_config("appledev") or not package:is_arch(os.subarch()))) then
        _get_configs_for_appleos(package, configs, opt)
    elseif package:is_plat("mingw") then
        _get_configs_for_mingw(package, configs, opt)
    elseif package:is_plat("wasm") then
        _get_configs_for_wasm(package, configs, opt)
    elseif package:is_cross() then
        _get_configs_for_cross(package, configs, opt)
    elseif package:config("toolchains") then
        -- we still need find system libraries,
        -- it just pass toolchain environments if the toolchain is compatible with host
        if _is_toolchain_compatible_with_host(package) then
            _get_configs_for_host_toolchain(package, configs, opt)
        else
            _get_configs_for_cross(package, configs, opt)
        end
    else
        _get_configs_for_generic(package, configs, opt)
    end

    -- fix error for cmake 4.x
    -- e.g. Compatibility with CMake < 3.5 has been removed from CMake.
    if _get_cmake_version() and _get_cmake_version():ge("4.0") then
        table.insert(configs, "-DCMAKE_POLICY_VERSION_MINIMUM=3.5")
    end

    local envs = _get_envs_for_default_flags(package, configs, opt)
    local runtime_envs = _get_envs_for_runtime_flags(package, configs, opt)
    if runtime_envs then
        envs = envs or {}
        for name, value in pairs(runtime_envs) do
            envs[name] = (envs[name] or " ") .. " " .. table.concat(value, " ")
        end
    end
    _insert_configs_from_envs(configs, envs or {}, opt)

    local ccache = package:data("ccache")
    if ccache then
        table.insert(configs, "-DCMAKE_C_COMPILER_LAUNCHER=" .. ccache)
        table.insert(configs, "-DCMAKE_CXX_COMPILER_LAUNCHER=" .. ccache)
    end

    return configs
end

-- Fix pdb issue, if multiple CL.EXE write to the same .PDB file, please use /FS
-- @see https://github.com/xmake-io/xmake/issues/5353
function _fix_pdbdir_for_ninja(package)
    if package:is_plat("windows") and package:has_tool("cxx", "cl") then
        local pdbdir = "pdb"
        if not os.isdir(pdbdir) then
            os.mkdir(pdbdir)
        end
    end
end

-- enter build directory
function _enter_buildir(package, opt)
    local buildir = opt.buildir or package:buildir()
    os.mkdir(path.join(buildir, "install"))
    return os.cd(buildir)
end

-- get build environments
function buildenvs(package, opt)

    -- we need to bind msvc environments manually
    -- @see https://github.com/xmake-io/xmake/issues/1057
    opt = opt or {}
    local envs = {}
    if package:is_plat("windows") then
        envs = _get_msvc_runenvs(package)
    end

    -- we need to pass pkgconf for windows/mingw without msys2/cygwin
    if package:is_plat("windows", "mingw") and is_subhost("windows") then
        local pkgconf = _get_pkgconfig(package)
        if pkgconf then
            envs.PKG_CONFIG = pkgconf
        end
    end

    -- add environments for cmake/find_packages
    -- and we need also find them from private libraries,
    -- @see https://github.com/xmake-io/xmake-repo/pull/2553
    local CMAKE_LIBRARY_PATH = {}
    local CMAKE_INCLUDE_PATH = {}
    local CMAKE_PREFIX_PATH  = {}
    local PKG_CONFIG_PATH = {}
    for _, dep in ipairs(package:librarydeps({private = true})) do
        if dep:is_system() then
            local fetchinfo = dep:fetch()
            if fetchinfo then
                table.join2(CMAKE_LIBRARY_PATH, fetchinfo.linkdirs)
                table.join2(CMAKE_INCLUDE_PATH, fetchinfo.includedirs)
                table.join2(CMAKE_INCLUDE_PATH, fetchinfo.sysincludedirs)
            end
        else
            table.join2(CMAKE_PREFIX_PATH, dep:installdir())
            local pkgconfig = path.join(dep:installdir(), "lib", "pkgconfig")
            if os.isdir(pkgconfig) then
                table.insert(PKG_CONFIG_PATH, pkgconfig)
            end
            pkgconfig = path.join(dep:installdir(), "share", "pkgconfig")
            if os.isdir(pkgconfig) then
                table.insert(PKG_CONFIG_PATH, pkgconfig)
            end
        end
    end
    envs.CMAKE_LIBRARY_PATH = path.joinenv(CMAKE_LIBRARY_PATH)
    envs.CMAKE_INCLUDE_PATH = path.joinenv(CMAKE_INCLUDE_PATH)
    envs.CMAKE_PREFIX_PATH  = path.joinenv(CMAKE_PREFIX_PATH)
    envs.PKG_CONFIG_PATH    = path.joinenv(PKG_CONFIG_PATH)
    return envs
end

-- do build for msvc
function _build_for_msvc(package, configs, opt)
    local allbuild = os.isfile("ALL_BUILD.vcxproj") and "ALL_BUILD.vcxproj" or "ALL_BUILD.vcproj"
    assert(os.isfile(allbuild), "ALL_BUILD project not found!")
    msbuild.build(package, {allbuild, "-t:Rebuild"}, opt)
end

-- do build for make
function _build_for_make(package, configs, opt)
    local argv = {}
    local targets = table.wrap(opt.target)
    if #targets ~= 0 then
        table.join2(argv, targets)
    end
    local jobs = _get_parallel_njobs(opt)
    table.insert(argv, "-j" .. jobs)
    if option.get("diagnosis") then
        table.insert(argv, "VERBOSE=1")
    end
    if is_host("bsd") then
        os.vrunv("gmake", argv)
    elseif is_subhost("windows") and package:is_plat("mingw") then
        local mingw_make = assert(_get_mingw32_make(package), "mingw32-make.exe not found!")
        os.vrunv(mingw_make, argv)
    elseif package:is_plat("android") and is_host("windows") then
        local make
        local ndk = get_config("ndk")
        if ndk then
            make = path.join(ndk, "prebuilt", "windows-x86_64", "bin", "make.exe")
        end
        if not make or not os.isfile(make) then
            make = "make"
        end
        os.vrunv(make, argv)
    else
        os.vrunv("make", argv)
    end
end

-- do build for ninja
function _build_for_ninja(package, configs, opt)
    opt = opt or {}
    _fix_pdbdir_for_ninja(package)
    ninja.build(package, {}, {envs = opt.envs or buildenvs(package, opt),
        jobs = opt.jobs,
        target = opt.target})
end

-- do build for cmake/build
function _build_for_cmakebuild(package, configs, opt)
    local cmake = assert(find_tool("cmake"), "cmake not found!")
    local argv = {"--build", os.curdir()}
    if opt.config then
        table.insert(argv, "--config")
        table.insert(argv, opt.config)
    end
    local targets = table.wrap(opt.target)
    if #targets ~= 0 then
        table.insert(argv, "--target")
        if #targets > 1 then
            -- https://stackoverflow.com/questions/47553569/how-can-i-build-multiple-targets-using-cmake-build
            if _get_cmake_version() and _get_cmake_version():ge("3.15") then
                table.join2(argv, targets)
            else
                raise("Build multiple targets need cmake >=3.15")
            end
        else
            table.insert(argv, targets[1])
        end
    end
    os.vrunv(cmake.program, argv, {envs = opt.envs or buildenvs(package)})
end

-- do install for msvc
function _install_for_msvc(package, configs, opt)
    local allbuild = os.isfile("ALL_BUILD.vcxproj") and "ALL_BUILD.vcxproj" or "ALL_BUILD.vcproj"
    assert(os.isfile(allbuild), "ALL_BUILD project not found!")
    msbuild.build(package, {allbuild, "-t:Rebuild", "/nr:false"}, opt)
    local projfile = os.isfile("INSTALL.vcxproj") and "INSTALL.vcxproj" or "INSTALL.vcproj"
    if os.isfile(projfile) then
        msbuild.build(package, {projfile}, opt)
        os.trycp("install/bin", package:installdir())
        os.trycp("install/lib", package:installdir()) -- perhaps only headers library
        os.trycp("install/share", package:installdir())
        os.trycp("install/include", package:installdir())
    else
        os.trycp("**.dll", package:installdir("bin"))
        os.trycp("**.lib", package:installdir("lib"))
        os.trycp("**.exp", package:installdir("lib"))
        if package:config("shared") or not package:is_library() then
            os.trycp("**.pdb", package:installdir("bin"))
        else
            os.trycp("**.pdb", package:installdir("lib"))
        end
    end
end

-- do install for make
function _install_for_make(package, configs, opt)
    local jobs = _get_parallel_njobs(opt)
    local argv = {"-j" .. jobs}
    if option.get("diagnosis") then
        table.insert(argv, "VERBOSE=1")
    end
    if is_host("bsd") then
        os.vrunv("gmake", argv)
        os.vrunv("gmake", {"install"})
    elseif is_subhost("windows") and package:is_plat("mingw", "wasm") then
        local mingw_make = assert(_get_mingw32_make(package), "mingw32-make.exe not found!")
        os.vrunv(mingw_make, argv)
        os.vrunv(mingw_make, {"install"})
    elseif package:is_plat("android") and is_host("windows") then
        local make
        local ndk = get_config("ndk")
        if ndk then
            make = path.join(ndk, "prebuilt", "windows-x86_64", "bin", "make.exe")
        end
        if not make or not os.isfile(make) then
            make = "make"
        end
        os.vrunv(make, argv)
        os.vrunv(make, {"install"})
    else
        os.vrunv("make", argv)
        os.vrunv("make", {"install"})
    end
end

-- do install for ninja
function _install_for_ninja(package, configs, opt)
    opt = opt or {}
    _fix_pdbdir_for_ninja(package)
    ninja.install(package, {}, {envs = opt.envs or buildenvs(package, opt),
        jobs = opt.jobs,
        target = opt.target})
end

-- do install for cmake/build
function _install_for_cmakebuild(package, configs, opt)
    opt = opt or {}
    local cmake = assert(find_tool("cmake"), "cmake not found!")
    local argv = {"--build", os.curdir()}
    if opt.config then
        table.insert(argv, "--config")
        table.insert(argv, opt.config)
    end
    os.vrunv(cmake.program, argv, {envs = opt.envs or buildenvs(package)})
    os.vrunv(cmake.program, {"--install", os.curdir()})
end

-- get cmake generator
function _get_cmake_generator(package, opt)
    opt = opt or {}
    local cmake_generator = opt.cmake_generator
    if not cmake_generator then
        local use_ninja = package:policy("package.cmake_generator.ninja")
        if use_ninja == nil then
            use_ninja = project.policy("package.cmake_generator.ninja")
        end
        if use_ninja then
            cmake_generator = "Ninja"
        end
        if not cmake_generator then
            if package:has_tool("cc", "clang_cl") or package:has_tool("cxx", "clang_cl") then
                cmake_generator = "Ninja"
            elseif (is_subhost("windows") and package:is_plat("mingw", "wasm"))
                or (package:is_plat("windows") and is_host("linux")) then
                local ninja = _get_ninja(package)
                if ninja then
                    cmake_generator = "Ninja"
                end
            end
        end
        local cmake_generator_env = os.getenv("CMAKE_GENERATOR")
        if not cmake_generator and cmake_generator_env then
            cmake_generator = cmake_generator_env
        end
        if cmake_generator then
            opt.cmake_generator = cmake_generator
        end
    end
    return cmake_generator
end

-- shrink cmake arguments, fix too long arguments
-- @see https://github.com/xmake-io/xmake-repo/pull/5247#discussion_r1780302212
function _shrink_cmake_arguments(argv, oldir, opt)
    local cmake_argv = {}
    local long_options = hashset.of(
        "CMAKE_C_FLAGS",
        "CMAKE_CXX_FLAGS",
        "CMAKE_ASM_FLAGS",
        "CMAKE_EXE_LINKER_FLAGS",
        "CMAKE_SHARED_LINKER_FLAGS",
        "CMAKE_MODULE_LINKER_FLAGS",
        "CMAKE_C_FLAGS_RELEASE",
        "CMAKE_CXX_FLAGS_RELEASE",
        "CMAKE_ASM_FLAGS_RELEASE",
        "CMAKE_EXE_LINKER_FLAGS_RELEASE",
        "CMAKE_SHARED_LINKER_FLAGS_RELEASE",
        "CMAKE_MODULE_LINKER_FLAGS_RELEASE",
        "CMAKE_C_FLAGS_DEBUG",
        "CMAKE_CXX_FLAGS_DEBUG",
        "CMAKE_ASM_FLAGS_DEBUG",
        "CMAKE_EXE_LINKER_FLAGS_DEBUG",
        "CMAKE_SHARED_LINKER_FLAGS_DEBUG",
        "CMAKE_MODULE_LINKER_FLAGS_DEBUG")
    local shrink = false
    local add_compile_options = false
    local add_link_options = false
    if _get_cmake_version() and _get_cmake_version():ge("3.13") then
        add_compile_options = true
        add_link_options = true
    end
    local buildtypes_map = {
        RELEASE = "Release",
        DEBUG = "Debug",
        RELWITHDEBINFO = "RelWithDebInfo"
    }
    table.remove_if(argv, function (idx, value)
        local k, v = value:match("%-D(.*)=(.*)")
        if k and v and long_options:has(k) then
            local kind, mode = k:match("CMAKE_(.+)_FLAGS_(.+)")
            if not kind then
                kind = k:match("CMAKE_(.+)_FLAGS")
            end
            -- improve cmake flags
            -- @see https://github.com/xmake-io/xmake/issues/5826
            --[[
            local build_type = mode and buildtypes_map[mode] or nil
            if #v > 0 and add_compile_options and (kind == "C" or kind == "CXX" or kind == "ASM") then
                if build_type then
                    table.insert(cmake_argv, ("if(CMAKE_BUILD_TYPE STREQUAL \"%s\")"):format(build_type))
                end
                local flags = v:replace("\"", "\\\"")
                table.insert(cmake_argv, ("set(COMP_%s_FLAGS \"%s\")"):format(kind, flags))
                table.insert(cmake_argv, ("add_compile_options($<$<COMPILE_LANGUAGE:%s>:${COMP_%s_FLAGS}>)"):format(kind, kind))
                if build_type then
                    table.insert(cmake_argv, "endif()")
                end
                shrink = true
                return true
            end]]
            -- shrink long arguments
            if #v > 128 then
                local flags = v:replace("\"", "\\\"")
                table.insert(cmake_argv, ("set(%s \"%s\")"):format(k, flags))
                shrink = true
                return true
            end
        end
    end)
    if shrink then
        local cmakefile = path.join(opt.curdir and opt.curdir or oldir, "CMakeLists.txt")
        io.insert(cmakefile, 1, table.concat(cmake_argv, "\n"))
    end
end

function configure(package, configs, opt)
    opt = opt or {}
    local oldir = _enter_buildir(package, opt)

    -- pass configurations
    local argv = {}
    for name, value in pairs(_get_configs(package, configs, opt)) do
        value = tostring(value):trim()
        if type(name) == "number" then
            if value ~= "" then
                table.insert(argv, value)
            end
        else
            table.insert(argv, "-D" .. name .. "=" .. value)
        end
    end
    -- shrink cmake arguments, fix too long arguments
    -- @see https://github.com/xmake-io/xmake-repo/pull/5247#discussion_r1780302212
    _shrink_cmake_arguments(argv, oldir, opt)
    table.insert(argv, oldir)

    -- do configure
    local cmake = assert(find_tool("cmake"), "cmake not found!")
    os.vrunv(cmake.program, argv, {envs = opt.envs or buildenvs(package, opt)})
    os.cd(oldir)
end

-- build package
function build(package, configs, opt)
    opt = opt or {}
    local cmake_generator = _get_cmake_generator(package, opt)

    -- do configure
    configure(package, configs, opt)

    -- do build
    local oldir = _enter_buildir(package, opt)
    if opt.cmake_build then
        _build_for_cmakebuild(package, configs, opt)
    elseif cmake_generator then
        if cmake_generator:find("Visual Studio", 1, true) then
            _build_for_msvc(package, configs, opt)
        elseif cmake_generator == "Ninja" then
            _build_for_ninja(package, configs, opt)
        elseif cmake_generator:find("Makefiles", 1, true) then
            _build_for_make(package, configs, opt)
        else
            raise("unknown cmake generator(%s)!", cmake_generator)
        end
    else
        if package:is_plat("windows") then
            _build_for_msvc(package, configs, opt)
        else
            _build_for_make(package, configs, opt)
        end
    end
    os.cd(oldir)
end

-- install package
function install(package, configs, opt)
    opt = opt or {}
    local cmake_generator = _get_cmake_generator(package, opt)

    -- do configure
    configure(package, configs, opt)

    -- do build and install
    local oldir = _enter_buildir(package, opt)
    if opt.cmake_build then
        _install_for_cmakebuild(package, configs, opt)
    elseif cmake_generator then
        if cmake_generator:find("Visual Studio", 1, true) then
            _install_for_msvc(package, configs, opt)
        elseif cmake_generator == "Ninja" then
            _install_for_ninja(package, configs, opt)
        elseif cmake_generator:find("Makefiles", 1, true) then
            _install_for_make(package, configs, opt)
        else
            raise("unknown cmake generator(%s)!", cmake_generator)
        end
    else
        if package:is_plat("windows") then
            _install_for_msvc(package, configs, opt)
        else
            _install_for_make(package, configs, opt)
        end
    end
    if package:is_plat("windows") and os.isdir("pdb") then
        if package:config("shared") or not package:is_library() then
            os.trycp("pdb/**.pdb", package:installdir("bin"))
        else
            os.trycp("pdb/**.pdb", package:installdir("lib"))
        end
    end
    os.cd(oldir)
end
