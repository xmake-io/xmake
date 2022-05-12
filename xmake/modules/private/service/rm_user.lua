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
-- @file        rm_user.lua
--

-- imports
import("core.base.option")
import("core.base.base64")
import("core.base.bytes")
import("core.base.hashset")
import("private.service.service")
import("private.service.server_config", {alias = "config"})

function main(user)
    assert(user, "empty user name!")

    -- get user password
    cprint("Please input user ${bright}%s${clear} password:", user)
    io.flush()
    local pass = (io.read() or ""):trim()
    assert(pass ~= "", "password is empty!")

    -- compute user authorization
    local token = base64.encode(user .. ":" .. pass)
    token = hash.md5(bytes(token))

    -- save to configs
    local configs = assert(config.configs(), "configs not found!")
    configs.tokens = configs.tokens or {}
    local tokenset = hashset.from(configs.tokens)
    if tokenset:has(token) then
        tokenset:remove(token)
        configs.tokens = tokenset:to_array()
    else
        cprint("User ${bright}%s${clear} not found!", user)
        return
    end
    config.save(configs)
    cprint("Remove user ${bright}%s${clear} ok!", user)
end


