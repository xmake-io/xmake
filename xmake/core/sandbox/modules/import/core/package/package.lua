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
-- @file        package.lua
--

-- define module
local sandbox_core_package_package = sandbox_core_package_package or {}

-- load modules
local project    = require("project/project")
local package    = require("package/package")
local raise      = require("sandbox/modules/raise")

-- get cache directory
function sandbox_core_package_package.cachedir()
    return package.cachedir()
end

-- the install directory
function sandbox_core_package_package.installdir()
    return package.installdir()
end

-- the search directories
function sandbox_core_package_package.searchdirs()
    return package.searchdirs()
end

-- load the package from the project file
function sandbox_core_package_package.load_from_project(packagename)

    -- load package instance
    local instance, errors = package.load_from_project(packagename, project)
    if errors then
        raise(errors)
    end

    -- ok
    return instance
end

-- load the package from the system
function sandbox_core_package_package.load_from_system(packagename)

    -- load package instance
    local instance, errors = package.load_from_system(packagename)
    if errors then
        raise(errors)
    end

    -- ok
    return instance
end

-- load the package from repositories
function sandbox_core_package_package.load_from_repository(packagename, repo, packagedir, packagefile)

    -- load package instance
    local instance, errors = package.load_from_repository(packagename, repo, packagedir, packagefile)
    if not instance then
        raise(errors)
    end

    -- ok
    return instance
end

-- return module
return sandbox_core_package_package
