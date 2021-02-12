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
-- @file        export_packages.lua
--

-- imports
import("private.action.require.impl.package")

-- export packages
function main(requires, opt)

    -- init options
    opt = opt or {}

    -- get the export directory
    local exportdir = assert(opt.exportdir)

    -- export all packages
    local packages = {}
    for _, instance in ipairs(package.load_packages(requires, opt)) do

        -- get the exported name
        local name = instance:name():lower():gsub("::", "_")
        if instance:version_str() then
            name = name .. "_" .. instance:version_str()
        end
        name = name .. "_" .. instance:buildhash()

        -- export this package
        if instance:fetch() then
            os.cp(instance:installdir(), path.join(exportdir, name))
            table.insert(packages, instance)
        end
    end
    return packages
end

