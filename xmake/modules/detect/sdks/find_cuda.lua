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
-- @file        find_cuda.lua
--

-- imports
import("lib.detect.find_file")
import("lib.detect.find_programver")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.cache.detectcache")

-- find cuda sdk directory
function _find_sdkdir(version)

    -- init the search directories
    local paths = {}
    if version then
        if is_host("macosx") then
            table.insert(paths, format("/Developer/NVIDIA/CUDA-%s/bin", version))
        elseif is_host("windows") then
            table.insert(paths, format("$(env CUDA_PATH_V%s)/bin", version:gsub("%.", "_")))
            table.insert(paths, format("C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA\\v%s\\bin", version))
        else
            table.insert(paths, format("/usr/local/cuda-%s/bin", version))
        end
    else
        if is_host("macosx") then
            table.insert(paths, "/Developer/NVIDIA/CUDA/bin")
            table.insert(paths, "/Developer/NVIDIA/CUDA*/bin")
        elseif is_host("windows") then
            table.insert(paths, "$(env CUDA_PATH)/bin")
            table.insert(paths, "C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA\\*\\bin")
        else
            -- find from default symbol link dir
            table.insert(paths, "/usr/local/cuda/bin")
            table.insert(paths, "/usr/local/cuda*/bin")
        end
        table.insert(paths, "$(env PATH)")
    end

    -- attempt to find nvcc
    local nvcc = find_file(is_host("windows") and "nvcc.exe" or "nvcc", paths)
    if nvcc then
        return path.directory(path.directory(nvcc))
    end
end

-- find cuda msbuild extensions
function _find_msbuildextensionsdir(sdkdir)
    local props = find_file("CUDA *.props", {path.join(sdkdir, "extras", "visual_studio_integration", "MSBuildExtensions")})
    if props then
        return path.directory(props)
    end
end

-- find cuda sdk toolchains
function _find_cuda(sdkdir)

    -- check sdkdir
    if sdkdir and not os.isdir(sdkdir) and not sdkdir:match("^[%d*]+%.[%d*]+$") then
        raise("invalid cuda version/location: " .. sdkdir)
    end

    -- find cuda directory
    if not sdkdir then
        sdkdir = _find_sdkdir()
    elseif sdkdir:match("^[%d*]+%.[%d*]+$") then
        local cudaversion = sdkdir
        sdkdir = _find_sdkdir(cudaversion)
        if not sdkdir then
            raise("cuda version %s not found!", cudaversion)
        end
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
    if is_host("windows") then
        local subdir = is_arch("x64") and "x64" or "Win32"
        table.insert(linkdirs, path.join(sdkdir, "lib", subdir))
    elseif is_host("linux") and is_arch("x86_64") then
        table.insert(linkdirs, path.join(sdkdir, "lib64", "stubs"))
        table.insert(linkdirs, path.join(sdkdir, "lib64"))
    else
        table.insert(linkdirs, path.join(sdkdir, "lib", "stubs"))
        table.insert(linkdirs, path.join(sdkdir, "lib"))
    end

    -- get includedirs
    local includedirs = {path.join(sdkdir, "include")}

    -- get version
    local version = find_programver(path.join(bindir, "nvcc"), {parse = "release (%d+%.%d+),"})
    
    -- find msbuildextensionsdir on windows
    local msbuildextensionsdir
    if is_host("windows") then
        msbuildextensionsdir = _find_msbuildextensionsdir(sdkdir)
    end

    -- get toolchains
    return {sdkdir = sdkdir, bindir = bindir, version = version, linkdirs = linkdirs, includedirs = includedirs, msbuildextensionsdir = msbuildextensionsdir}
end

-- find cuda sdk toolchains
--
-- @param sdkdir    the cuda sdk directory or version
-- @param opt       the argument options
--
-- @return          the cuda sdk toolchains. e.g. {sdkdir = ..., bindir = .., linkdirs = ..., includedirs = ..., .. }
--
-- @code
--
-- local toolchains = find_cuda("/Developer/NVIDIA/CUDA-9.1")
-- local toolchains = find_cuda("9.1")
-- local toolchains = find_cuda("9.*")
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_cuda"
    local cacheinfo = detectcache:get(key) or {}
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
    detectcache:set(key, cacheinfo)
    detectcache:save()
    return cuda
end
