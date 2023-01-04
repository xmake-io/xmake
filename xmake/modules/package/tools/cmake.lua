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
import("core.tool.toolchain")
import("core.project.config")
import("core.tool.linker")
import("core.tool.compiler")
import("lib.detect.find_file")
import("lib.detect.find_tool")
import("package.tools.ninja")
import("detect.sdks.find_emsdk")

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
        if not bin_path:find(string.ipattern("%.exe$")) and
           not bin_path:find(string.ipattern("%.cmd$")) and
           not bin_path:find(string.ipattern("%.bat$")) then
            bin_path = bin_path .. ".exe"
        end
    end
    return bin_path
end

-- map compiler flags
function _map_compflags(package, langkind, name, values)
    return compiler.map_flags(langkind, name, values, {target = package})
end

-- map linker flags
function _map_linkflags(package, targetkind, sourcekinds, name, values)
    return linker.map_flags(targetkind, sourcekinds, name, values, {target = package})
end

-- is cross compilation?
function _is_cross_compilation(package)
    if not package:is_plat(os.subhost()) then
        return true
    end
    if package:is_plat("macosx") and not package:is_arch(os.subarch()) then
        return true
    end
    return false
end

-- is the toolchain compatible with the host?
function _is_toolchain_compatible_with_host(package)
    local toolchains = package:config("toolchains")
    if toolchains then
        toolchains = table.wrap(toolchains)
        if is_host("linux", "macosx", "bsd") then
            for _, name in ipairs(toolchains) do
                if name:startswith("clang") or name:startswith("gcc") then
                    return true
                end
            end
        elseif is_host("windows") and table.contains(toolchains, "msvc") then
            return true
        end
    end
end

-- get msvc
function _get_msvc(package)
    local msvc = toolchain.load("msvc", {plat = package:plat(), arch = package:arch()})
    assert(msvc:check(), "vs not found!") -- we need check vs envs if it has been not checked yet
    return msvc
end

-- get msvc run environments
function _get_msvc_runenvs(package)
    return os.joinenvs(_get_msvc(package):runenvs())
end

-- get vs arch
function _get_vsarch(package)
    local arch = package:arch()
    if arch == 'x86' or arch == 'i386' then return "Win32" end
    if arch == 'x86_64' then return "x64" end
    if arch:startswith('arm64') then return "ARM64" end
    if arch:startswith('arm') then return "ARM" end
    return arch
end

-- get cflags from package deps
function _get_cflags_from_packagedeps(package, opt)
    local result = {}
    for _, depname in ipairs(opt.packagedeps) do
        local dep = package:dep(depname)
        if dep then
            local fetchinfo = dep:fetch({external = false})
            if fetchinfo then
                table.join2(result, _map_compflags(package, "cxx", "define", fetchinfo.defines))
                table.join2(result, _translate_paths(_map_compflags(package, "cxx", "includedir", fetchinfo.includedirs)))
                table.join2(result, _translate_paths(_map_compflags(package, "cxx", "sysincludedir", fetchinfo.sysincludedirs)))
            end
        end
    end
    return result
end

-- get ldflags from package deps
function _get_ldflags_from_packagedeps(package, opt)
    local result = {}
    for _, depname in ipairs(opt.packagedeps) do
        local dep = package:dep(depname)
        if dep then
            local fetchinfo = dep:fetch({external = false})
            if fetchinfo then
                table.join2(result, _translate_paths(_map_linkflags(package, "binary", {"cxx"}, "linkdir", fetchinfo.linkdirs)))
                table.join2(result, _map_linkflags(package, "binary", {"cxx"}, "link", fetchinfo.links))
                table.join2(result, _translate_paths(_map_linkflags(package, "binary", {"cxx"}, "syslink", fetchinfo.syslinks)))
                table.join2(result, _map_linkflags(package, "binary", {"cxx"}, "framework", fetchinfo.frameworks))
            end
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
        table.join2(result, _map_compflags(package, "c", "define", package:build_getenv("defines")))
        table.join2(result, _map_compflags(package, "c", "includedir", package:build_getenv("includedirs")))
        table.join2(result, _map_compflags(package, "c", "sysincludedir", package:build_getenv("sysincludedirs")))
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
    table.join2(result, _get_cflags_from_packagedeps(package, opt))
    if #result > 0 then
        return os.args(result)
    end
end

