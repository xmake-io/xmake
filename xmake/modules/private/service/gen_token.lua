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
-- @file        gen_token.lua
--

-- imports
import("core.base.option")
import("core.base.base64")
import("core.base.bytes")
import("core.base.hashset")
import("private.service.service")
import("private.service.server_config", {alias = "config"})

-- generate a token
function _generate_token()
    return hash.md5(bytes(base64.encode(hash.uuid())))
end

function main()

    -- generate token
    local token = _generate_token()

    -- save to configs
    local configs = assert(config.configs(), "configs not found!")
    configs.tokens = configs.tokens or {}
    if not hashset.from(configs.tokens):has(token) then
        table.insert(configs.tokens, token)
    else
        cprint("Token ${yellow bright}%s${clear} has been added!", token)
        return
    end
    config.save(configs)
    cprint("New token ${yellow bright}%s${clear} is generated!", token)
end

