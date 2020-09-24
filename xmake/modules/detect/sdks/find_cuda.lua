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
-- @file        find_cuda.lua
--

-- imports
import("lib.detect.cache")
import("lib.detect.find_file")
import("core.base.option")
import("core.base.global")
import("core.project.config")

-- find cuda sdk directory
function _find_sdkdir()

    -- init the search directories
    local paths = {}
    if os.host() == "macosx" then
        table.insert(paths, "/Developer/NVIDIA/CUDA/bin")
        table.insert(paths, "/Developer/NVIDIA/CUDA*/bin")
    elseif os.host() == "windows" then
        table.insert(paths, "$(env CUDA_PATH)/bin")
    else
        -- find from default symbol link dir
        table.insert(paths, "/usr/local/cuda/bin")
        table.insert(paths, "/usr/local/cuda*/bin")
    end
    table.insert(paths, "$(env PATH)")

    -- attempt to find nvcc
    local nvcc = find_file(os.host() == "windows" and "nvcc.exe" or "nvcc", paths)
    if nvcc then
        return path.directory(path.directory(nvcc))
    end
end

-- find cuda sdk toolchains
function _find_cuda(sdkdir)

    -- find cuda directory
    if not sdkdir or not os.isdir(sdkdir) then
        sdkdir = _find_sdkdir()
    end

    -- not found?
    if not sdkdir or not os.isdir(sdkdir) then
        return nil
    end

    -- get the bin directory
    local bindir = path.join(sdkdir, "bin")
    if not os.isexec(path.join(bindir, "nvcc")) then
        return nil
    end

    -- get linkdirs
    local linkdirs = {}
    if is_plat("windows") then
        local subdir = is_arch("x64") and "x64" or "Win32"
        table.insert(linkdirs, path.join(sdkdir, "lib", subdir))
    elseif is_plat("linux") and is_arch("x86_64") then
        table.insert(linkdirs, path.join(sdkdir, "lib64", "stubs"))
        table.insert(linkdirs, path.join(sdkdir, "lib64"))
    else
        table.insert(linkdirs, path.join(sdkdir, "lib", "stubs"))
        table.insert(linkdirs, path.join(sdkdir, "lib"))
    end

    -- get includedirs
    local includedirs = {path.join(sdkdir, "include")}

    -- get toolchains
    return {sdkdir = sdkdir, bindir = bindir, linkdirs = linkdirs, includedirs = includedirs}
end

-- find cuda sdk toolchains
--
-- @param sdkdir    the cuda sdk directory
-- @param opt       the argument options
--
-- @return          the cuda sdk toolchains. e.g. {sdkdir = ..., bindir = .., linkdirs = ..., includedirs = ..., .. }
--
-- @code
--
-- local toolchains = find_cuda("/Developer/NVIDIA/CUDA-9.1")
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_cuda"
    local cacheinfo = cache.load(key)
    if not opt.force and cacheinfo.cuda and cacheinfo.cuda.sdkdir and os.isdir(cacheinfo.cuda.sdkdir) then
        return cacheinfo.cuda
    end

    -- find cuda
    local cuda = _find_cuda(sdkdir or config.get("cuda") or global.get("cuda") or config.get("sdk"))
    if cuda then

        -- save to config
        config.set("cuda", cuda.sdkdir, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for Cuda SDK directory ... ${color.success}%s", cuda.sdkdir)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for Cuda SDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.cuda = cuda or false
    cache.save(key, cacheinfo)

    -- ok?
    return cuda
end
