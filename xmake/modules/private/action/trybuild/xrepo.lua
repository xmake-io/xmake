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
-- @file        xrepo.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.project.config")
import("lib.detect.find_file")
import("lib.detect.find_tool")
import("private.action.require.impl.search_packages")

-- get build directory
function _get_buildir()
    return config.buildir() or "build"
end

-- get artifacts directory
function _get_artifacts_dir()
    return path.absolute(path.join(_get_buildir(), "artifacts"))
end

-- detect build-system and configuration file
function detect()

    -- we need xrepo
    local xrepo = find_tool("xrepo")
    if not xrepo then
        return
    end

    -- get package name and version
    local dirname = path.filename(os.curdir())
    local packagename = dirname
    local version = semver.match(dirname)
    if version then
        local pos = dirname:find(version:rawstr(), 1, true)
        if pos then
            packagename = dirname:sub(1, pos - 1)
            if packagename:endswith("-") or packagename:endswith("_") then
                packagename = packagename:sub(1, #packagename - 1):lower()
            end
        end
    end
    packagename = packagename:trim()
    if #packagename == 0 then
        return
    end

    -- search packages
    local result
    local packages_found = search_packages(packagename, {require_version = version and version:rawstr() or nil})
    for name, packages in pairs(packages_found) do
        for _, package in ipairs(packages) do
            if package.name == packagename then
                result = package
                break
            end
        end
    end
    if not result then
        for name, packages in pairs(packages_found) do
            if #packages > 0 then
                result = packages[1]
            end
        end
    end
    if result then
        _g.package = result
        if result.version then
            return ("%s %s in %s"):format(result.name, result.version, result.reponame)
        else
            return ("%s in %s"):format(result.name, result.reponame)
        end
    end
end

-- get common configs
function _get_common_configs(argv)
    table.insert(argv, "-y")
    table.insert(argv, "--shallow")
    table.insert(argv, "-v")
    if option.get("diagnosis") then
        table.insert(argv, "-D")
    end
    if config.get("plat") then
        table.insert(argv, "-p")
        table.insert(argv, config.get("plat"))
    end
    if config.get("arch") then
        table.insert(argv, "-a")
        table.insert(argv, config.get("arch"))
    end
    if config.get("mode") then
        table.insert(argv, "-m")
        table.insert(argv, config.get("mode"))
    end
    if config.get("kind") then
        table.insert(argv, "-k")
        table.insert(argv, config.get("kind"))
    end
    if config.get("toolchain") then
        table.insert(argv, "--toolchain=" .. config.get("toolchain"))
    end
    if config.get("vs_runtime") then
        table.insert(argv, "-f")
        table.insert(argv, "vs_runtime='" .. config.get("vs_runtime") .. "'")
    end
end

-- get install configs
function _get_install_configs(argv)

    -- pass jobs
    if option.get("jobs") then
        table.insert(argv, "-j")
        table.insert(argv, option.get("jobs"))
    end

    -- cross compilation
    if config.get("sdk") then
        table.insert(argv, "--sdk=" .. config.get("sdk"))
    end

    -- android
    if config.get("ndk") then
        table.insert(argv, "--ndk=" .. config.get("ndk"))
    end

    -- mingw
    if config.get("mingw") then
        table.insert(argv, "--mingw=" .. config.get("mingw"))
    end

    -- msvc
    if config.get("vs") then
        table.insert(argv, "--vs=" .. config.get("vs"))
    end
    if config.get("vs_toolset") then
        table.insert(argv, "--vs_toolset=" .. config.get("vs_toolset"))
    end
    if config.get("vs_sdkver") then
        table.insert(argv, "--vs_sdkver=" .. config.get("vs_sdkver"))
    end

    -- xcode
    if config.get("xcode") then
        table.insert(argv, "--xcode=" .. config.get("xcode"))
    end
    if config.get("xcode_sdkver") then
        table.insert(argv, "--xcode_sdkver=" .. config.get("xcode_sdkver"))
    end
    if config.get("target_minver") then
        table.insert(argv, "--target_minver=" .. config.get("target_minver"))
    end
    if config.get("appledev") then
        table.insert(argv, "--appledev=" .. config.get("appledev"))
    end
end

-- do clean
function clean()
end

-- do build
function build()

    -- get xrepo
    local xrepo = assert(find_tool("xrepo"), "xrepo not found!")

    -- get package info
    local package = assert(_g.package, "package not found!")

    -- do install for building
    local argv = {"install"}
    _get_common_configs(argv)
    _get_install_configs(argv)
    table.insert(argv, "-d")
    table.insert(argv, ".")
    if package.version then
        table.insert(argv, package.name .. " " .. package.version)
    else
        table.insert(argv, package.name)
    end
    os.vexecv(xrepo.program, argv)

    -- do export
    local artifacts_dir = _get_artifacts_dir()
    local argv = {"export"}
    _get_common_configs(argv)
    table.insert(argv, "-o")
    table.insert(argv, artifacts_dir)
    if package.version then
        table.insert(argv, package.name .. " " .. package.version)
    else
        table.insert(argv, package.name)
    end
    os.vexecv(xrepo.program, argv)
    cprint("output to ${bright}%s", artifacts_dir)
    cprint("${color.success}build ok!")
end
