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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("private.action.require.list")
import("private.action.require.scan")
import("private.action.require.info")
import("private.action.require.fetch")
import("private.action.require.clean")
import("private.action.require.search")
import("private.action.require.export")
import("private.action.require.import", {alias = "import_packages"})
import("private.action.require.install")
import("private.action.require.uninstall")

--
-- the default repositories:
--     xmake-repo https://github.com/xmake-io/xmake-repo.git
--
-- add other repositories:
--     xmake repo --add other-repo https://github.com/other/other-repo.git
-- or
--     add_repositories("other-repo https://github.com/other/other-repo.git")
--
-- add requires:
--
--     add_requires("tboox.tbox >=1.5.1", "zlib >=1.2.11")
--     add_requires("zlib master")
--     add_requires("xmake-repo@tboox.tbox >=1.5.1")
--     add_requires("https://github.com/tboox/tbox.git@tboox.tbox >=1.5.1")
--
-- add package dependencies:
--
--     target("test")
--         add_packages("tboox.tbox", "zlib")
--

-- load project
function _load_project()

    -- config it first
    task.run("config", {require = false}, {disable_dump = true})

    -- enter project directory
    os.cd(project.directory())
end

-- main
function main()

    -- load project first
    _load_project()

    -- clean all installed packages cache
    if option.get("clean") then

        clean(option.get("requires"))

    -- search for the given packages from repositories
    elseif option.get("search") then

        search(option.get("requires"))

    -- uninstall the installed packages
    elseif option.get("uninstall") then

        uninstall(option.get("requires"))

    -- export the installed packages
    elseif option.get("export") then

        export(option.get("requires"))

    -- import the installed packages
    elseif option.get("import") then

        import_packages(option.get("requires"))

    -- show the given package info
    elseif option.get("info") then

        info(option.get("requires"))

    -- fetch the library info of the given package
    elseif option.get("fetch") then

        fetch(option.get("requires"))

    -- list all package dependencies in project
    elseif option.get("list") then

        list()

    -- scan the given or all packages
    elseif option.get("scan") then

        scan(option.get("requires"))

    -- install and upgrade all outdated package dependencies by default if no arguments
    else
        install(option.get("requires"))
    end
end

