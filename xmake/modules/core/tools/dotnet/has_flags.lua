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
-- @author      ruki
-- @file        has_flags.lua
--

-- attempt to check it from known flags
function _check_from_knownargs(flags, opt)
    local flag = flags[1]
    -- dotnet MSBuild properties
    if flag:startswith("-p:") or flag:startswith("/p:") then
        return true
    end
    -- dotnet CLI options
    if flag:startswith("--") then
        return true
    end
    -- common csflags patterns
    if flag:startswith("-") or flag:startswith("/") then
        return true
    end
end

-- has_flags(flags)?
--
-- @param opt   the argument options, e.g. {toolname = "", program = "", programver = "", toolkind = "[cs|csld|cssh]"}
--
-- @return      true or false
--
function main(flags, opt)
    opt = opt or {}
    if _check_from_knownargs(flags, opt) then
        return true
    end
    return false
end
