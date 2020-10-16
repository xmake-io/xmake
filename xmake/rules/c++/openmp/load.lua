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
-- @file        load.lua
--

-- main entry
function main(target, sourcekind)
    local _, compiler_name = target:tool(sourcekind)
    local flag_name        = sourcekind == "cxx" and "cxxflags" or "cflags"
    if compiler_name == "cl" then
        target:add(flag_name, "/openmp")
    elseif compiler_name == "clang" or compiler_name == "clangxx" then
        if target:is_plat("macosx") then
            target:add(flag_name, "-Xpreprocessor -fopenmp")
        else
            target:add(flag_name, "-fopenmp")
        end
    elseif compiler_name == "gcc" or compiler_name == "gxx" then
        target:add(flag_name, "-fopenmp")
    elseif compiler_name == "icc" or compiler_name == "icpc" then
        target:add(flag_name, "-qopenmp")
    elseif compiler_name == "icl" then
        target:add(flag_name, "-Qopenmp")
    end
end
