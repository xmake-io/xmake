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
                packagename = packagename:sub(1, #packagename - 1)
            end
        end
    end
    packagename = packagename:trim()
    if #packagename == 0 then
        return
    end

    -- search packages
    -- TODO search the given version
    local result
    for name, packages in pairs(search_packages(packagename)) do
        if #packages > 0 then
            local package = packages[1]
            _g.package = package
            return ("%s %s in %s"):format(package.name, package.version, package.reponame)
        end
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
    local argv = {"install", "-v"}
    if option.get("diagnosis") then
        table.insert(argv, "-D")
    end
    table.insert(argv, "-d")
    table.insert(argv, ".")
    table.insert(argv, package.name .. " " .. package.version)
    os.vexecv(xrepo.program, argv)

    -- do export
    local artifacts_dir = _get_artifacts_dir()
    local argv = {"export", "-v", "--shallow"}
    if option.get("diagnosis") then
        table.insert(argv, "-D")
    end
    table.insert(argv, "-o")
    table.insert(argv, artifacts_dir)
    table.insert(argv, package.name .. " " .. package.version)
    os.vexecv(xrepo.program, argv)
    cprint("output to ${bright}%s", artifacts_dir)
    cprint("${color.success}build ok!")
end
