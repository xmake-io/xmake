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
-- @file        uninstall_packages.lua
--

-- imports
import("core.cache.localcache")
import("private.action.require.impl.package")

-- uninstall packages
function main(requires, opt)

    -- init options
    opt = opt or {}

    -- do not remove dependent packages
    opt.nodeps = true

    -- clear the local cache
    localcache.clear()

    -- remove all packages
    local packages = {}
    for _, instance in ipairs(package.load_packages(requires, opt)) do
        if os.isfile(instance:manifest_file()) then
            table.insert(packages, instance)
        end
        os.tryrm(instance:installdir())
    end
    return packages
end

