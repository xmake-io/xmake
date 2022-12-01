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
-- @file        find_vulkansdk.lua
--

-- imports
import("core.project.config")
import("lib.detect.find_file")
import("lib.detect.find_path")
import("lib.detect.find_library")
import("lib.detect.find_programver")

-- find vulkansdk
--
-- @param opt   the package options. e.g. see the options of find_package()
--
-- @return      see the return value of find_package()
--
function main(opt)

    -- init option
    opt = opt or {}

    -- init search configs
    local paths =
    {
        "$(env VK_SDK_PATH)",
        "$(env VULKAN_SDK)"
    }
    local arch = opt.arch or config.arch() or os.arch()
    local binsuffix = ((is_host("windows") and arch == "x86") and "bin32" or "bin")
    local libname = (is_host("windows") and "vulkan-1" or "vulkan")
    local libsuffix = ((is_host("windows") and arch == "x86") and "lib32" or "lib")

    -- find library
    local result = {links = {}, linkdirs = {}, includedirs = {}}
    local linkinfo = find_library(libname, paths, {suffixes = {libsuffix}})
    if linkinfo then
        result.sdkdir = path.directory(linkinfo.linkdir)
        result.bindir = path.join(result.sdkdir, binsuffix)
        table.insert(result.linkdirs, linkinfo.linkdir)
        table.insert(result.links, libname)
    else
        -- not found?
        return
    end

    -- find headers
    local incdir = find_path(path.join("vulkan", "vulkan.h"), paths, {suffixes = {"include"}})
    if incdir then
        table.insert(result.includedirs, incdir)
    else
        -- not found?
        return
    end

    -- find api version
    local vkinfo
    if is_host("windows") then
        if arch == "x86" then
            vkinfo = find_file("vulkaninfoSDK.exe", paths, {suffixes = {"bin32"}})
        else
            vkinfo = find_file("vulkaninfoSDK.exe", paths, {suffixes = {"bin"}})
        end
    elseif is_host("linux") then
        vkinfo = find_file("vulkaninfo", paths, {suffixes = {"bin"}})
    end
    if vkinfo then
        local apiver = find_programver(vkinfo, {command = "--summary", parse = "Vulkan Instance Version: (%d+%.%d+%.%d+)"})
        result.apiversion = apiver
    end

    -- return
    return result
end
