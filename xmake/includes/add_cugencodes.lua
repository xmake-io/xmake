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
-- @author      OpportunityLiu
-- @file        add_cugencodes.lua
--

-- add cuda `-gencode` flags to target
--
-- the gpu arch format syntax
-- - compute_xx                   --> `-gencode arch=compute_xx,code=compute_xx`
-- - sm_xx                        --> `-gencode arch=compute_xx,code=sm_xx`
-- - sm_xx,sm_yy                  --> `-gencode arch=compute_xx,code=[sm_xx,sm_yy]`
-- - compute_xx,sm_yy             --> `-gencode arch=compute_xx,code=sm_yy`
-- - compute_xx,sm_yy,sm_zz       --> `-gencode arch=compute_xx,code=[sm_yy,sm_zz]`
-- - native                       --> match the fastest cuda device on current host,
--                                    eg. for a Tesla P100, `-gencode arch=compute_60,code=sm_60` will be added,
--                                    if no available device is found, no `-gencode` flags will be added
--                                    @seealso xmake/modules/lib/detect/find_cudadevices
--
-- e.g.
-- includes("add_cugencodes.lua")
-- target("test")
--    add_rules("cuda.console")
--    add_files("src/*.cu")
--    add_cugencodes("native", "compute_50,sm_50", "compute_70")
--
function add_cugencodes(...)
    add_values("cuda.gencode", ...)
end

