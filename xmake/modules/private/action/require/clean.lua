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
-- @file        clean.lua
--

-- imports
import("core.base.option")
import("core.package.package")
import("core.cache.localcache")
import("private.action.require.impl.remove_packages")

-- clean the given or all package caches
function main(package_names)

    -- trace
    print("clearing packages ..")

    -- clear all unused packages
    remove_packages(package_names, {clean = true})

    -- trace
    print("clearing caches ..")

    -- clear cache directory
    os.rm(package.cachedir())

    -- clear require cache
    local require_cache = localcache.cache("package")
    require_cache:clear()
    require_cache:save()
end

