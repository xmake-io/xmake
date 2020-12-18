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
-- @file        rm-repo.lua
--

-- imports
import("core.base.option")

-- get menu options
function menu_options()

    -- description
    local description = "Remove the given remote repository."

    -- menu options
    local options =
    {
        {nil, "all",  "k", nil, "Remove all added repositories."},
        {nil, "name", "v", nil, "The repository name."}
    }

    -- show menu options
    local function show_options()

        -- show usage
        cprint("${bright}Usage: $${clear cyan}xrepo rm-repo [options] [name]")

        -- show description
        print("")
        print(description)

        -- show options
        option.show_options(options, "rm-repo")
    end
    return options, show_options, description
end

-- remove repository
function remove_repository(name)

    -- enter working project directory
    local workdir = path.join(os.tmpdir(), "xrepo", "working")
    if not os.isdir(workdir) then
        os.mkdir(workdir)
        os.cd(workdir)
        os.vrunv("xmake", {"create", "-P", "."})
    else
        os.cd(workdir)
    end

    -- remove it
    local repo_argv = {"repo", "--remove", "--global"}
    if option.get("verbose") then
        table.insert(repo_argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(repo_argv, "-D")
    end
    table.insert(repo_argv, name)
    os.vexecv("xmake", repo_argv)
end

-- clear repository
function clear_repository()

    -- enter working project directory
    local workdir = path.join(os.tmpdir(), "xrepo", "working")
    if not os.isdir(workdir) then
        os.mkdir(workdir)
        os.cd(workdir)
        os.vrunv("xmake", {"create", "-P", "."})
    else
        os.cd(workdir)
    end

    -- clear all
    local repo_argv = {"repo", "--clear", "--global"}
    if option.get("verbose") then
        table.insert(repo_argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(repo_argv, "-D")
    end
    os.vexecv("xmake", repo_argv)
end

-- main entry
function main()
    local name = option.get("name")
    if name then
        remove_repository(name)
    elseif option.get("all") then
        clear_repository()
    else
        raise("please specify the repository name to be removed.")
    end
end
