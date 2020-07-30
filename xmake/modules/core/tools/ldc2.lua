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
-- @author      ruki, BarrOff
-- @file        ldc2.lua
--

-- imports
inherit("dmd")

-- init it
function init(self)

    -- init arflags
    self:set("dcarflags", "-lib")

    -- init shflags
    self:set("dcshflags", "-shared", "--relocation-model=pic")

    -- init dcflags for the kind: shared
    self:set("shared.dcflags", "--relocation-model=pic")
end

-- make the optimize flag
function nf_optimize(self, level)
    local maps =
    {
        fast        = "-O"
    ,   faster      = "-O --release"
    ,   fastest     = "-O --release --boundscheck=off"
    ,   smallest    = "-O --release --boundscheck=off"
    ,   aggressive  = "-O --release --boundscheck=off"
    }
    return maps[level]
end


