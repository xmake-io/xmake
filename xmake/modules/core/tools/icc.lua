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
-- @file        icc.lua
--

-- inherit gcc
inherit("gcc")

-- init it
function init(self)
    _super.init(self)
end

-- make the fp-model flag
function nf_fpmodel(self, level)
    local maps =
    {
        precise    = "-fp-model=precise"
    ,   fast       = "-fp-model=fast"  --default
    ,   strict     = "-fp-model=strict"
    ,   except     = "-fp-model=except"
    ,   noexcept   = "-fp-model=no-except"
    }
    return maps[level]
end
