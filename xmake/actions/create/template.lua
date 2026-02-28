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

import("core.base.global")
import("core.base.hashset")

function builtinvars(targetname)
    return {TARGETNAME = targetname,
            FAQ = function() return io.readfile(path.join(os.programdir(), "scripts", "faq.lua")) end}
end

-- get template root directories
function rootdirs()
    local results = {}
    local dir = path.join(global.directory(), "templates")
    if os.isdir(dir) then
        table.insert(results, dir)
    end
    dir = path.join(os.programdir(), "templates")
    if os.isdir(dir) and not table.contains(results, dir) then
        table.insert(results, dir)
    end
    return results
end

-- get template root directory
function templatedir(lang, templateid)
    assert(lang)
    assert(templateid)
    for _, rootdir in ipairs(rootdirs()) do
        local dir = path.join(rootdir, lang, templateid)
        if os.isdir(dir) then
            return dir
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

-- replace variables in files
function replace_variables_in_files(files, vars)
    local pattern = "%${(.-)}"
    for _, file in ipairs(files) do
        if os.isfile(file) and path.filename(file) == "xmake.lua" then
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
                local name = path.filename(d)
                found:insert(name)
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
        local templatedirs = os.dirs(path.join(templateroot, "*"))
        if templatedirs then
            for _, templatedir in ipairs(templatedirs) do
                if os.isfile(path.join(templatedir, "xmake.lua")) then
                    local name = path.filename(templatedir)
                    found:insert(name)
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
        for _, rootdir in ipairs(rootdirs()) do
            if os.isdir(path.join(rootdir, lang, templateid)) then
                table.insert(accepted, lang)
                break
            end
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