-- get cxxflags
function _get_cxxflags(package, opt)
    opt = opt or {}
    local result = {}
    if opt.cross then
        table.join2(result, package:build_getenv("cxxflags"))
        table.join2(result, package:build_getenv("cxflags"))
        table.join2(result, _map_compflags(package, "cxx", "define", package:build_getenv("defines")))
        table.join2(result, _map_compflags(package, "cxx", "includedir", package:build_getenv("includedirs")))
        table.join2(result, _map_compflags(package, "cxx", "sysincludedir", package:build_getenv("sysincludedirs")))
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
    table.join2(result, _get_cflags_from_packagedeps(package, opt))
    if #result > 0 then
        return os.args(result)
    end
end

-- get asflags
function _get_asflags(package, opt)
    opt = opt or {}
    local result = {}
    if opt.cross then
        table.join2(result, package:build_getenv("asflags"))
        table.join2(result, _map_compflags(package, "as", "define", package:build_getenv("defines")))
        table.join2(result, _map_compflags(package, "as", "includedir", package:build_getenv("includedirs")))
        table.join2(result, _map_compflags(package, "as", "sysincludedir", package:build_getenv("sysincludedirs")))
    end
    table.join2(result, package:config("asflags"))
    if opt.asflags then
        table.join2(result, opt.asflags)
    end
    if #result > 0 then
        return os.args(result)
    end
end

-- get ldflags
function _get_ldflags(package, opt)
    opt = opt or {}
    local result = {}
    if opt.cross then
        table.join2(result, package:build_getenv("ldflags"))
        table.join2(result, _map_linkflags(package, "binary", {"cxx"}, "link", package:build_getenv("links")))
        table.join2(result, _map_linkflags(package, "binary", {"cxx"}, "syslink", package:build_getenv("syslinks")))
        table.join2(result, _map_linkflags(package, "binary", {"cxx"}, "linkdir", package:build_getenv("linkdirs")))
    end
    if package:config("lto") then
        table.join2(result, package:_generate_lto_configs().ldflags)
    end
    table.join2(result, _get_ldflags_from_packagedeps(package, opt))
    if opt.ldflags then
        table.join2(result, opt.ldflags)
    end
    if #result > 0 then
        return os.args(result)
    end
end

-- get shflags
function _get_shflags(package, opt)
    opt = opt or {}
    local result = {}
    if opt.cross then
        table.join2(result, package:build_getenv("shflags"))
        table.join2(result, _map_linkflags(package, "shared", {"cxx"}, "link", package:build_getenv("links")))
        table.join2(result, _map_linkflags(package, "shared", {"cxx"}, "syslink", package:build_getenv("syslinks")))
        table.join2(result, _map_linkflags(package, "shared", {"cxx"}, "linkdir", package:build_getenv("linkdirs")))
    end
    if package:config("lto") then
        table.join2(result, package:_generate_lto_configs().shflags)
    end
    table.join2(result, _get_ldflags_from_packagedeps(package, opt))
    if opt.shflags then
        table.join2(result, opt.shflags)
    end
    if #result > 0 then
        return os.args(result)
    end
end

