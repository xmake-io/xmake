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
-- @file        client_config.lua
--

-- imports
import("core.base.global")
import("core.base.base64")
import("core.base.bytes")
import("private.service.server_config")

-- get a local server token
function _get_local_server_token()
    local tokens = server_config.get("tokens")
    if tokens then
        return tokens[1]
    end
end

-- generate a default config file
function _generate_configfile()
    local filepath = configfile()
    assert(not _g.configs and not os.isfile(filepath))
    local token = _get_local_server_token()
    print("generating the config file to %s ..", filepath)
    local configs = {
        send_timeout = -1,
        recv_timeout = -1,
        connect_timeout = -1,
        remote_build = {
            -- without authorization: "127.0.0.1:9691"
            -- with user authorization: "user@127.0.0.1:9691"
            connect = "127.0.0.1:9691",
            -- with token authorization
            token = token
        },
        remote_cache = {
            connect = "127.0.0.1:9692",
            token = token
        },
        distcc_build = {
            hosts = {
                -- optional configs
                --
                -- njob: max jobs
                {connect = "127.0.0.1:9693", token = token}
            }
        }
    }
    save(configs)
end

-- get config file path
function configfile()
    return path.join(global.directory(), "service", "client.conf")
end

-- get all configs
function configs()
    return _g.configs
end

-- get the given config, e.g. client_config.get("remote_build.connect")
function get(name)
    local value = configs()
    for _, key in ipairs(name:split('.', {plain = true})) do
        if type(value) == "table" then
            value = value[key]
        else
            value = nil
            break
        end
    end
    return value
end

-- load configs
function load()
    if _g.configs == nil then
        local filepath = configfile()
        if not os.isfile(filepath) then
            _generate_configfile()
        end
        assert(os.isfile(filepath), "%s not found!", filepath)
        _g.configs = io.load(filepath)
    end
end

-- save configs
function save(configs)
    local filepath = configfile()
    io.save(filepath, configs, {orderkeys = true})
end
