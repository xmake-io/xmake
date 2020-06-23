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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        cmake.lua
--

-- imports
import("core.base.cli")
import("core.base.option")
import("core.project.config")
import("core.tool.toolchain")
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

-- get configs
function _get_configs(artifacts_dir)

    -- add prefix
    local configs = {"-DCMAKE_INSTALL_PREFIX=" .. artifacts_dir, "-DCMAKE_INSTALL_LIBDIR=" .. path.join(artifacts_dir, "lib")}
    if is_plat("windows") and is_arch("x64") then
        table.insert(configs, "-A")
        table.insert(configs, "x64")
    end

    -- enable verbose?
    if option.get("verbose") then
        table.insert(configs, "-DCMAKE_VERBOSE_MAKEFILE=ON")
    end

    -- add extra user configs 
    local tryconfigs = config.get("tryconfigs")
    if tryconfigs then
        for _, opt in ipairs(cli.parse(tryconfigs)) do
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

    -- only support the current subsystem host platform now!
    assert(is_subhost(config.plat()), "cmake: %s not supported!", config.plat())

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
        os.vexecv(msbuild.program, {slnfile, "-nologo", "-t:Build", "-p:Configuration=" .. (is_mode("debug") and "Debug" or "Release"), "-p:Platform=" .. (is_arch("x64") and "x64" or "Win32")}, {envs = runenvs})
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