-- get vs toolset
function _get_vs_toolset(package)
    local toolset_ver = nil
    local vs_toolset = _get_msvc(package):config("vs_toolset") or config.get("vs_toolset")
    if vs_toolset then
        local verinfo = vs_toolset:split('%.')
        if #verinfo >= 2 then
            toolset_ver = "v" .. verinfo[1] .. (verinfo[2]:sub(1, 1) or "0")
        end
    end
    return toolset_ver
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
    end
    if package:config("pic") ~= false then
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
        elseif package:is_arch("arm.*") then
            table.insert(configs, "ARM")
        else
            table.insert(configs, "x64")
        end
        local vs_toolset = _get_vs_toolset(package)
        if vs_toolset then
            table.insert(configs, "-DCMAKE_GENERATOR_TOOLSET=" .. vs_toolset)
        end
    end
    -- we maybe need patch `cmake_policy(SET CMP0091 NEW)` to enable this argument for some packages
    -- @see https://cmake.org/cmake/help/latest/policy/CMP0091.html#policy:CMP0091
    -- https://github.com/xmake-io/xmake-repo/pull/303
    local vs_runtime = package:config("vs_runtime")
    if vs_runtime == "MT" then
        table.insert(configs, "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded")
    elseif vs_runtime == "MTd" then
        table.insert(configs, "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDebug")
    elseif vs_runtime == "MD" then
        table.insert(configs, "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL")
    elseif vs_runtime == "MDd" then
        table.insert(configs, "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDebugDLL")
    end
    if vs_runtime then
        -- CMake default MSVC flags as of 3.21.2
        local default_debug_flags = "/Zi /Ob0 /Od /RTC1"
        local default_release_flags = "/O2 /Ob2 /DNDEBUG"
        table.insert(configs, '-DCMAKE_CXX_FLAGS_DEBUG=/' .. vs_runtime .. ' ' .. default_debug_flags)
        table.insert(configs, '-DCMAKE_CXX_FLAGS_RELEASE=/' .. vs_runtime .. ' ' .. default_release_flags)
        table.insert(configs, '-DCMAKE_C_FLAGS_DEBUG=/' .. vs_runtime .. ' ' .. default_debug_flags)
        table.insert(configs, '-DCMAKE_C_FLAGS_RELEASE=/' .. vs_runtime .. ' ' .. default_release_flags)
    end
    if not opt._configs_str:find("CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY") then
        table.insert(configs, "-DCMAKE_COMPILE_PDB_OUTPUT_DIRECTORY=pdb")
    end
    _get_configs_for_generic(package, configs, opt)
end

-- get configs for android
function _get_configs_for_android(package, configs, opt)

    -- https://developer.android.google.cn/ndk/guides/cmake
    local ndk = get_config("ndk")
    if ndk and os.isdir(ndk) then
        local ndk_sdkver = get_config("ndk_sdkver")
        local ndk_cxxstl = get_config("ndk_cxxstl")
        table.insert(configs, "-DCMAKE_TOOLCHAIN_FILE=" .. path.join(ndk, "build/cmake/android.toolchain.cmake"))
        table.insert(configs, "-DANDROID_ABI=" .. package:arch())
        if ndk_sdkver then
            table.insert(configs, "-DANDROID_NATIVE_API_LEVEL=" .. ndk_sdkver)
        end
        if ndk_cxxstl then
            table.insert(configs, "-DANDROID_STL=" .. ndk_cxxstl)
        end
        if is_host("windows") then
            local make = path.join(ndk, "prebuilt", "windows-x86_64", "bin", "make.exe")
            if os.isfile(make) then
                table.insert(configs, "-DCMAKE_MAKE_PROGRAM=" .. make)
            end
        end
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
    elseif package:is_plat("macosx") then
        envs.CMAKE_SYSTEM_NAME = "Darwin"
    end
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY   = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE   = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_FRAMEWORK = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_PROGRAM   = "NEVER"
    -- avoid install bundle targets
    envs.CMAKE_MACOSX_BUNDLE       = "NO"
    for k, v in pairs(envs) do
        table.insert(configs, "-D" .. k .. "=" .. v)
    end
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
    envs.CMAKE_LINKER              = _translate_bin_path(package:build_getenv("ld"))
    envs.CMAKE_RANLIB              = _translate_bin_path(package:build_getenv("ranlib"))
    envs.CMAKE_RC_COMPILER         = _translate_bin_path(package:build_getenv("mrc"))
    envs.CMAKE_C_FLAGS             = _get_cflags(package, opt)
    envs.CMAKE_CXX_FLAGS           = _get_cxxflags(package, opt)
    envs.CMAKE_ASM_FLAGS           = _get_asflags(package, opt)
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = _get_ldflags(package, opt)
    envs.CMAKE_SHARED_LINKER_FLAGS = _get_shflags(package, opt)
    envs.CMAKE_SYSTEM_NAME         = "Windows"
    -- avoid find and add system include/library path
    -- @see https://github.com/xmake-io/xmake/issues/2037
    envs.CMAKE_FIND_ROOT_PATH      = sdkdir
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_PROGRAM = "NEVER"
    -- avoid add -isysroot on macOS
    envs.CMAKE_OSX_SYSROOT = ""
    -- Avoid cmake to add the flags -search_paths_first and -headerpad_max_install_names on macOS
    envs.HAVE_FLAG_SEARCH_PATHS_FIRST = "0"
    -- CMAKE_MAKE_PROGRAM may be required for some CMakeLists.txt (libcurl)
    if is_subhost("windows") then
        local mingw = assert(package:build_getenv("mingw") or package:build_getenv("sdk"), "mingw not found!")
        envs.CMAKE_MAKE_PROGRAM = path.join(mingw, "bin", "mingw32-make.exe")
    end

    if opt.cmake_generator == "Ninja" then
        envs.CMAKE_MAKE_PROGRAM = "ninja"
    end

    for k, v in pairs(envs) do
        table.insert(configs, "-D" .. k .. "=" .. v)
    end
