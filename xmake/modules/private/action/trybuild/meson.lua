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
-- @file        meson.lua
--

-- imports
import("core.base.cli")
import("core.base.option")
import("core.project.config")
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
function _get_configs(artifacts_dir, buildir)

    -- add prefix
    local configs = {"--prefix=" .. artifacts_dir}
    if configfile then
        table.insert(configs, "--reconfigure")
    end

    -- add extra user configs
    local tryconfigs = config.get("tryconfigs")
    if tryconfigs then
        for _, opt in ipairs(cli.parse(tryconfigs)) do
            table.insert(configs, tostring(opt))
        end
    end

    -- add build directory
    table.insert(configs, buildir)
    return configs
end

-- detect build-system and configuration file
function detect()
    return find_file("meson.build", os.curdir())
end

-- do clean
function clean()
    local buildir = _get_buildir()
    if os.isdir(buildir) then
        local configfile = find_file("build.ninja", buildir)
        if configfile then
            local ninja = assert(find_tool("ninja"), "ninja not found!")
            local ninja_argv = {"-C", buildir}
            if option.get("verbose") or option.get("diagnosis") then
                table.insert(ninja_argv, "-v")
            end
            table.insert(ninja_argv, "-t")
            table.insert(ninja_argv, "clean")
            os.vexecv(ninja.program, ninja_argv)
            if option.get("all") then
                os.tryrm(buildir)
            end
        end
    end
end

-- do build
function build()

    -- only support the current subsystem host platform now!
    assert(is_subhost(config.plat()), "meson: %s not supported!", config.plat())

    -- get artifacts directory
    local artifacts_dir = _get_artifacts_dir()
    if not os.isdir(artifacts_dir) then
        os.mkdir(artifacts_dir)
    end

    -- generate makefile
    local buildir = _get_buildir()
    local meson = assert(find_tool("meson"), "meson not found!")
    local configfile = find_file("build.ninja", buildir)
    if not configfile or os.mtime(config.filepath()) > os.mtime(configfile) then
        os.vexecv(meson.program, _get_configs(artifacts_dir, buildir))
    end

    -- do build
    local ninja = assert(find_tool("ninja"), "ninja not found!")
    local ninja_argv = {"-C", buildir}
    if option.get("verbose") then
        table.insert(ninja_argv, "-v")
    end
    table.insert(ninja_argv, "-j")
    table.insert(ninja_argv, option.get("jobs"))
    os.vexecv(ninja.program, ninja_argv)
    os.vexecv(ninja.program, table.join("install", ninja_argv))
    cprint("output to ${bright}%s", artifacts_dir)
    cprint("${color.success}build ok!")
end
