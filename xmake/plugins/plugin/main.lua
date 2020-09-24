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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("devel.git")
import("net.fasturl")
import("actions.require.impl.environment", {rootdir = os.programdir()})

-- install plugins
function _install()

    -- enter environment
    environment.enter()

    -- remove previous plugins if exists
    local plugindir = path.join(global.directory(), "plugins")
    if os.isdir(plugindir) then
        os.rmdir(plugindir)
    end

    -- do install
    try
    {
        function ()

            -- sort main urls
            local mainurls = {"https://github.com/xmake-io/xmake-plugins.git", "https://gitlab.com/tboox/xmake-plugins.git", "https://gitee.com/tboox/xmake-plugins.git"}
            fasturl.add(mainurls)
            mainurls = fasturl.sort(mainurls)

            -- add main url
            for _, url in ipairs(mainurls) do
                git.clone(url, {verbose = option.get("verbose"), branch = "master", outputdir = plugindir})
                break
            end

            -- trace
            cprint("${bright}all plugins have been installed in %s!", plugindir)
        end,
        catch
        {
            function (errors)
                raise(errors)
            end
        }
    }

    -- leave environment
    environment.leave()
end

-- clear all installed plugins
function _clear()

    -- remove all plugins
    local plugindir = path.join(global.directory(), "plugins")
    if os.isdir(plugindir) then
        os.rmdir(plugindir)
    end

    -- trace
    cprint("${color.success}clear all installed plugins ok!")
end

-- main
function main()
    if option.get("install") then
        _install()
    elseif option.get("clear") then
        _clear()
    end
end

