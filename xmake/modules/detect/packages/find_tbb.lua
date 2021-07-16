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
-- @author      xq114
-- @file        find_tbb.lua
--

-- imports
import("lib.detect.find_path")
import("lib.detect.find_library")

-- find tbb
--
-- @param opt   the package options. e.g. see the options of find_package()
--
-- @return      see the return value of find_package()
--
function main(opt)

    -- for windows platform
    if opt.plat == "windows" then

        -- init bits
        local rdir = (opt.arch == "x64" and "intel64" or "ia32")

        -- init search paths
        local paths = {
            "$(env ONEAPI_ROOT)\\tbb\\latest"
        }

        -- find library
        local result = {links = {}, linkdirs = {}, includedirs = {}}
        local linkinfo = find_library("tbb", paths, {suffixes = path.join("lib", rdir, "vc14")})
        if linkinfo then
            table.insert(result.linkdirs, linkinfo.linkdir)
            table.join2(result.links, {"tbb", "tbb_malloc"})
        else
            -- not found?
            return
        end

        -- find include
        table.insert(result.includedirs, find_path(path.join("tbb", "tbb.h"), paths, {suffixes = "include"}))

        -- ok
        return result
    end
end
