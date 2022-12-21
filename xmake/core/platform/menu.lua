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
-- @file        menu.lua
--

-- define module
local menu          = menu or {}

-- load modules
local os             = require("base/os")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local config         = require("project/config")
local platform       = require("platform/platform")

-- the remote build client is connected?
--
-- this implementation is from remote_build_client.is_connected(), but we can not call it by module/import
--
-- @see https://github.com/xmake-io/xmake/issues/3187
function _remote_build_is_connected()
    -- the current process is in service? we cannot enable it
    if os.getenv("XMAKE_IN_SERVICE") then
        return false
    end
    local projectdir = os.projectdir()
    local projectfile = os.projectfile()
    if projectfile and os.isfile(projectfile) and projectdir then
        local workdir = path.join(config.directory(), "remote_build")
        local statusfile = path.join(workdir, "status.txt")
        if os.isfile(statusfile) then
            local status = io.load(statusfile)
            if status and status.connected then
                return true
            end
        end
    end
end

-- get the option menu for action: xmake config or global
function menu.options(action)
    assert(action)

    -- get all platforms
    local plats = platform.plats()
    assert(plats)

    -- load and merge all platform options
    local exist     = {}
    local results   = {}
    for _, plat in ipairs(plats) do

        -- load platform
        local instance, errors = platform.load(plat)
        if not instance then
            return nil, errors
        end

        -- get menu of the supported platform on the current host
        local menu = instance:menu()
        if menu and (os.is_host(table.unpack(table.wrap(instance:hosts()))) or _remote_build_is_connected()) then

            -- get the options for this action
            local options = menu[action]
            if options then

                -- get the language option
                for _, option in ipairs(options) do

                    -- merge it and remove repeat
                    local name = option[2]
                    if name then
                        if not exist[name] then
                            table.insert(results, option)
                            exist[name] = true
                        end
                    else
                        table.insert(results, option)
                    end
                end
            end
        end
    end
    return results
end

-- return module
return menu
