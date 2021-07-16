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
-- @file        find_nvtx.lua
--

-- imports
import("lib.detect.find_path")
import("lib.detect.find_library")
import("detect.sdks.find_cuda")

-- find nvtx
--
-- @param opt   the package options. e.g. see the options of find_package()
--
-- @return      see the return value of find_package()
--
function main(opt)
    if opt.plat == "windows" then

        -- init bits
        local rdir = (opt.arch == "x64" and "x64" or "Win32")
        local libname = (opt.arch == "x64" and "nvToolsExt64_1" or "nvToolsExt32_1")

        -- init search paths
        local paths =
        {
            "$(env NVTOOLSEXT_PATH)",
            "$(env PROGRAMFILES)/NVIDIA Corporation/NvToolsExt"
        }

        -- find library
        local result = {links = {}, linkdirs = {}, includedirs = {}, libfiles = {}}
        local linkinfo = find_library(libname, paths, {suffixes = path.join("lib", rdir)})
        if linkinfo then
            local nvtx_dir = path.directory(path.directory(linkinfo.linkdir))
            table.insert(result.linkdirs, linkinfo.linkdir)
            table.insert(result.links, libname)
            table.insert(result.libfiles, path.join(nvtx_dir, "bin", rdir, libname .. ".dll"))
            table.insert(result.libfiles, path.join(nvtx_dir, "lib", rdir, libname .. ".lib"))
        else
            -- not found?
            return
        end

        -- find include
        table.insert(result.includedirs, find_path("nvToolsExt.h", paths, {suffixes = "include"}))
        return result
    else
        local cuda = find_cuda()
        if cuda then
            local result = {links = {}, linkdirs = {}, includedirs = {}}

            -- find library
            local linkinfo = find_library("nvToolsExt", cuda.linkdirs)
            if linkinfo then
                table.insert(result.links, "nvToolsExt")
                table.insert(result.linkdirs, linkinfo.linkdir)
            else
                return
            end
            table.join2(result.includedirs, cuda.includedirs)
            return result
        end
    end
end