end

-- get configs for wasm
function _get_configs_for_wasm(package, configs, opt)
    local emsdk = find_emsdk()
    assert(emsdk and emsdk.emscripten, "emscripten not found!")
    local emscripten_cmakefile = find_file("Emscripten.cmake", path.join(emsdk.emscripten, "cmake/Modules/Platform"))
    assert(emscripten_cmakefile, "Emscripten.cmake not found!")
    table.insert(configs, "-DCMAKE_TOOLCHAIN_FILE=" .. emscripten_cmakefile)
    if is_subhost("windows") then
        local mingw = assert(package:build_getenv("mingw") or package:build_getenv("sdk"), "mingw not found!")
        table.insert(configs, "-DCMAKE_MAKE_PROGRAM=" .. _translate_paths(path.join(mingw, "bin", "mingw32-make.exe")))
    end
    _get_configs_for_generic(package, configs, opt)
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
    -- https://github.com/xmake-io/xmake-repo/pull/1096
    local cxx = envs.CMAKE_CXX_COMPILER
    if cxx and package:has_tool("cxx", "clang", "gcc") then
        local dir = path.directory(cxx)
        local name = path.filename(cxx)
        name = name:gsub("clang$", "clang++")
        name = name:gsub("clang%-", "clang++-")
        name = name:gsub("gcc$", "g++")
        name = name:gsub("gcc%-", "g++-")
        envs.CMAKE_CXX_COMPILER = _translate_bin_path(dir and path.join(dir, name) or name)
    end
    -- @note The link command line is set in Modules/CMake{C,CXX,Fortran}Information.cmake and defaults to using the compiler, not CMAKE_LINKER,
    -- so we need set CMAKE_CXX_LINK_EXECUTABLE to use CMAKE_LINKER as linker.
    --
    -- https://github.com/xmake-io/xmake-repo/pull/1039
    -- https://stackoverflow.com/questions/1867745/cmake-use-a-custom-linker/25274328#25274328
    envs.CMAKE_LINKER              = _translate_bin_path(package:build_getenv("ld"))
    if package:has_tool("ld", "gxx", "clangxx") then
        envs.CMAKE_CXX_LINK_EXECUTABLE = "<CMAKE_LINKER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
    end
    envs.CMAKE_RANLIB              = _translate_bin_path(package:build_getenv("ranlib"))
    envs.CMAKE_C_FLAGS             = _get_cflags(package, opt)
    envs.CMAKE_CXX_FLAGS           = _get_cxxflags(package, opt)
    envs.CMAKE_ASM_FLAGS           = _get_asflags(package, opt)
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = _get_ldflags(package, opt)
    envs.CMAKE_SHARED_LINKER_FLAGS = _get_shflags(package, opt)
    -- we need not set it as cross compilation if we just pass toolchain
    -- https://github.com/xmake-io/xmake/issues/2170
    if not package:is_plat(os.subhost()) then
        envs.CMAKE_SYSTEM_NAME     = "Linux"
    else
        if package:config("pic") ~= false then
            table.insert(configs, "-DCMAKE_POSITION_INDEPENDENT_CODE=ON")
        end
    end
    -- avoid find and add system include/library path
    -- @see https://github.com/xmake-io/xmake/issues/2037
    envs.CMAKE_FIND_ROOT_PATH      = sdkdir
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_PROGRAM = "NEVER"
    -- avoid add -isysroot on macOS
    envs.CMAKE_OSX_SYSROOT = ""
    -- Avoid cmake to add the flags -search_paths_first and -headerpad_max_install_names on macOS
    envs.HAVE_FLAG_SEARCH_PATHS_FIRST = "0"
    -- Avoids finding host include/library path
    envs.CMAKE_FIND_USE_CMAKE_SYSTEM_PATH = "0"
    envs.CMAKE_FIND_USE_INSTALL_PREFIX = "0"
    for k, v in pairs(envs) do
        table.insert(configs, "-D" .. k .. "=" .. v)
    end
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
    envs.CMAKE_AR                  = _translate_bin_path(package:build_getenv("ar"))
    -- https://github.com/xmake-io/xmake-repo/pull/1096
    local cxx = envs.CMAKE_CXX_COMPILER
    if cxx and package:has_tool("cxx", "clang", "gcc") then
        local dir = path.directory(cxx)
        local name = path.filename(cxx)
        name = name:gsub("clang$", "clang++")
        name = name:gsub("clang%-", "clang++-")
        name = name:gsub("gcc$", "g++")
        name = name:gsub("gcc%-", "g++-")
        envs.CMAKE_CXX_COMPILER = _translate_bin_path(dir and path.join(dir, name) or name)
    end
    -- @note The link command line is set in Modules/CMake{C,CXX,Fortran}Information.cmake and defaults to using the compiler, not CMAKE_LINKER,
    -- so we need set CMAKE_CXX_LINK_EXECUTABLE to use CMAKE_LINKER as linker.
    --
    -- https://github.com/xmake-io/xmake-repo/pull/1039
    -- https://stackoverflow.com/questions/1867745/cmake-use-a-custom-linker/25274328#25274328
    envs.CMAKE_LINKER              = _translate_bin_path(package:build_getenv("ld"))
    if package:has_tool("ld", "gxx", "clangxx") then
        envs.CMAKE_CXX_LINK_EXECUTABLE = "<CMAKE_LINKER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
    end
    envs.CMAKE_RANLIB              = _translate_bin_path(package:build_getenv("ranlib"))
    envs.CMAKE_C_FLAGS             = _get_cflags(package, opt)
    envs.CMAKE_CXX_FLAGS           = _get_cxxflags(package, opt)
    envs.CMAKE_ASM_FLAGS           = _get_asflags(package, opt)
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(package:build_getenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = _get_ldflags(package, opt)
    envs.CMAKE_SHARED_LINKER_FLAGS = _get_shflags(package, opt)
    -- we need not set it as cross compilation if we just pass toolchain
    -- https://github.com/xmake-io/xmake/issues/2170
    if not package:is_plat(os.subhost()) then
        envs.CMAKE_SYSTEM_NAME     = "Linux"
    else
        if package:config("pic") ~= false then
            table.insert(configs, "-DCMAKE_POSITION_INDEPENDENT_CODE=ON")
        end
    end
    for k, v in pairs(envs) do
        table.insert(configs, "-D" .. k .. "=" .. v)
    end
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

-- get configs
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
        (package:is_plat("macosx") and not package:is_arch(os.subarch())) then
        _get_configs_for_appleos(package, configs, opt)
    elseif package:is_plat("mingw") then
        _get_configs_for_mingw(package, configs, opt)
    elseif package:is_plat("wasm") then
        _get_configs_for_wasm(package, configs, opt)
    elseif _is_cross_compilation(package) then
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
    return configs
end

-- get build environments
function buildenvs(package, opt)

    -- we need bind msvc environments manually
    -- @see https://github.com/xmake-io/xmake/issues/1057
    opt = opt or {}
    local envs = {}
    if package:is_plat("windows") then
        envs = _get_msvc_runenvs(package)
    end

    -- we need pass pkgconf for windows/mingw without msys2/cygwin
    if package:is_plat("windows", "mingw") and is_subhost("windows") then
        local pkgconf = find_tool("pkgconf")
        if pkgconf then
            envs.PKG_CONFIG = pkgconf.program
        end
    end

    -- add environments for cmake/find_packages
    local CMAKE_LIBRARY_PATH = {}
    local CMAKE_INCLUDE_PATH = {}
    local CMAKE_PREFIX_PATH  = {}
    for _, dep in ipairs(package:librarydeps()) do
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
    envs.CMAKE_LIBRARY_PATH = path.joinenv(CMAKE_LIBRARY_PATH)
    envs.CMAKE_INCLUDE_PATH = path.joinenv(CMAKE_INCLUDE_PATH)
    envs.CMAKE_PREFIX_PATH  = path.joinenv(CMAKE_PREFIX_PATH)
    return envs
end

-- do build for msvc
function _build_for_msvc(package, configs, opt)
    local jobs = _get_parallel_njobs(opt)
    local slnfile = assert(find_file("*.sln", os.curdir()), "*.sln file not found!")
    local runenvs = _get_msvc_runenvs(package)
    local msbuild = find_tool("msbuild", {envs = runenvs})
    os.vrunv(msbuild.program, {slnfile, "-nologo", "-t:Rebuild",
            (jobs ~= nil and format("-m:%d", jobs) or "-m"),
            "-p:Configuration=" .. (package:is_debug() and "Debug" or "Release"),
            "-p:Platform=" .. _get_vsarch(package)}, {envs = runenvs})
end

-- do build for make
function _build_for_make(package, configs, opt)
    local argv = {}
    if opt.target then
        table.insert(argv, opt.target)
    end
    local jobs = _get_parallel_njobs(opt)
    table.insert(argv, "-j" .. jobs)
    if option.get("diagnosis") then
        table.insert(argv, "VERBOSE=1")
    end
    if is_host("bsd") then
        os.vrunv("gmake", argv)
    elseif is_subhost("windows") and package:is_plat("mingw") then
        local mingw = assert(package:build_getenv("mingw") or package:build_getenv("sdk"), "mingw not found!")
        local mingw_make = path.join(mingw, "bin", "mingw32-make.exe")
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
    ninja.build(package, {}, {envs = opt.envs or buildenvs(package, opt)})
end

-- do build for cmake/build
function _build_for_cmakebuild(package, configs, opt)
    local cmake = assert(find_tool("cmake"), "cmake not found!")
    local argv = {"--build", os.curdir()}
    if opt.config then
        table.insert(argv, "--config")
        table.insert(argv, opt.config)
    end
    if opt.target then
        table.insert(argv, "--target")
        table.insert(argv, opt.target)
    end
    os.vrunv(cmake.program, argv, {envs = opt.envs or buildenvs(package)})
end

-- do install for msvc
function _install_for_msvc(package, configs, opt)
    local jobs = _get_parallel_njobs(opt)
    local slnfile = assert(find_file("*.sln", os.curdir()), "*.sln file not found!")
    local runenvs = _get_msvc_runenvs(package)
    local msbuild = assert(find_tool("msbuild", {envs = runenvs}), "msbuild not found!")
    os.vrunv(msbuild.program, {slnfile, "-nologo", "-t:Rebuild", "/nr:false",
        (jobs ~= nil and format("-m:%d", jobs) or "-m"),
        "-p:Configuration=" .. (package:is_debug() and "Debug" or "Release"),
        "-p:Platform=" .. _get_vsarch(package)}, {envs = runenvs})
    local projfile = os.isfile("INSTALL.vcxproj") and "INSTALL.vcxproj" or "INSTALL.vcproj"
    if os.isfile(projfile) then
        os.vrunv(msbuild.program, {projfile, "/property:configuration=" .. (package:is_debug() and "Debug" or "Release")}, {envs = runenvs})
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
        local mingw = assert(package:build_getenv("mingw") or package:build_getenv("sdk"), "mingw not found!")
        local mingw_make = path.join(mingw, "bin", "mingw32-make.exe")
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
    ninja.install(package, {}, {envs = opt.envs or buildenvs(package, opt)})
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

-- build package
function build(package, configs, opt)

    -- init options
    opt = opt or {}

    -- enter build directory
    local buildir = opt.buildir or package:buildir()
    os.mkdir(path.join(buildir, "install"))
    local oldir = os.cd(buildir)

    -- exists $CMAKE_GENERATOR? use it
    local cmake_generator_env = os.getenv("CMAKE_GENERATOR")
    if not opt.cmake_generator and cmake_generator_env then
        opt.cmake_generator = cmake_generator_env
    end

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
    table.insert(argv, oldir)

    -- do configure
    local cmake = assert(find_tool("cmake"), "cmake not found!")
    os.vrunv(cmake.program, argv, {envs = opt.envs or buildenvs(package, opt)})

    -- do build
    local cmake_generator = opt.cmake_generator
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

    -- init options
    opt = opt or {}

    -- enter build directory
    local buildir = opt.buildir or package:buildir()
    os.mkdir(path.join(buildir, "install"))
    local oldir = os.cd(buildir)

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
    table.insert(argv, oldir)

    -- generate build file
    local cmake = assert(find_tool("cmake"), "cmake not found!")
    os.vrunv(cmake.program, argv, {envs = opt.envs or buildenvs(package, opt)})

    -- do build and install
    local cmake_generator = opt.cmake_generator
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
