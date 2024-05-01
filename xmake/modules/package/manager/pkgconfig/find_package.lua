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
-- @file        find_package.lua
--

-- imports
import("lib.detect.pkgconfig")
import("private.core.base.is_cross")
import("package.manager.system.find_package", {alias = "find_package_from_system"})

-- find package from the pkg-config package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)
    opt = opt or {}
    if is_cross(opt.plat, opt.arch) then
        return
    end

    -- get library info
    local libinfo = pkgconfig.libinfo(name, opt)
    if not libinfo and name:startswith("lib") then
        -- libxxx? attempt to find xxx without `lib` prefix
        libinfo = pkgconfig.libinfo(name:sub(4), opt)
    end
    if not libinfo then
        return
    end

    -- no linkdirs in pkg-config? attempt to find it from system directories
    if libinfo.links and not libinfo.linkdirs then
        local libinfo_sys = find_package_from_system(name, table.join(opt, {links = libinfo.links}))
        if libinfo_sys then
            libinfo.linkdirs = libinfo_sys.linkdirs
        end
    end

    -- get result, libinfo may be empty body, but it's also valid
    -- @see https://github.com/xmake-io/xmake/issues/3777#issuecomment-1568453316
    local result = nil
    if libinfo then
        result             = result or {}
        result.includedirs = libinfo.includedirs
        result.linkdirs    = libinfo.linkdirs
        result.links       = libinfo.links
        result.defines     = libinfo.defines
        result.cxflags     = libinfo.cxflags
        result.ldflags     = libinfo.ldflags
        result.shflags     = libinfo.shflags
        result.version     = libinfo.version
    end
    return result
end
