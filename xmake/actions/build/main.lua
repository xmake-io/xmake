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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("build")
import("build_files")
import("cleaner")
import("trybuild")
import("statistics")

-- main
function main()

    -- try building it using third-party buildsystem if xmake.lua not exists
    if not os.isfile(project.file()) and option.get("try") then
        return trybuild() 
    end

    -- lock the whole project
    project.lock()

    -- get the target name
    local targetname = option.get("target")

    -- config it first
    task.run("config", {target = targetname})

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- post statistics
    statistics.post()

    -- clean up temporary files once a day
    cleaner.cleanup()

    -- build it
    try
    {
        function ()
            local sourcefiles = option.get("files")
            if sourcefiles then
                build_files(targetname, sourcefiles)
            else
                build(targetname) 
            end
        end,

        catch 
        {
            function (errors)
                if errors then
                    raise(errors)
                elseif targetname then
                    raise("build target: %s failed!", targetname)
                else
                    raise("build target failed!")
                end
            end
        }
    }

    -- unlock the whole project
    project.unlock()

    -- leave project directory
    os.cd(oldir)

    -- trace
    if option.get("rebuild") then
        cprint("${bright}build ok!${clear}")
    end
end
