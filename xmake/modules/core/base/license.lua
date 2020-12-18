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
-- @file        license.lua
--

-- imports
import("core.base.object")
import("core.base.hashset")

-- get licenses
function _licenses()
    local licenses = _g.licenses
    if not licenses then
        licenses = hashset.from({"Apache-1.1", "Apache-2.0",
                                 "MIT",
                                 "Zlib",
                                 "Public Domain",
                                 "CC0",
                                 "LLVM",
                                 "AFL-3.0",
                                 "AGPL-3.0",
                                 "LGPL-2.0", "LGPL-2.1", "LGPL-3.0",
                                 "GPL-2.0", "GPL-3.0",
                                 "BSD-2-Clause", "BSD-3-Clause",
                                 "BSL-1.0",
                                 "MPL-2.0",
                                 "libpng-2.0",
                                 "Python-2.0"})
        _g.licenses = licenses
    end
    return licenses
end

-- get all licenses list
function list()
    return _licenses():to_array()
end

-- normalize license
function normalize(license)
    -- TODO parse and convert license strings in other formats
    return license
end

-- check if the license is compatible
-- @see https://github.com/xmake-io/xmake/issues/1016
--
function compatible(target_license, library_license, opt)
    opt = opt or {}
    library_license = normalize(library_license)
    if library_license then
        target_license = normalize(target_license)
        if library_license:startswith("GPL-") then
            return target_license and target_license:startswith("GPL-")
        elseif library_license:startswith("LGPL-") then
            if target_license and target_license:startswith("LGPL-") then
                return true
            elseif opt.library_kind and opt.library_kind == "shared" then
                -- we can only use shared library with LGPL-x
                return true
            else
                return false, string.format("we can use shared libraries with %s or use set_license()/set_policy() to modify/disable license", library_license)
            end
        else
            -- TODO maybe we need handle more licenses
        end
    end
    return true
end
