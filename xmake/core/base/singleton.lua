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
-- @file        singleton.lua
--

-- define module
local singleton = singleton or {}

-- get a singleton instance and create it if not exists
--
-- e.g.
--
-- function get_xxx()
--      return {xxx = 1}
-- end
-- local instance = singleton.get("key", get_xxx)
--
-- Or
--
-- function get_xxx()
--
--     -- get instance
--     local instance, inited = singleton.get(get_xxx)
--     if inited then
--          return instance
--     end
--
--     -- init instance
--     instance.xxx = 1
--     return instance
-- end
--
function singleton.get(key, init)

    -- get key
    key = tostring(key)

    -- get all instances
    local instances = singleton.instances()

    -- get singleton instance
    local inited = true
    local instance = instances[key]
    if instance == nil then

        -- init instance
        if init then
            instance = init()
        else
            -- mark as not inited
            inited = false

            -- init instance
            instance = {}
        end

        -- save this instance
        instances[key] = instance
    end
    return instance, inited
end

-- get all singleton instances
function singleton.instances()
    local instances = singleton._INSTANCES
    if not instances then
        instances = {}
        singleton._INSTANCES = instances
    end
    return instances
end

-- return module: singleton
return singleton
