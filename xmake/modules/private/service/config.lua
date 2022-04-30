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
-- @file        config.lua
--

-- imports
import("core.base.global")

-- generate a default config file
function _generate_configfile()
    local filepath = configfile()
    assert(not _g.configs and not os.isfile(filepath))
    local servicedir = path.join(global.directory(), "service")
    local configs = {
        logfile = path.join(servicedir, "logs.txt"),
        server = {
            known_hosts = {
                "127.0.0.1"
            },
            auths = {
                "root:123456"
            }
        },
        remote_build = {
            server = {
                listen = "0.0.0.0:9691",
                workdir = path.join(servicedir, "remote_build"),
            },
            client = {
                connect = "127.0.0.1:9691",
                user = "root"
            }
        }
    }
    io.save(filepath, configs, {orderkeys = true})
end

-- get config file path
function configfile()
    return path.join(global.directory(), "service.conf")
end

-- get all configs
function configs()
    return _g.configs
end

-- get the given config, e.g. config.get("remote_build.server.listen")
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

-- load config
function load()
    assert(not _g.configs, "config has been loaded!")
    local filepath = configfile()
    if not os.isfile(filepath) then
        _generate_configfile()
    end
    assert(os.isfile(filepath), "%s not found!", filepath)
    _g.configs = io.load(filepath)
end
