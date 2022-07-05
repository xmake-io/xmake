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
-- @file        server_config.lua
--

-- imports
import("core.base.global")
import("core.base.base64")
import("core.base.bytes")

-- generate a token
function _generate_token()
    return hash.md5(bytes(base64.encode(hash.uuid())))
end

-- generate a default config file
function _generate_configfile()
    local filepath = configfile()
    assert(not _g.configs and not os.isfile(filepath))
    local servicedir = path.join(global.directory(), "service", "server")
    local token = _generate_token()
    print("generating the config file to %s ..", filepath)
    cprint("an token(${bright yellow}%s${clear}) is generated, we can use this token to connect service.", token)
    local configs = {
        logfile = path.join(servicedir, "logs.txt"),
        known_hosts = {
        --    "127.0.0.1"
        },
        tokens = {
            token
        },
        send_timeout = -1,
        recv_timeout = -1,
        remote_build = {
            listen = "0.0.0.0:9691",
            workdir = path.join(servicedir, "remote_build"),
        },
        remote_cache = {
            listen = "0.0.0.0:9692",
            workdir = path.join(servicedir, "remote_cache"),
        },
        distcc_build = {
            listen = "0.0.0.0:9693",
            workdir = path.join(servicedir, "distcc_build"),
            toolchains = {
                ndk = {
                }
            }
        }
    }
    save(configs)
end

-- get config file path
function configfile()
    return path.join(global.directory(), "service", "server.conf")
end

-- get all configs
function configs()
    return _g.configs
end

-- get the given config, e.g. server_config.get("remote_build.listen")
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
