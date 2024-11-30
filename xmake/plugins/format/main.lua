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
import("core.base.hashset")
import("core.project.config")
import("core.project.project")
import("lib.detect.find_tool")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")

-- match source files
function _match_sourcefiles(sourcefile, filepatterns)
    for _, filepattern in ipairs(filepatterns) do
        if sourcefile:match(filepattern.pattern) == sourcefile then
            if filepattern.excludes then
                if filepattern.rootdir and sourcefile:startswith(filepattern.rootdir) then
                    sourcefile = sourcefile:sub(#filepattern.rootdir + 2)
                end
                for _, exclude in ipairs(filepattern.excludes) do
                    if sourcefile:match(exclude) == sourcefile then
                        return false
                    end
                end
            end
            return true
        end
    end
end

-- convert all sourcefiles to lua pattern
function _get_file_patterns(sourcefiles)
    local patterns = {}
    for _, sourcefile in ipairs(path.splitenv(sourcefiles)) do

        -- get the excludes
        local pattern  = sourcefile:trim()
        local excludes = pattern:match("|.*$")
        if excludes then excludes = excludes:split("|", {plain = true}) end

        -- translate excludes
        if excludes then
            local _excludes = {}
            for _, exclude in ipairs(excludes) do
                exclude = path.translate(exclude)
                exclude = path.pattern(exclude)
                table.insert(_excludes, exclude)
            end
            excludes = _excludes
        end

        -- translate path and remove some repeat separators
        pattern = path.translate((pattern:gsub("|.*$", "")))

        -- remove "./" or '.\\' prefix
        if pattern:sub(1, 2):find('%.[/\\]') then
            pattern = pattern:sub(3)
        end

        -- get the root directory
        local rootdir = pattern
        local startpos = pattern:find("*", 1, true)
        if startpos then
            rootdir = rootdir:sub(1, startpos - 1)
        end
        rootdir = path.directory(rootdir)

        -- convert to lua path pattern
        pattern = path.pattern(pattern)
        table.insert(patterns, {pattern = pattern, excludes = excludes, rootdir = rootdir})
    end
    return patterns
end

-- get all the targets that match the group or targetname
function _get_targets(targetname, group_pattern)
    local targets = {}
    if targetname then
        table.insert(targets, project.target(targetname))
    else
        for _, target in pairs(project.targets()) do
            local group = target:get("group")
            if (target:is_default() and not group_pattern) or option.get("all") or (group_pattern and group and group:match(group_pattern)) then
                table.insert(targets, target)
            end
        end
    end
    return targets
end

-- main
function main()

    -- load configuration
    config.load()

    -- enter the environments of llvm
    local oldenvs = packagenv.enter("llvm")

    -- find clang-format
    local packages = {}
    local clang_format = find_tool("clang-format")
    if not clang_format then
        table.join2(packages, install_packages("llvm"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need to force detect and flush detect cache after loading all environments
    if not clang_format then
        clang_format = find_tool("clang-format", {force = true})
    end
    assert(clang_format, "clang-format not found!")

    -- create style file
    local argv = {}
    local projectdir = project.directory()
    if option.get("create") then
        table.insert(argv, "--style=" .. (option.get("style") or "Google"))
        table.insert(argv, "--dump-config")
        os.execv(clang_format.program, argv, {stdout = path.join(projectdir, ".clang-format"), curdir = projectdir})
        return
    end

    -- set style file
    if option.get("style") then
        table.insert(argv, "--style=" .. option.get("style"))
    end

    if option.get("dry-run") then
        -- do not make any changes, just show the files that would be formatted
        table.insert(argv, "--dry-run")
    else
        -- inplace flag
        table.insert(argv, "-i")
    end

    -- changes formatting warnings to errors
    if option.get("error") then
        table.insert(argv, "--Werror")
    end

    -- print verbose information
    if option.get("verbose") then
        table.insert(argv, "--verbose")
    end

    local targetname
    local group_pattern = option.get("group")
    if group_pattern then
        group_pattern = "^" .. path.pattern(group_pattern) .. "$"
    else
        targetname = option.get("target")
    end

    local targets = _get_targets(targetname, group_pattern)
    if option.get("files") then
        local filepatterns = _get_file_patterns(option.get("files"))
        for _, target in ipairs(targets) do
            for _, source in ipairs(target:sourcefiles()) do
                if _match_sourcefiles(source, filepatterns) then
                    table.insert(argv, path.join(projectdir, source))
                end
            end
            for _, header in ipairs(target:headerfiles()) do
                if _match_sourcefiles(header, filepatterns) then
                    table.insert(argv, path.join(projectdir, header))
                end
            end
        end
    else
        for _, target in ipairs(targets) do
            for _, source in ipairs(target:sourcefiles()) do
                table.insert(argv, path.join(projectdir, source))
            end
            for _, header in ipairs(target:headerfiles()) do
                table.insert(argv, path.join(projectdir, header))
            end
        end
    end

    -- format files
    os.vrunv(clang_format.program, argv, {curdir = projectdir})
    cprint("${color.success}format ok!")

    -- done
    os.setenvs(oldenvs)
end
