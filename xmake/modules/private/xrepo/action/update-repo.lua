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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        update-repo.lua
--

-- imports
import("core.base.option")

-- get menu options
function menu_options()

    -- description
    local description = "Update the local repositories from remote."

    -- menu options
    local options =
    {
        {nil, "name", "v", nil, "The repository name."}
    }

    -- show menu options
    local function show_options()

        -- show usage
        cprint("${bright}Usage: $${clear cyan}xrepo update-repo [options]")

        -- show description
        print("")
        print(description)

        -- show options
        option.show_options(options, "update-repo")
    end
    return options, show_options, description
end

-- update repository
function update_repository()

    -- enter working project directory
    local workdir = path.join(os.tmpdir(), "xrepo", "working")
    if not os.isdir(workdir) then
        os.mkdir(workdir)
        os.cd(workdir)
        os.vrunv(os.programfile(), {"create", "-P", "."})
    else
        os.cd(workdir)
    end

    -- update it
    local repo_argv = {"repo", "--update"}
    if option.get("verbose") then
        table.insert(repo_argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(repo_argv, "-D")
    end
    local name = option.get("name")
    if name then
        table.insert(repo_argv, name)
    end
    os.vexecv(os.programfile(), repo_argv)
end

function main()
    update_repository()
end
