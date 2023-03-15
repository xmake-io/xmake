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

-- is the toolchain compatible with the host?
function _is_toolchain_compatible_with_host(name)
    if is_host("linux", "macosx", "bsd") then
        if name:startswith("clang") or name:startswith("gcc") then
            return true
        end
    elseif is_host("windows") and name == "msvc" then
        return true
    end
end

-- get configs for windows
function _get_configs_for_windows(configs)
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
    elseif is_plat("macosx") then
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
    -- avoid find and add system include/library path
    envs.CMAKE_FIND_ROOT_PATH      = sdkdir
    envs.CMAKE_SYSROOT             = sdkdir
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY = "ONLY"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE = "ONLY"
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
    -- so we need set CMAKE_CXX_LINK_EXECUTABLE to use CMAKE_LINKER as linker.
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
    envs.CMAKE_FIND_ROOT_PATH_MODE_LIBRARY = "ONLY"
    envs.CMAKE_FIND_ROOT_PATH_MODE_INCLUDE = "ONLY"
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
    -- so we need set CMAKE_CXX_LINK_EXECUTABLE to use CMAKE_LINKER as linker.
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
    -- we need not set it as cross compilation if we just pass toolchain
    -- https://github.com/xmake-io/xmake/issues/2170
    if not is_plat(os.subhost()) then
        envs.CMAKE_SYSTEM_NAME     = "Linux"
    end
    for k, v in pairs(envs) do
        table.insert(configs, "-D" .. k .. "=" .. v)
    end
end

-- get configs
function _get_configs(artifacts_dir)

    -- add prefix
    local configs = {"-DCMAKE_INSTALL_PREFIX=" .. artifacts_dir, "-DCMAKE_INSTALL_LIBDIR=" .. path.join(artifacts_dir, "lib")}
    if is_plat("windows") then
        _get_configs_for_windows(configs)
    elseif is_plat("android") then
        _get_configs_for_android(configs)
    elseif is_plat("iphoneos", "watchos") or
        -- for cross-compilation on macOS, @see https://github.com/xmake-io/xmake/issues/2804
        (is_plat("macosx") and not is_arch(os.subarch())) then
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
        if _is_toolchain_compatible_with_host(config.get("toolchain")) then
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
        for _, opt in ipairs(os.argv(tryconfigs)) do
            table.insert(configs, tostring(opt))
        end
    end

    -- add build directory
    table.insert(configs, '..')
    return configs
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
                local runenvs = toolchain.load("msvc"):runenvs()
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

    -- get artifacts directory
    local artifacts_dir = _get_artifacts_dir()
    if not os.isdir(artifacts_dir) then
        os.mkdir(artifacts_dir)
    end
    os.cd(_get_buildir())

    -- generate makefile
    local cmake = assert(find_tool("cmake"), "cmake not found!")
    local configfile = find_file("[mM]akefile", os.curdir()) or (is_plat("windows") and find_file("*.sln", os.curdir()))
    if not configfile or os.mtime(config.filepath()) > os.mtime(configfile) then
        os.vexecv(cmake.program, _get_configs(artifacts_dir))
    end

    -- do build
    if is_plat("windows") then
        local runenvs = toolchain.load("msvc"):runenvs()
        local msbuild = find_tool("msbuild", {envs = runenvs})
        local slnfile = assert(find_file("*.sln", os.curdir()), "*.sln file not found!")
        os.vexecv(msbuild.program, {slnfile, "-nologo", "-t:Build", "-m", "-p:Configuration=" .. (is_mode("debug") and "Debug" or "Release"), "-p:Platform=" .. (is_arch("x64") and "x64" or "Win32")}, {envs = runenvs})
        local projfile = os.isfile("INSTALL.vcxproj") and "INSTALL.vcxproj" or "INSTALL.vcproj"
        if os.isfile(projfile) then
            os.vexecv(msbuild.program, {projfile, "/property:configuration=" .. (is_mode("debug") and "Debug" or "Release")}, {envs = runenvs})
        end
    else
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
    cprint("output to ${bright}%s", artifacts_dir)
    cprint("${color.success}build ok!")
end
