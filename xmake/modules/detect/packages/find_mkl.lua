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
-- @file        find_mkl.lua
--

-- imports
import("lib.detect.find_path")
import("lib.detect.find_library")
import("lib.detect.find_package")

-- find mkl
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
            "$(env ONEAPI_ROOT)\\mkl\\latest"
        }

        -- find library
        local result = {links = {}, linkdirs = {}, includedirs = {}, threading = ""}
        local linkinfo = find_library("mkl_core", paths, {suffixes = path.join("lib", rdir)})
        if not linkinfo then
            return
        end
        table.insert(result.linkdirs, linkinfo.linkdir)
        if rdir == "intel64" then
            table.insert(result.links, "mkl_intel_ilp64")
        else
            table.insert(result.links, "mkl_intel_c")
        end

        -- use tbb if available
        local tbb_res = find_package("tbb")
        if tbb_res then
            table.join2(result.linkdirs, tbb_res.linkdirs)
            table.join2(result.links, {"mkl_tbb_thread", "mkl_core", "tbb"})
            result.threading = "tbb"
        else
            table.join2(result.links, {"mkl_sequential", "mkl_core"})
            result.threading = "seq"
        end

        -- find include
        table.insert(result.includedirs, find_path("mkl.h", paths, {suffixes = "include"}))
        return result
    end
end
