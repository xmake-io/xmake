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
import("core.base.option")
import("core.base.semver")
import("core.project.config")
import("core.project.target")
import("lib.detect.find_tool")
import("lib.detect.find_file")

-- find package using the cargo package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, require_version = "1.12.x")
--
function main(name, opt)
    
    -- Rust packages like actix-web will produce a file named actix_web-<...>
    name = name:gsub("-", "_")

    local frameworkdirs
    local frameworks
    local librarydir = path.join(opt.installdir, "lib")
    local libfiles = os.files(path.join(librarydir, "*.rlib"))
    for _, libraryfile in ipairs(libfiles) do
        local filename = path.filename(libraryfile)
        if filename:startswith("lib" .. name .. "-") then
            frameworkdirs = frameworkdirs or {}
            frameworks = frameworks or {}
            table.insert(frameworkdirs, librarydir)
            table.insert(frameworks, libraryfile)
            break
        end
    end
    local result
    if frameworks and frameworkdirs then
        result = result or {}
        result.libfiles = libfiles
        result.frameworkdirs = frameworkdirs
        result.frameworks = frameworks
        result.version = opt.require_version
    end
    return result
end
