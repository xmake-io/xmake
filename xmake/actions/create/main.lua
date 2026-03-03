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

-- validate template component against path traversal
function _validate_template_component(name, value)
    if #value == 0 or value == "." or value == ".."
        or value:find("/", 1, true) or value:find("\\", 1, true)
        or value:find(":", 1, true) or value:find("\0", 1, true) then
        raise("invalid %s: %s!", name, value)
    end
end

-- get template language from template id
function _get_language_from_template(templateid)
    local lang = option.get("language")
    if lang then
        _validate_template_component("language", lang)
    end
    if not templateid or not lang or template.templatedir(lang, templateid) then
        return lang
    end
    local langs = template.languages_for_template(templateid)
    if #langs == 1 then
        return langs[1]
    elseif #langs > 1 then
        raise("template(%s): please pass -l/--language, supported languages: %s", templateid, table.concat(langs, ", "))
    end
    return lang
end

-- get template id from command line options
function _get_templateid()
    local templateid = option.get("template")
    _validate_template_component("template id", templateid)
    return templateid
end

-- get target name from command line options
function _get_targetname()
    return option.get("target") or path.basename(project.directory()) or "demo"
end

-- list all supported templates for each language
function _list_templates(lang_filter)
    local languages = template.languages()
    if lang_filter then
        _validate_template_component("language", lang_filter)
        if not table.contains(languages, lang_filter) then
            raise("unknown language(%s), supported languages: %s", lang_filter, table.concat(languages, ", "))
        end
        languages = {lang_filter}
    end
    for _, lang in ipairs(languages) do
        cprint("${bright}%s${reset}", lang)
        local templates = template.templates(lang)
        if templates and #templates > 0 then
            for _, name in ipairs(templates) do
                cprint("  - %s", name)
            end
        end
        print("")
    end
end

-- create project from template
function _create_project(lang, templateid, targetname)
    assert(targetname ~= ".", "you should specify ${red}-P${reset} instead of directly using ${red}.${reset}")
    assert(lang, "no language!")
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
    local sourcedir = template.templatedir(lang, templateid)
    assert(sourcedir, "template(%s/%s): not found!", lang, templateid)

    -- get the builtin variables
    local builtinvars = template.builtinvars(targetname)

    -- copy template project files
    local createdfiles = template.copy_files(sourcedir, projectdir)

    -- copy the default .gitignore
    if not os.isfile(path.join(projectdir, ".gitignore")) then
        os.cp(path.join(os.programdir(), "scripts", "gitignore"), path.join(projectdir, ".gitignore"))
        table.insert(createdfiles, path.join(projectdir, ".gitignore"))
    end

    -- replace template variables
    template.replace_variables_in_files(createdfiles, builtinvars)

    -- done
    table.sort(createdfiles)
    for _, file in ipairs(createdfiles) do
        cprint("  ${green}[+]: ${clear}%s", path.relative(file, projectdir))
    end
end

function main()
    os.cd(os.workingdir())

    -- `xmake create --list` only prints available templates and exits.
    if option.get("list") then
        local explicit_language = option.options() and option.options().language
        _list_templates(explicit_language)
        return
    end

    local targetname = _get_targetname()
    local templateid = _get_templateid()
    local lang = _get_language_from_template(templateid)

    -- create project from template
    cprint("${bright}create %s ...", targetname)
    _create_project(lang, templateid, targetname)
    cprint("${color.success}create ok!")
end
