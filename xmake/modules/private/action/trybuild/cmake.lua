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
import("core.project.config")
import("core.tool.toolchain")
import("core.platform.platform")
import("lib.detect.find_file")
import("lib.detect.find_tool")
import("private.utils.toolchain", {alias = "toolchain_utils"})

-- get build directory
function _get_buildir()
    return config.buildir() or "build"
end

-- get artifacts directory
function _get_artifacts_dir()
    return path.absolute(path.join(_get_buildir(), "artifacts"))
end

-- get the build environment
function _get_buildenv(key)
    local value = config.get(key)
    if value == nil then
        value = platform.toolconfig(key, config.plat())
    end
    if value == nil then
        value = platform.tool(key, config.plat())
    end
    return value
end

-- get vs arch
function _get_vsarch()
    local arch = get_config("arch") or os.arch()
    if arch == "x86" or arch == "i386" then return "Win32" end
    if arch == "x86_64" then return "x64" end
    if arch == "arm64ec" then return "ARM64EC" end
    if arch:startswith("arm64") then return "ARM64" end
    if arch:startswith("arm") then return "ARM" end
    return arch
end

-- get msvc
function _get_msvc()
    local msvc = toolchain.load("msvc")
    assert(msvc:check(), "vs not found!") -- we need to check vs envs if it has been not checked yet
    return msvc
end

-- get msvc run environments
function _get_msvc_runenvs()
    return os.joinenvs(_get_msvc():runenvs())
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

-- is cross compilation?
function _is_cross_compilation()
    if not is_plat(os.subhost()) then
        return true
    end
    if is_plat("macosx") and not is_arch(os.subarch()) then
        return true
    end
    return false
end

function _get_cmake_system_processor()
    -- on Windows, CMAKE_SYSTEM_PROCESSOR comes from PROCESSOR_ARCHITECTURE
    -- on other systems it's the output of uname -m
    if is_plat("windows") then
        local archs = {
            x86 = "x86",
            x64 = "AMD64",
            x86_64 = "AMD64",
            arm = "ARM",
            arm64 = "ARM64",
            arm64ec = "ARM64EC"
        }
        return archs[os.subarch()] or os.subarch()
    end
    return os.subarch()
end

-- get configs for windows
function _get_configs_for_windows(configs, opt)
    opt = opt or {}
    local cmake_generator = opt.cmake_generator
    if cmake_generator and not cmake_generator:find("Visual Studio", 1, true) then
        return
    end
    table.insert(configs, "-A")
    if is_arch("x86", "i386") then
        table.insert(configs, "Win32")
    else
        table.insert(configs, "x64")
    end
end

-- get configs for android
function _get_configs_for_android(configs)
    -- https://developer.android.google.cn/ndk/guides/cmake
    local ndk = config.get("ndk")
    if ndk and os.isdir(ndk) then
        local arch = config.arch()
        local ndk_sdkver = config.get("ndk_sdkver")
        local ndk_cxxstl = config.get("ndk_cxxstl")
        table.insert(configs, "-DCMAKE_TOOLCHAIN_FILE=" .. path.join(ndk, "build/cmake/android.toolchain.cmake"))
        if arch then
            table.insert(configs, "-DANDROID_ABI=" .. arch)
        end
        if ndk_sdkver then
            table.insert(configs,  "-DANDROID_NATIVE_API_LEVEL=" .. ndk_sdkver)
        end
        if ndk_cxxstl then
            table.insert(configs, "-DANDROID_STL=" .. ndk_cxxstl)
        end

        -- avoid find and add system include/library path
        -- @see https://github.com/xmake-io/xmake/issues/2037
        table.insert(configs, "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH")
        table.insert(configs, "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH")
        table.insert(configs, "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH")
        table.insert(configs, "-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER")
    end
end

