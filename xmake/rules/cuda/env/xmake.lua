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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: environment
rule("cuda.env")
    after_load(function (target)

        -- imports
        import("detect.sdks.find_cuda")

        -- get cuda sdk
        local cuda = assert(find_cuda(nil, {verbose = true}), "Cuda SDK not found!")

        -- add arch
        if is_arch("i386", "x86") then
            target:add("cuflags", "-m32", {force = true})
            target:add("culdflags", "-m32", {force = true})
        else
            target:add("cuflags", "-m64", {force = true})
            target:add("culdflags", "-m64", {force = true})
        end

        -- add ccbin
        local cu_ccbin = get_config("cu-ccbin")
        if cu_ccbin then
            target:add("culdflags", "-ccbin=" .. os.args(cu_ccbin), {force = true})
        end

        -- add links
        target:add("syslinks", "cudadevrt")
        local cudart = false
        for _, link in ipairs(table.join(target:get("links") or {}, target:get("syslinks"))) do
            if link == "cudart" or link == "cudart_static" then
                cudart = true
                break
            end
        end
        if not cudart then
            target:add("syslinks", "cudart_static")
        end
        if is_plat("linux") then
            target:add("syslinks", "rt", "pthread", "dl")
        end
        target:add("linkdirs", cuda.linkdirs)
        target:add("rpathdirs", cuda.linkdirs)

        -- add includedirs
        target:add("includedirs", cuda.includedirs)
    end)

