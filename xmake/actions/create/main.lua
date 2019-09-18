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
import("core.project.project")
import("core.project.template")

-- get the builtin variables
function _get_builtinvars(tempinst, targetname)
    return {TARGETNAME = targetname, 
            FAQ = function() return io.readfile(path.join(os.programdir(), "scripts", "faq.lua")) end}
end

-- create project from template
function _create_project(tempinst, sourcedir, targetname)

    -- get project directory
    local projectdir = path.absolute(option.get("project") or path.join(os.curdir(), targetname))

    -- ensure the project directory 
    if not os.isdir(projectdir) then 
        os.mkdir(projectdir)
    end

    -- copy the project files
    os.cp(path.join(sourcedir, "*"), projectdir) 

    -- get the builtin variables 
    local builtinvars = _get_builtinvars(tempinst, targetname)

    -- replace all variables
    for _, configfile in ipairs(tempinst:get("configfiles")) do
        local pattern = "%${(.-)}"
        io.gsub(configfile, "(" .. pattern .. ")", function(_, variable) 
            variable = variable:trim()
            local value = builtinvars[variable] 
            return type(value) == "function" and value() or value
        end)
    end

    -- generate .gitignore
    os.cp(path.join(os.programdir(), "scripts", "gitignore"), path.join(projectdir, ".gitignore"))
end

-- create project or files from template
function _create_project_or_files(language, templateid, targetname)

    -- check the language
    assert(language, "no language!")

    -- check the template id
    assert(templateid, "no template id!")

    -- load all templates for the given language
    local templates = template.templates(language)

    -- TODO: deprecated
    -- in order to be compatible with the old version template
    local templates_old = { quickapp_qt  = "qt.quickapp", 
                            widgetapp_qt = "qt.widgetapp",
                            console_qt   = "qt.console",
                            static_qt    = "qt.static",
                            shared_qt    = "qt.shared",
                            console_tbox = "tbox.console",
                            static_tbox  = "tbox.static",
                            shared_tbox  = "tbox.shared"}
    if templates_old[templateid] then
--        deprecated.add("template(" .. templates_old[templateid] .. ")", "template(" .. templateid .. ")")
        templateid = templates_old[templateid]
    end

    -- get the given template instance
    local tempinst = nil
    if templates then 
        for _, t in ipairs(templates) do
            if t:name() == templateid then
                tempinst = t
                break
            end
        end
    end
    assert(tempinst and tempinst:scriptdir(), "invalid template id: %s!", templateid)

    -- create project
    local sourcedir = path.join(tempinst:scriptdir(), "project")
    if os.isdir(sourcedir) then
        _create_project(tempinst, sourcedir, targetname)
    else
        raise("template(%s): project and files not found!", templateid)
    end
end


-- main
function main()

    -- enter the original working directory, because the default directory is in the project directory 
    os.cd(os.workingdir())

    -- the target name
    local targetname = option.get("target") or option.get("name") or path.basename(project.directory()) or "demo"

    -- trace
    cprint("${bright}create %s ...", targetname)

    -- create project or files from template
    _create_project_or_files(option.get("language"), option.get("template"), targetname)

    -- trace
    cprint("${bright}create ok!${ok_hand}")
end
