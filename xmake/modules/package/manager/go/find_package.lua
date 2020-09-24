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
-- @file        find_package.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.package.package")

-- get the package install directory
function _go_get_installdir(name, opt)
    local name = "go_" .. name:lower()
    local dir = path.join(package.installdir(), name:sub(1, 1):lower(), name)
    if opt.version then
        dir = path.join(dir, opt.version)
    end
    return path.join(dir, opt.buildhash)
end

-- find package using the go package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)
    local result
    local installdir = _go_get_installdir(name, opt)
    for _, libraryfile in ipairs(os.files(path.join(installdir, "lib", "**.a"))) do
        result = {version = opt.version, linkdirs = path.join(installdir, "lib"), includedirs = path.join(installdir, "lib")}
        break
    end
    return result
end
