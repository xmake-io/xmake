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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.project.config")

-- load it
function main(platform)

    -- cross toolchains?
    if config.get("cross") or config.get("bin") or config.get("sdk") then 

        -- init linkdirs and includedirs
        local sdkdir = config.get("sdk") 
        if sdkdir then
            platform:add("includedirs", path.join(sdkdir, "include"))
            platform:add("linkdirs", path.join(sdkdir, "lib"))
        end

        -- ok
        return 
    end

    -- init flags for architecture
    local archflags = nil
    local arch = config.get("arch")
    if arch then
        if arch == "x86_64" then archflags = "-m64"
        elseif arch == "i386" then archflags = "-m32"
        end
    end

    -- init flags for c/c++
    platform:add("cxflags", archflags, "-I/usr/local/include", "-I/usr/include")
    platform:add("ldflags", archflags, "-L/usr/local/lib", "-L/usr/lib")
    platform:add("shflags", archflags, "-L/usr/local/lib", "-L/usr/lib")

    -- init flags for objc/c++  (with ldflags and shflags)
    platform:add("mxflags", archflags)

    -- init flags for asm
    platform:add("yasm.asflags", "-f", arch == "x86_64" and "elf64" or "elf32")
    platform:add("asflags", archflags)

    -- init flags for golang
    platform:set("gc-ldflags", "")

    -- init flags for dlang
    local dc_archs = { i386 = "-m32", x86_64 = "-m64" }
    platform:add("dcflags", dc_archs[arch] or "")
    platform:add("dc-shflags", dc_archs[arch] or "")
    platform:add("dc-ldflags", dc_archs[arch] or "")

    -- init flags for rust
    platform:set("rc-shflags", "")
    platform:set("rc-ldflags", "")

    -- init flags for cuda
    local cu_archs = { i386 = "-m32 -Xcompiler -m32", x86_64 = "-m64 -Xcompiler -m64" }
    platform:add("cuflags", cu_archs[arch] or "")
    platform:add("cu-shflags", cu_archs[arch] or "")
    platform:add("cu-ldflags", cu_archs[arch] or "")
    local cuda_dir = config.get("cuda")
    if cuda_dir then
        platform:add("cuflags", "-I" .. os.args(path.join(cuda_dir, "include")))
        platform:add("cu-ldflags", "-L" .. os.args(path.join(cuda_dir, "lib")))
        platform:add("cu-shflags", "-L" .. os.args(path.join(cuda_dir, "lib")))
        platform:add("cu-ldflags", "-Xlinker -rpath=" .. os.args(path.join(cuda_dir, "lib")))
    end
end

