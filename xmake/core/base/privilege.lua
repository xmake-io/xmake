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
-- @author      TitanSnow
-- @file        privilege.lua
--

-- define module
local privilege = privilege or {}

-- load modules
local os = require("base/os")

-- store privilege
function privilege.store()

    -- check if root
    if not os.isroot() then
        return false
    end

    local owner = {}
    -- sudo will set SUDO_UID & SUDO_GID
    -- so that can easily get original uid & gid
    local sudo_uid = os.getenv("SUDO_UID")
    local sudo_gid = os.getenv("SUDO_GID")
    if sudo_uid and sudo_gid then
        owner.uid = sudo_uid
        owner.gid = sudo_gid
    else
        -- find projectdir's owner
        local projectdir = xmake._PROJECT_DIR
        assert(projectdir)
        owner = os.getown(projectdir)
        if not owner then

            -- fallback to current dir
            owner = os.getown(os.curdir())
            if not owner then
                return false
            end
        end
    end

    -- set gid
    if os.gid(owner.gid).errno ~= 0 then
        return false
    end

    -- set uid
    if os.uid({ruid = owner.uid}).errno ~= 0 or os.uid({euid = owner.uid}).errno ~= 0 then
        return false
    end

    -- set flag
    privilege._HAS_PRIVILEGE = true

    -- ok
    return true
end

-- check if has stored privilege
function privilege.has()
    return privilege._HAS_PRIVILEGE or false
end

function privilege.get()

    -- has?
    if privilege._HAS_PRIVILEGE ~= true then
        return false
    end

    -- set uid
    if os.uid({euid = 0}).errno ~= 0 or os.uid({ruid = 0}).errno ~= 0 then
        return false
    end

    -- set gid
    if os.gid(0).errno ~= 0 then
        return false
    end

    return true
end

-- return module
return privilege
