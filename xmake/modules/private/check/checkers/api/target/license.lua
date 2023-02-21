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
-- @file        check_licenses.lua
--

-- imports
import("core.project.project")
import("core.base.license")
import("private.check.checker")

-- show info
function _show(str)
    cprint("${color.warning}${text.warning}${clear}: %s", str)
end

-- check licenses
function _check_licenses_for_package(target, package, opt)
    opt = opt or {}
    local target_license  = target:license()
    local package_license = package:license()
    local package_kind    = package:has_shared() and "shared"
    local ok, errors = license.compatible(target_license, package_license, {library_kind = package_kind})
    if not ok then
        errors = errors or "you can use set_license()/set_policy() to modify/disable license"
        if target_license then
            errors = string.format("license(%s) of target(%s) is not compatible with license(%s) of package(%s)\n%s!", target_license, target:name(), package_license, package:name(), errors)
        else
            errors = string.format("target(%s) maybe is not compatible with license(%s) of package(%s), \n%s!", target:name(), package_license, package:name(), errors)
        end
        (opt.show or _show)(errors)
        checker.update_stats("warning")
    end
end

-- check licenses for all dependent packages
--
-- @see https://github.com/xmake-io/xmake/issues/1016
--
function _check_licenses_for_target(target, opt)
    if target:policy("check.target_package_licenses") then
        for _, pkg in ipairs(target:orderpkgs()) do
            if pkg:license() then
                _check_licenses_for_package(target, pkg, opt)
            end
        end
    end
end

function main(opt)
    opt = opt or {}
    local target = opt.target
    if target then
        _check_licenses_for_target(target, opt)
    else
        for _, target in pairs(project.targets()) do
            _check_licenses_for_target(target, opt)
        end
    end
end
