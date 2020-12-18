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
-- @file        add-repo.lua
--

-- imports
import("core.base.option")

-- get menu options
function menu_options()

    -- description
    local description = "Add the given remote repository url."

    -- menu options
    local options =
    {
        {nil, "name",   "v", nil, "The repository name."   },
        {nil, "url",    "v", nil, "The repository url"     },
        {nil, "branch", "v", nil, "The repository branch"  }
    }

    -- show menu options
    local function show_options()

        -- show usage
        cprint("${bright}Usage: $${clear cyan}xrepo add-repo [options] name url [branch]")

        -- show description
        print("")
        print(description)

        -- show options
        option.show_options(options, "add-repo")
    end
    return options, show_options, description
end

-- add repository
function _add_repository(name, url, branch)

    -- enter working project directory
    local workdir = path.join(os.tmpdir(), "xrepo", "working")
    if not os.isdir(workdir) then
        os.mkdir(workdir)
        os.cd(workdir)
        os.vrunv("xmake", {"create", "-P", "."})
    else
        os.cd(workdir)
    end

    -- add it
    local repo_argv = {"repo", "--add", "--global"}
    if option.get("verbose") then
        table.insert(repo_argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(repo_argv, "-D")
    end
    table.insert(repo_argv, name)
    table.insert(repo_argv, url)
    if branch then
        table.insert(repo_argv, branch)
    end
    os.vexecv("xmake", repo_argv)
end

-- main entry
function main()
    local name = option.get("name")
    local url  = option.get("url")
    if name and url then
        _add_repository(name, url, option.get("branch"))
    else
        raise("please specify the repository name and url to be added.")
    end
end
