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
-- @file        xmake.lua
--

-- define toolchain
toolchain("dlang")
        
    -- set toolsets
    set_toolsets("dc",   "$(env DC)", "dmd", "ldc2", "gdc")
    set_toolsets("dcld", "$(env DC)", "dmd", "ldc2", "gdc")
    set_toolsets("dcsh", "$(env DC)", "dmd", "ldc2", "gdc")
    set_toolsets("dcar", "$(env DC)", "dmd", "ldc2", "gdc")

    -- on load
    on_load(function (toolchain)
        local march = is_arch("x86_64", "x64") and "-m64" or "-m32"
        toolchain:add("dcflags",   march)
        toolchain:add("dcshflags", march)
        toolchain:add("dcldflags", march)
    end)
