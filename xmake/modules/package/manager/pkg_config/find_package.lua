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
import("lib.detect.pkg_config")

-- find package from the pkg-config package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- init options
    opt = opt or {}

    -- get library info
    local libinfo = pkg_config.libinfo(name, opt)
    if not libinfo then
        return 
    end

    local result = nil
    if libinfo.links or libinfo.includedirs then
        result             = result or {}
        result.includedirs = libinfo.includedirs
        result.linkdirs    = libinfo.linkdirs
        result.links       = libinfo.links
        result.version     = libinfo.version
    end
    return result
end
