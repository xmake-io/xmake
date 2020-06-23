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
-- @author      OpportunityLiu
-- @file        math.lua
--

-- define module
local math = math or {}

-- init constants
math.nan   = math.log(-1)
math.e     = math.exp(1)
math.inf   = 1/0 -- @see http://lua-users.org/wiki/InfAndNanComparisons

-- check a number is int
--
-- @returns true for int, otherwise false
--
function math:isint()
    assert(type(self) == "number", "number expacted")
    return self == math.floor(self) and self ~= math.huge and self ~= -math.huge
end

-- check a number is inf or -inf
--
-- @returns 1 for inf,  -1 for -inf, otherwise false
--
function math:isinf()
    assert(type(self) == "number", "number expacted")
    if self == math.inf then
        return 1
    elseif self == -math.inf then
        return -1
    else
        return false
    end
end

-- check a number is nan
--
-- @returns true for nan, otherwise false
--
function math:isnan()
    assert(type(self) == "number", "number expacted")
    return self ~= self
end


-- return module
return math
