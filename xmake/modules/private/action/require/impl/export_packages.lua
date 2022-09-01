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
import("core.package.package", {alias = "core_package"})
import("private.action.require.impl.package")

-- export packages
function main(requires, opt)
    opt = opt or {}
    local packages = {}
    local packagedir = assert(opt.packagedir)
    for _, instance in ipairs(package.load_packages(requires, opt)) do

        -- get export path
        local installdir = instance:installdir()
        local rootdir = core_package.installdir()
        local exportpath, count = installdir:replace(rootdir, packagedir, {plain = true})

        -- export this package
        if exportpath and count == 1 and instance:fetch({force = true}) then
            print("exporting %s-%s %s", instance:displayname(), instance:version_str(), package.get_configs_str(instance))
            cprint("  ${yellow}->${clear} %s", exportpath)
            os.cp(installdir, exportpath, {symlink = true})
            os.tryrm(path.join(exportpath, "references.txt"))
            table.insert(packages, instance)
        end
    end
    return packages
end

