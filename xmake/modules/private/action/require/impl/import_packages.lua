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
-- @file        import_packages.lua
--

-- imports
import("core.package.package", {alias = "core_package"})
import("private.action.require.impl.package")

-- import packages
function main(requires, opt)
    opt = opt or {}
    local packages = {}
    local packagedir = assert(opt.packagedir)
    for _, instance in ipairs(package.load_packages(requires, opt)) do

        -- get import path
        local installdir = instance:installdir()
        local rootdir = core_package.installdir()
        local importpath, count = installdir:replace(rootdir, packagedir, {plain = true})

        -- import this package
        if importpath and count == 1 then
            print("importing %s-%s %s", instance:displayname(), instance:version_str(), package.get_configs_str(instance))
            cprint("  ${yellow}<-${clear} %s", importpath)
            os.tryrm(installdir)
            os.cp(importpath, installdir, {symlink = true})
            table.insert(packages, instance)
        end
    end
    return packages
end

