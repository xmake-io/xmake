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
-- @file        uninstall_admin.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("uninstall")

-- uninstall
function main(targetname, installdir, prefix)

    -- enter project directory
    os.cd(project.directory())

    -- load config
    config.load()

    -- load platform
    platform.load(config.plat())

    -- save the current option and push a new option context
    option.save()

    -- pass installdir to option
    if installdir then
        option.set("installdir", installdir)
    end

    -- pass prefix to option
    if prefix then
        option.set("prefix", prefix)
    end

    -- uninstall target
    uninstall(targetname ~= "__all" and targetname or nil)

    -- restore the previous option context
    option.restore()
end
