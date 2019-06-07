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

    -- before load
    before_load(function (target)
        if not target:data("cuda") then
            local cuda = get_config("cuda")
            if not cuda then
                -- TODO improve find_cuda + cache 
                local toolchain = import("detect.sdks.find_cuda")()
                if toolchain then
                    cuda = toolchain.cudadir
                end
            end
            target:data_set("cuda", assert(find_qt(nil, {verbose = true}), "Qt SDK not found!"))
        end
    end)

