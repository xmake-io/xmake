--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        package.lua
--

-- define module
local sandbox_core_package_package = sandbox_core_package_package or {}

-- load modules
local package    = require("package/package")
local raise      = require("sandbox/modules/raise")

-- get cache directory
function sandbox_core_package_package.cachedir()
    return package.cachedir()
end

-- get install directory
function sandbox_core_package_package.installdir(is_global)
    return package.installdir(is_global)
end

-- load the package from the project file 
function sandbox_core_package_package.load_from_project(packagename)

    -- load package instance 
    local instance, errors = package.load_from_project(packagename) 
    if errors then
        raise(errors)
    end

    -- ok
    return instance
end

-- load the package from repositories
function sandbox_core_package_package.load_from_repository(packagename, is_global, packagedir, packagefile)

    -- load package instance
    local instance, errors = package.load_from_repository(packagename, is_global, packagedir, packagefile) 
    if not instance then
        raise(errors)
    end

    -- ok
    return instance
end

-- load the package from the package url 
function sandbox_core_package_package.load_from_url(packagename, packageurl)

    -- load package instance 
    local instance, errors = package.load_from_url(packagename, packageurl) 
    if not instance then
        raise(errors)
    end

    -- ok
    return instance
end

-- return module
return sandbox_core_package_package
