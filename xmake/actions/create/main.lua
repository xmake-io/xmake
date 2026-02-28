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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.project")
import("actions.create.template", {rootdir = os.programdir()})

-- create project from template
function _create_project(language, templateid, targetname)

    -- check the targetname
    assert(targetname ~= ".", "you should specify ${red}-P${reset} instead of directly using ${red}.${reset}")

    -- check the language
    assert(language, "no language!")

    -- check the template id
    assert(templateid, "no template id!")

    -- get project directory
    local projectdir = path.absolute(option.get("project") or path.join(os.curdir(), targetname))
    if not os.isdir(projectdir) then
        -- make the project directory if not exists
        os.mkdir(projectdir)
    end

    -- xmake.lua exists?
    if os.isfile(path.join(projectdir, "xmake.lua")) and not option.get("force") then
        raise("project (${underline}%s/xmake.lua${reset}) exists!", projectdir)
    end

    -- empty project?
    os.tryrm(path.join(projectdir, ".xmake"))
    if not os.emptydir(projectdir) and not option.get("force") then
        -- otherwise, check whether it is empty
        raise("project directory (${underline}%s${reset}) is not empty!", projectdir)
    end

    -- enter the project directory
    os.cd(projectdir)

    -- create project
    local sourcedir = template.templatedir(language, templateid)
    assert(os.isdir(sourcedir), "invalid template id: %s!", templateid)

    -- get the builtin variables
    local builtinvars = template.builtinvars(targetname)

    local createdfiles = template.copy_files(sourcedir, projectdir, builtinvars)

    if not os.isfile(path.join(projectdir, ".gitignore")) then
        os.cp(path.join(os.programdir(), "scripts", "gitignore"), path.join(projectdir, ".gitignore"))
        table.insert(createdfiles, path.join(projectdir, ".gitignore"))
    end

    template.replace_variables_in_files(createdfiles, builtinvars)

    table.sort(createdfiles)
    for _, file in ipairs(createdfiles) do
        cprint("  ${green}[+]: ${clear}%s", path.relative(file, projectdir))
    end
end

-- main
function main()

    -- enter the original working directory, because the default directory is in the project directory
    os.cd(os.workingdir())

    -- the target name
    local targetname = option.get("target") or path.basename(project.directory()) or "demo"

    -- trace
    cprint("${bright}create %s ...", targetname)

    -- create project from template
    _create_project(option.get("language"), option.get("template"), targetname)

    -- trace
    cprint("${color.success}create ok!")
end
