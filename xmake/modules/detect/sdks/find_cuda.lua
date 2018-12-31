--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_cuda.lua
--

-- imports
import("lib.detect.find_file")

-- find cuda sdk directory
function _find_cudadir()

    -- init the search directories
    local pathes = {}
    if os.host() == "macosx" then
        table.insert(pathes, "/Developer/NVIDIA/CUDA*/bin")
    elseif os.host() == "windows" then
        table.insert(pathes, "$(env CUDA_PATH)/bin")
    else
        table.insert(pathes, "/usr/local/cuda*/bin")
    end

    -- attempt to find nvcc
    local nvcc = find_file(os.host() == "windows" and "nvcc.exe" or "nvcc", pathes)
    if nvcc then
        return path.directory(path.directory(nvcc))
    end
end

-- find cuda sdk toolchains
--
-- @param cudadir   the cuda directory
-- @param opt       the argument options 
--
-- @return          the cuda sdk toolchains. .e.g {cudadir = ..., bindir = .., linkdirs = ..., includedirs = ..., .. }
--
-- @code 
--
-- local toolchains = find_cuda("/Developer/NVIDIA/CUDA-9.1")
-- 
-- @endcode
--
function main(cudadir, opt)

    -- init arguments
    opt = opt or {}

    -- find cuda directory
    if not cudadir or not os.isdir(cudadir) then
        cudadir = _find_cudadir()
    end

    -- not found?
    if not cudadir or not os.isdir(cudadir) then
        return nil
    end

    -- get the bin directory 
    local bindir = path.join(cudadir, "bin")
    if not os.isexec(path.join(bindir, "nvcc")) then
        return nil
    end

    -- get linkdirs
    local linkdirs = {path.join(cudadir, "lib")}

    -- get includedirs
    local includedirs = {path.join(cudadir, "include")}

    -- get toolchains
    return {cudadir = cudadir, bindir = bindir, linkdirs = linkdirs, includedirs = includedirs}
end
