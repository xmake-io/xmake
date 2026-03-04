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
-- @file        template.lua
--

-- imports
import("core.base.global")
import("core.base.hashset")
import("core.language.language")
import("core.package.repository")

-- some builtin template variables in xmake.lua
function builtinvars(targetname)
    return {TARGET_NAME = targetname,
            FAQ = function() return io.readfile(path.join(os.programdir(), "scripts", "faq.lua")) end}
end

-- get all template roots with extra meta information
--
-- priority:
--   1. repo:     <global-repo>/templates (including builtin repo templates)
--   2. global:   <globaldir>/templates
function rootinfos()
    local results = {}

    -- get template directories from global repositories
    local repos = repository.repositories({global = true, network = false})
    if repos then
        for _, repo in ipairs(repos) do
            local templatesdir = path.join(repo:directory(), "templates")
            if os.isdir(templatesdir) then
                table.insert(results, {kind = "repo", name = repo:name(), url = repo:url(), branch = repo:branch(), dir = templatesdir})
            end
        end
    end

    -- get template directories from global and builtin
    local dir = path.join(global.directory(), "templates")
    if os.isdir(dir) then
        table.insert(results, {kind = "global", dir = dir})
    end
    return results
end

-- get template root directories
function rootdirs()
    local results = {}
    for _, info in ipairs(rootinfos()) do
        table.insert(results, info.dir)
    end
    return results
end

-- get template root directory
function _templateid_subdir(templateid)
    local items = templateid:split(".", {plain = true})
    if not items or #items == 0 then
        return
    end
    for _, item in ipairs(items) do
        if #item == 0 then
            return
        end
    end
    return path.join(table.unpack(items))
end

function templatedir(lang, templateid)
    assert(lang)
    assert(templateid)
    for _, rootdir in ipairs(rootdirs()) do
        local subdir = _templateid_subdir(templateid)
        if subdir then
            local dir = path.join(rootdir, lang, subdir)
            if os.isfile(path.join(dir, "xmake.lua")) then
                return dir
            end
        end
    end
end

-- copy template files to project directory
function copy_files(sourcedir, projectdir)
    local createdfiles = {}
    for _, srcfile in ipairs(os.files(path.join(sourcedir, "**"))) do
        local relpath = path.relative(srcfile, sourcedir)
        local dstfile = path.absolute(path.join(projectdir, relpath))
        os.mkdir(path.directory(dstfile))
        os.cp(srcfile, dstfile, {writeable = true})
        table.insert(createdfiles, dstfile)
    end
    return createdfiles
end

-- only replace variables in template source files and xmake.lua
function _need_replace_variables(filepath)
    if not os.isfile(filepath) then
        return false
    end
    if path.filename(filepath):lower() == "xmake.lua" then
        return true
    end
    local extension = path.extension(filepath)
    if extension then
        return language.extensions()[extension:lower()] ~= nil
    end
end

-- replace variables in files
function replace_variables_in_files(files, vars)
    local pattern = "%${(.-)}"
    for _, file in ipairs(files) do
        if _need_replace_variables(file) then
            io.gsub(file, "(" .. pattern .. ")", function(_, variable)
                variable = variable:trim()
                local value = vars[variable]
                if value == nil then
                    return "${" .. variable .. "}"
                end
                return type(value) == "function" and value() or tostring(value)
            end, {encoding = "binary"})
        end
    end
end

-- get all languages from templates
function languages()
    local found = hashset.new()
    for _, rootdir in ipairs(rootdirs()) do
        local languages_dirs = os.dirs(path.join(rootdir, "*"))
        if languages_dirs then
            for _, d in ipairs(languages_dirs) do
                found:insert(path.filename(d))
            end
        end
    end
    local results = found:to_array()
    table.sort(results)
    return results
end

-- get all templates for the given language
function templates(lang)
    assert(lang)
    local found = hashset.new()
    for _, rootdir in ipairs(rootdirs()) do
        local templateroot = path.join(rootdir, lang)
        local configfiles = os.files(path.join(templateroot, "**", "xmake.lua"))
        if configfiles then
            local templatedirs = {}
            for _, configfile in ipairs(configfiles) do
                local templatedir = path.directory(configfile)
                local relpath = path.relative(templatedir, templateroot)
                if relpath and relpath ~= "." then
                    table.insert(templatedirs, {dir = templatedir, relpath = relpath})
                end
            end
            table.sort(templatedirs, function(a, b) return #a.relpath < #b.relpath end)
            local accepted = {}
            for _, item in ipairs(templatedirs) do
                local ok = true
                for _, root in ipairs(accepted) do
                    if item.dir:startswith(root .. path.sep()) then
                        ok = false
                        break
                    end
                end
                if ok then
                    table.insert(accepted, item.dir)
                    found:insert((item.relpath:gsub("[/\\]", ".")))
                end
            end
        end
    end
    local results = found:to_array()
    table.sort(results)
    return results
end

-- get languages for the given template
function languages_for_template(templateid)
    local accepted = {}
    for _, lang in ipairs(languages()) do
        if templatedir(lang, templateid) then
            table.insert(accepted, lang)
        end
    end
    return accepted
end

-- get templates with all supported languages
function templates_with_languages()
    local templates_map = {}
    for _, lang in ipairs(languages()) do
        for _, name in ipairs(templates(lang)) do
            templates_map[name] = templates_map[name] or {}
            if not table.contains(templates_map[name], lang) then
                table.insert(templates_map[name], lang)
            end
        end
    end
    return templates_map
end
