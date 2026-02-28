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

function builtinvars(targetname)
    return {TARGETNAME = targetname,
            FAQ = function() return io.readfile(path.join(os.programdir(), "scripts", "faq.lua")) end}
end

function replace_variables_in_string(s, vars)
    local pattern = "%${(.-)}"
    return (s:gsub(pattern, function (variable)
        variable = variable:trim()
        local value = vars[variable]
        if value == nil then
            return "${" .. variable .. "}"
        end
        return type(value) == "function" and value() or tostring(value)
    end))
end

function is_binary_file(filepath)
    local file = io.open(filepath, "rb")
    if not file then
        return false
    end
    local data = file:read(4096) or ""
    file:close()
    return data:find("\0", 1, true) ~= nil
end

function templatedir(lang, templateid)
    assert(lang)
    assert(templateid)
    return path.join(os.programdir(), "templates", lang, templateid)
end

function copy_files(sourcedir, projectdir, vars)
    local createdfiles = {}
    for _, srcfile in ipairs(os.files(path.join(sourcedir, "**"))) do
        local relpath = path.relative(srcfile, sourcedir)
        if relpath ~= "template.lua" then
            local dstrelpath = replace_variables_in_string(relpath, vars)
            local dstfile = path.absolute(path.join(projectdir, dstrelpath))
            os.mkdir(path.directory(dstfile))
            os.cp(srcfile, dstfile, {writeable = true})
            table.insert(createdfiles, dstfile)
        end
    end
    return createdfiles
end

function replace_variables_in_files(files, vars)
    local pattern = "%${(.-)}"
    for _, file in ipairs(files) do
        if os.isfile(file) and not is_binary_file(file) then
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

function languages()
    local languages = {}
    local languages_dirs = os.dirs(path.join(os.programdir(), "templates", "*"))
    if languages_dirs then
        for _, d in ipairs(languages_dirs) do
            table.insert(languages, path.basename(d))
        end
    end
    table.sort(languages)
    return languages
end

function templates(lang)
    assert(lang)
    local results = {}
    local templateroot = path.join(os.programdir(), "templates", lang)
    local templatedirs = os.dirs(path.join(templateroot, "*"))
    if templatedirs then
        for _, templatedir in ipairs(templatedirs) do
            if os.isfile(path.join(templatedir, "xmake.lua")) then
                table.insert(results, path.filename(templatedir))
            end
        end
    end
    table.sort(results)
    return results
end

function languages_for_template(templateid)
    local accepted = {}
    for _, l in ipairs(languages()) do
        if os.isdir(path.join(os.programdir(), "templates", l, templateid)) then
            table.insert(accepted, l)
        end
    end
    return accepted
end

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
