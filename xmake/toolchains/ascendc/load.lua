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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      wuzhenqing
-- @file        load.lua
--

function main(toolchain)
    local sdkdir = toolchain:config("sdkdir")
    local hostroot = toolchain:config("hostroot")
    if not sdkdir or not hostroot then
        raise("ascendc toolchain not checked")
    end

    -- add run environments
    toolchain:add("runenvs", "LD_LIBRARY_PATH", path.join(hostroot, "lib64"))

    -- add toolchain-level search paths (picked up by language nameflags)
    toolchain:add("includedirs", path.join(hostroot, "include"))
    toolchain:add("includedirs", path.join(hostroot, "asc", "include"))
    toolchain:add("includedirs", path.join(hostroot, "asc", "include", "aicpu_api"))
    toolchain:add("includedirs", path.join(sdkdir, "include"))
    toolchain:add("linkdirs", path.join(hostroot, "lib64"))
    toolchain:add("linkdirs", path.join(hostroot, "devlib"))
    toolchain:add("linkdirs", path.join(sdkdir, "lib64"))
    toolchain:add("rpathdirs", path.join(hostroot, "lib64"))
    toolchain:add("rpathdirs", path.join(hostroot, "devlib"))
    toolchain:add("rpathdirs", path.join(sdkdir, "lib64"))
    toolchain:add("syslinks", "ascendcl", "acl_rt", "dl")

    -- aicpu-specific compiler flags (SDK-path-dependent)
    toolchain:add("aicpuflags", "-D_AICPU_DEVICE_")
    toolchain:add("aicpuflags", "--cce-aicpu-L" .. path.join(hostroot, "lib64", "device", "lib64"))
    toolchain:add("aicpuflags", "--cce-aicpu-laicpu_api")
    toolchain:add("aicpuflags", "--cce-aicpu-toolkit-path=" .. path.join(sdkdir, "toolkit", "toolchain", "hcc", "bin"))
    toolchain:add("aicpuflags", "--cce-aicpu-sysroot=" .. path.join(sdkdir, "toolkit", "toolchain", "hcc", "sysroot"))
end