-- get configs for appleos
function _get_configs_for_appleos(configs)
    local envs                     = {}
    local cflags                   = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cflags"))
    local cxxflags                 = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cxxflags"))
    envs.CMAKE_C_FLAGS             = table.concat(cflags, ' ')
    envs.CMAKE_CXX_FLAGS           = table.concat(cxxflags, ' ')
    envs.CMAKE_ASM_FLAGS           = table.concat(table.wrap(_get_buildenv("asflags")), ' ')
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(_get_buildenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = table.concat(table.wrap(_get_buildenv("ldflags")), ' ')
    envs.CMAKE_SHARED_LINKER_FLAGS = table.concat(table.wrap(_get_buildenv("shflags")), ' ')
    -- https://cmake.org/cmake/help/v3.17/manual/cmake-toolchains.7.html#id25
    if is_plat("watchos") then
        envs.CMAKE_SYSTEM_NAME = "watchOS"
        if is_arch("x86_64", "i386") then
            envs.CMAKE_OSX_SYSROOT = "watchsimulator"
        end
    elseif is_plat("iphoneos") then
        envs.CMAKE_SYSTEM_NAME = "iOS"
        if is_arch("x86_64", "i386") then
            envs.CMAKE_OSX_SYSROOT = "iphonesimulator"
        end
    elseif _is_cross_compilation() then
        envs.CMAKE_SYSTEM_NAME = "Darwin"
        envs.CMAKE_SYSTEM_PROCESSOR = _get_cmake_system_processor()
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
function _get_configs_for_mingw(configs)
    local envs                     = {}
    local cflags                   = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cflags"))
    local cxxflags                 = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cxxflags"))
    local sdkdir                   = _get_buildenv("mingw") or _get_buildenv("sdk")
    envs.CMAKE_C_COMPILER          = _get_buildenv("cc")
    envs.CMAKE_CXX_COMPILER        = _get_buildenv("cxx")
    envs.CMAKE_ASM_COMPILER        = _get_buildenv("as")
    envs.CMAKE_AR                  = _get_buildenv("ar")
    envs.CMAKE_LINKER              = _get_buildenv("ld")
    envs.CMAKE_RANLIB              = _get_buildenv("ranlib")
    envs.CMAKE_C_FLAGS             = table.concat(cflags, ' ')
    envs.CMAKE_CXX_FLAGS           = table.concat(cxxflags, ' ')
    envs.CMAKE_ASM_FLAGS           = table.concat(table.wrap(_get_buildenv("asflags")), ' ')
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(_get_buildenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = table.concat(table.wrap(_get_buildenv("ldflags")), ' ')
    envs.CMAKE_SHARED_LINKER_FLAGS = table.concat(table.wrap(_get_buildenv("shflags")), ' ')
    envs.CMAKE_SYSTEM_NAME         = "Windows"
    envs.CMAKE_SYSTEM_PROCESSOR    = _get_cmake_system_processor()
    -- avoid find and add system include/library path
    envs.CMAKE_FIND_ROOT_PATH      = sdkdir
    envs.CMAKE_SYSROOT             = sdkdir
    envs.CMAKE_FIND_ROOT_PATH_MODE_PACKAGE = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_PROGRAM = "NEVER"
    -- avoid add -isysroot on macOS
    envs.CMAKE_OSX_SYSROOT = ""
    -- Avoid cmake to add the flags -search_paths_first and -headerpad_max_install_names on macOS
    envs.HAVE_FLAG_SEARCH_PATHS_FIRST = "0"
    for k, v in pairs(envs) do
        table.insert(configs, "-D" .. k .. "=" .. v)
    end
end

-- get configs for wasm
function _get_configs_for_wasm(configs)
    local emsdk = find_emsdk()
    assert(emsdk and emsdk.emscripten, "emscripten not found!")
    local emscripten_cmakefile = find_file("Emscripten.cmake", path.join(emsdk.emscripten, "cmake/Modules/Platform"))
    assert(emscripten_cmakefile, "Emscripten.cmake not found!")
    table.insert(configs, "-DCMAKE_TOOLCHAIN_FILE=" .. emscripten_cmakefile)
    assert(emscripten_cmakefile, "Emscripten.cmake not found!")
    _get_configs_for_generic(configs)
end

-- get configs for cross
function _get_configs_for_cross(configs)
    local envs                     = {}
    local cflags                   = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cflags"))
    local cxxflags                 = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cxxflags"))
    local sdkdir                   = _translate_paths(_get_buildenv("sdk"))
    envs.CMAKE_C_COMPILER          = _translate_bin_path(_get_buildenv("cc"))
    envs.CMAKE_CXX_COMPILER        = _translate_bin_path(_get_buildenv("cxx"))
    envs.CMAKE_ASM_COMPILER        = _translate_bin_path(_get_buildenv("as"))
    envs.CMAKE_AR                  = _translate_bin_path(_get_buildenv("ar"))
    -- https://github.com/xmake-io/xmake-repo/pull/1096
    local cxx = envs.CMAKE_CXX_COMPILER
    if cxx and (cxx:find("clang", 1, true) or cxx:find("gcc", 1, true)) then
        local dir = path.directory(cxx)
        local name = path.filename(cxx)
        name = name:gsub("clang$", "clang++")
        name = name:gsub("clang%-", "clang++-")
        name = name:gsub("gcc$", "g++")
        name = name:gsub("gcc%-", "g++-")
        envs.CMAKE_CXX_COMPILER = _translate_bin_path(dir and path.join(dir, name) or name)
    end
    -- @note The link command line is set in Modules/CMake{C,CXX,Fortran}Information.cmake and defaults to using the compiler, not CMAKE_LINKER,
    -- so we need to set CMAKE_CXX_LINK_EXECUTABLE to use CMAKE_LINKER as linker.
    --
    -- https://github.com/xmake-io/xmake-repo/pull/1039
    -- https://stackoverflow.com/questions/1867745/cmake-use-a-custom-linker/25274328#25274328
    envs.CMAKE_LINKER              = _translate_bin_path(_get_buildenv("ld"))
    local ld = envs.CMAKE_LINKER
    if ld and (ld:find("g++", 1, true) or ld:find("clang++", 1, true)) then
        envs.CMAKE_CXX_LINK_EXECUTABLE = "<CMAKE_LINKER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
    end
    envs.CMAKE_RANLIB              = _translate_bin_path(_get_buildenv("ranlib"))
    envs.CMAKE_C_FLAGS             = table.concat(cflags, ' ')
    envs.CMAKE_CXX_FLAGS           = table.concat(cxxflags, ' ')
    envs.CMAKE_ASM_FLAGS           = table.concat(table.wrap(_get_buildenv("asflags")), ' ')
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(_get_buildenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = table.concat(table.wrap(_get_buildenv("ldflags")), ' ')
    envs.CMAKE_SHARED_LINKER_FLAGS = table.concat(table.wrap(_get_buildenv("shflags")), ' ')
    envs.CMAKE_SYSTEM_NAME         = "Linux"
    -- avoid find and add system include/library path
    envs.CMAKE_FIND_ROOT_PATH      = sdkdir
    envs.CMAKE_SYSROOT             = sdkdir
    envs.CMAKE_FIND_ROOT_PATH_MODE_PACKAGE = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE = "BOTH"
    envs.CMAKE_FIND_ROOT_PATH_MODE_PROGRAM = "NEVER"
    -- avoid add -isysroot on macOS
    envs.CMAKE_OSX_SYSROOT = ""
    -- Avoid cmake to add the flags -search_paths_first and -headerpad_max_install_names on macOS
    envs.HAVE_FLAG_SEARCH_PATHS_FIRST = "0"
    for k, v in pairs(envs) do
        table.insert(configs, "-D" .. k .. "=" .. v)
    end
end

-- get configs for host toolchain
function _get_configs_for_host_toolchain(configs)
    local envs                     = {}
    local cflags                   = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cflags"))
    local cxxflags                 = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cxxflags"))
    local sdkdir                   = _translate_paths(_get_buildenv("sdk"))
    envs.CMAKE_C_COMPILER          = _translate_bin_path(_get_buildenv("cc"))
    envs.CMAKE_CXX_COMPILER        = _translate_bin_path(_get_buildenv("cxx"))
    envs.CMAKE_ASM_COMPILER        = _translate_bin_path(_get_buildenv("as"))
    envs.CMAKE_AR                  = _translate_bin_path(_get_buildenv("ar"))
    -- https://github.com/xmake-io/xmake-repo/pull/1096
    local cxx = envs.CMAKE_CXX_COMPILER
    if cxx and (cxx:find("clang", 1, true) or cxx:find("gcc", 1, true)) then
        local dir = path.directory(cxx)
        local name = path.filename(cxx)
        name = name:gsub("clang$", "clang++")
        name = name:gsub("clang%-", "clang++-")
        name = name:gsub("gcc$", "g++")
        name = name:gsub("gcc%-", "g++-")
        envs.CMAKE_CXX_COMPILER = _translate_bin_path(dir and path.join(dir, name) or name)
    end
    -- @note The link command line is set in Modules/CMake{C,CXX,Fortran}Information.cmake and defaults to using the compiler, not CMAKE_LINKER,
    -- so we need to set CMAKE_CXX_LINK_EXECUTABLE to use CMAKE_LINKER as linker.
    --
    -- https://github.com/xmake-io/xmake-repo/pull/1039
    -- https://stackoverflow.com/questions/1867745/cmake-use-a-custom-linker/25274328#25274328
    envs.CMAKE_LINKER              = _translate_bin_path(_get_buildenv("ld"))
    local ld = envs.CMAKE_LINKER
    if ld and (ld:find("g++", 1, true) or ld:find("clang++", 1, true)) then
        envs.CMAKE_CXX_LINK_EXECUTABLE = "<CMAKE_LINKER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
    end
    envs.CMAKE_RANLIB              = _translate_bin_path(_get_buildenv("ranlib"))
    envs.CMAKE_C_FLAGS             = table.concat(cflags, ' ')
    envs.CMAKE_CXX_FLAGS           = table.concat(cxxflags, ' ')
    envs.CMAKE_ASM_FLAGS           = table.concat(table.wrap(_get_buildenv("asflags")), ' ')
    envs.CMAKE_STATIC_LINKER_FLAGS = table.concat(table.wrap(_get_buildenv("arflags")), ' ')
    envs.CMAKE_EXE_LINKER_FLAGS    = table.concat(table.wrap(_get_buildenv("ldflags")), ' ')
    envs.CMAKE_SHARED_LINKER_FLAGS = table.concat(table.wrap(_get_buildenv("shflags")), ' ')
    -- we don't need to set it as cross compilation if we just pass toolchain
    -- https://github.com/xmake-io/xmake/issues/2170
    if _is_cross_compilation() then
        envs.CMAKE_SYSTEM_NAME = "Linux"
    end
    for k, v in pairs(envs) do
        table.insert(configs, "-D" .. k .. "=" .. v)
    end
end

-- get cmake generator for msvc
function _get_cmake_generator_for_msvc()
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
    local vs = _get_msvc():config("vs") or config.get("vs")
    assert(vsvers[vs], "Unknown Visual Studio version: '" .. tostring(vs) .. "' set in project.")
    return "Visual Studio " .. vsvers[vs] .. " " .. vs
end

-- get configs for cmake generator
function _get_configs_for_generator(configs, opt)
    opt     = opt or {}
    configs = configs or {}
    local cmake_generator = opt.cmake_generator
    if cmake_generator then
        if cmake_generator:find("Visual Studio", 1, true) then
            cmake_generator = _get_cmake_generator_for_msvc()
        end
        table.insert(configs, "-G")
        table.insert(configs, cmake_generator)
    elseif is_plat("mingw") and is_subhost("msys") then
        table.insert(configs, "-G")
        table.insert(configs, "MSYS Makefiles")
    elseif is_plat("mingw") and is_subhost("windows") then
        table.insert(configs, "-G")
        table.insert(configs, "MinGW Makefiles")
    elseif is_plat("windows") then
        table.insert(configs, "-G")
        table.insert(configs, _get_cmake_generator_for_msvc())
    elseif is_plat("wasm") and is_subhost("windows") then
        table.insert(configs, "-G")
        table.insert(configs, "MinGW Makefiles")
    else
        table.insert(configs, "-G")
        table.insert(configs, "Unix Makefiles")
    end
end

-- get configs for installation
function _get_configs_for_install(configs, opt)
    -- @see https://cmake.org/cmake/help/v3.14/module/GNUInstallDirs.html
    -- LIBDIR: object code libraries (lib or lib64 or lib/<multiarch-tuple> on Debian)
    --
    table.insert(configs, "-DCMAKE_INSTALL_PREFIX=" .. opt.artifacts_dir)
    table.insert(configs, "-DCMAKE_INSTALL_LIBDIR:PATH=lib")
end

-- get configs
function _get_configs(opt)
    local configs = {}
    _get_configs_for_install(configs, opt)
    _get_configs_for_generator(configs, opt)
    if is_plat("windows") then
        _get_configs_for_windows(configs, opt)
    elseif is_plat("android") then
        _get_configs_for_android(configs)
    elseif is_plat("iphoneos", "watchos") or
        -- for cross-compilation on macOS, @see https://github.com/xmake-io/xmake/issues/2804
        (is_plat("macosx") and (get_config("appledev") or not is_arch(os.subarch()))) then
        _get_configs_for_appleos(configs)
    elseif is_plat("mingw") then
        _get_configs_for_mingw(configs)
    elseif is_plat("wasm") then
        _get_configs_for_wasm(configs)
    elseif _is_cross_compilation() then
        _get_configs_for_cross(configs)
    elseif config.get("toolchain") then
        -- we still need find system libraries,
        -- it just pass toolchain environments if the toolchain is compatible with host
        if toolchain_utils.is_compatible_with_host(config.get("toolchain")) then
            _get_configs_for_host_toolchain(configs)
        else
            _get_configs_for_cross(configs)
        end
    end

    -- enable verbose?
    if option.get("verbose") then
        table.insert(configs, "-DCMAKE_VERBOSE_MAKEFILE=ON")
    end

    -- add extra user configs
    local tryconfigs = config.get("tryconfigs")
    if tryconfigs then
        for _, item in ipairs(os.argv(tryconfigs)) do
            table.insert(configs, tostring(item))
        end
    end

    -- add build directory
    table.insert(configs, '..')
    return configs
end

-- build for msvc
function _build_for_msvc(opt)
    local runenvs = _get_msvc_runenvs()
    local msbuild = find_tool("msbuild", {envs = runenvs})
    local slnfile = assert(find_file("*.sln", os.curdir()), "*.sln file not found!")
    os.vexecv(msbuild.program, {slnfile, "-nologo", "-t:Build", "-m",
        "-p:Configuration=" .. (is_mode("debug") and "Debug" or "Release"),
        "-p:Platform=" .. _get_vsarch()}, {envs = runenvs})
    local projfile = os.isfile("INSTALL.vcxproj") and "INSTALL.vcxproj" or "INSTALL.vcproj"
    if os.isfile(projfile) then
        os.vexecv(msbuild.program, {projfile, "/property:configuration=" .. (is_mode("debug") and "Debug" or "Release")}, {envs = runenvs})
    end
end

-- build for make
function _build_for_make(opt)
    local argv = {"-j" .. option.get("jobs")}
    if option.get("verbose") then
        table.insert(argv, "VERBOSE=1")
    end
    if is_host("bsd") then
        os.vexecv("gmake", argv)
        os.vexecv("gmake", {"install"})
    else
        os.vexecv("make", argv)
        os.vexecv("make", {"install"})
    end
end

-- build for ninja
function _build_for_ninja(opt)
    local njob = option.get("jobs") or tostring(os.default_njob())
    local ninja = assert(find_tool("ninja"), "ninja not found!")
    local argv = {}
    if option.get("diagnosis") then
        table.insert(argv, "-v")
    end
    table.insert(argv, "-j")
    table.insert(argv, njob)
    local envs
    if is_plat("windows") then
        envs = _get_msvc_runenvs()
    end
    os.vexecv(ninja.program, argv, {envs = envs})
end

-- detect build-system and configuration file
function detect()
    return find_file("CMakeLists.txt", os.curdir())
end

-- do clean
function clean()
    local buildir = _get_buildir()
    if os.isdir(buildir) then
        local configfile = find_file("[mM]akefile", buildir) or (is_plat("windows") and find_file("*.sln", buildir))
        if configfile then
            local oldir = os.cd(buildir)
            if is_plat("windows") then
                local runenvs = _get_msvc_runenvs()
                local msbuild = find_tool("msbuild", {envs = runenvs})
                os.vexecv(msbuild.program, {configfile, "-nologo", "-t:Clean", "-p:Configuration=" .. (is_mode("debug") and "Debug" or "Release"), "-p:Platform=" .. (is_arch("x64") and "x64" or "Win32")}, {envs = runenvs})
            else
                os.vexec("make clean")
            end
            os.cd(oldir)
        end
    end
end

-- do build
function build()

    -- get cmake
    local cmake = assert(find_tool("cmake"), "cmake not found!")

    -- get artifacts directory
    local opt = {}
    local artifacts_dir = _get_artifacts_dir()
    if not os.isdir(artifacts_dir) then
        os.mkdir(artifacts_dir)
    end
    os.cd(_get_buildir())
    opt.artifacts_dir = artifacts_dir

    -- exists $CMAKE_GENERATOR? use it
    opt.cmake_generator = os.getenv("CMAKE_GENERATOR")

    -- do configure
    os.vexecv(cmake.program, _get_configs(opt))

    -- do build
    local cmake_generator = opt.cmake_generator
    if cmake_generator then
        if cmake_generator:find("Visual Studio", 1, true) then
            _build_for_msvc(opt)
        elseif cmake_generator == "Ninja" then
            _build_for_ninja(opt)
        elseif cmake_generator:find("Makefiles", 1, true) then
            _build_for_make(opt)
        else
            raise("unknown cmake generator(%s)!", cmake_generator)
        end
    else
        if is_plat("windows") then
            _build_for_msvc(opt)
        else
            _build_for_make(opt)
        end
    end

    cprint("output to ${bright}%s", artifacts_dir)
    cprint("${color.success}build ok!")
end
