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
-- @file        should_install.lua
--


-- should install?
function _should_install(instance)
    if instance:exists() then
        return false
    end
    if instance:parents() then
        -- if all the packages that depend on it already exist, then there is no need to install it
        for _, parent in pairs(instance:parents()) do
            if _should_install(parent) and not parent:exists() then
                return true
            end
        end
    else
        return true
    end
end

-- the given package should be install?
function main(instance)
    return _should_install(instance)
end
