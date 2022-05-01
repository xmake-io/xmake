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
-- @file        xmake.lua
--

-- define toolchain
toolchain("cuda")

    -- set homepage
    set_homepage("https://developer.nvidia.com/cuda-toolkit")
    set_description("CUDA Toolkit (nvcc, nvc, nvc++, nvfortran)")

    -- set toolset
    set_toolset("cc",   "nvc")
    set_toolset("cxx",  "nvc++")
    set_toolset("fc",   "nvfortran")
    set_toolset("fcld", "nvfortran")
    set_toolset("fcsh", "nvfortran")
    set_toolset("ld",   "nvc++", "nvc")
    set_toolset("sh",   "nvc++", "nvc")
    set_toolset("cu",   "nvcc", "clang")
    set_toolset("culd", "nvcc")
    set_toolset("cu-ccbin", "$(env CXX)", "$(env CC)")

    -- bind msvc environments, because nvcc will call cl.exe
    on_load(function (toolchain)
        if toolchain:is_plat("windows") then
            import("core.tool.toolchain", {alias = "core_toolchain"})
            local msvc = core_toolchain.load("msvc", {plat = toolchain:plat(), arch = toolchain:arch()})
            for name, values in pairs(msvc:runenvs()) do
                toolchain:add("runenvs", name, values)
            end
        end
    end)

