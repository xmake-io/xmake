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
import("core.base.hashset")
import("core.project.config")
import("core.project.project")
import("lib.detect.find_tool")
import("async.runjobs")
import("utils.progress")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")
import("private.action.utils", {alias = "action_utils"})

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
                local exclude = path.translate(exclude)
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

-- tell if the source batch is a c/c++/objc/objc++/cuda/qt source batch
function _source_batch_should_format(sourcebatch)
    local rulename = sourcebatch.rulename
    local matched_rules = {"c.build", "c++.build", "c++.build.modules", "cuda.build", "objc.build", "objc++.build", "qt.moc", "qt.qmltyperegistrar"}
    return table.contains(matched_rules, rulename)
end

-- check whether a file is inside the given directory
function _is_in_directory(file, dir)
    if not file or not dir then
        return false
    end
    file = path.normalize(file)
    dir = path.normalize(dir)
    if not os.fscase() then
        file = file:lower()
        dir = dir:lower()
    end
    local sep = path.sep()
    if not dir:endswith(sep) then
        dir = dir .. sep
    end
    return file:startswith(dir)
end

-- add a source file if valid, matched, and not duplicated
function _add_sourcefile(sourcefiles, sourcefiles_set, file, projectdir, autogendir, filepatterns)
    local abs_file = path.normalize(path.absolute(file, projectdir))
    if autogendir and _is_in_directory(abs_file, autogendir) then
        return
    end
    local key = not os.fscase() and abs_file:lower() or abs_file
    if sourcefiles_set:has(key) then
        return
    end
    if filepatterns then
        local rel_file = path.relative(abs_file, projectdir)
        local matched = _match_sourcefiles(rel_file, filepatterns)
        if matched == nil then
            matched = _match_sourcefiles(abs_file, filepatterns)
        end
        if not matched then
            return
        end
    end
    if not os.isfile(abs_file) then
        return
    end
    sourcefiles_set:insert(key)
    table.insert(sourcefiles, abs_file)
end

-- collect source files to format
function _collect_sourcefiles(targets, projectdir, filepatterns)
    local sourcefiles = {}
    local sourcefiles_set = hashset.new()
    for _, target in ipairs(targets) do
        local autogendir = target:autogendir({root = true})
        if autogendir then
            autogendir = path.normalize(path.absolute(autogendir, projectdir))
        end
        for _, sourcebatch in pairs(target:sourcebatches()) do
            if _source_batch_should_format(sourcebatch) then
                for _, source in ipairs(sourcebatch.sourcefiles) do
                    _add_sourcefile(sourcefiles, sourcefiles_set, source, projectdir, autogendir, filepatterns)
                end
            end
        end
        for _, header in ipairs(target:headerfiles()) do
            _add_sourcefile(sourcefiles, sourcefiles_set, header, projectdir, autogendir, filepatterns)
        end
    end
    return sourcefiles
end

-- main
function main()

    -- @note we cannot use utils.warning() here, it's queued and only shown at the end
    cprint("${bright color.warning}${text.warning}: ${color.warning}the builtin `xmake format` plugin is deprecated, " ..
           "please use the format-plugin addon: `xmake addon --install format-plugin`")

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

    -- collect sourcefiles
    local targetnames, group_pattern = action_utils.get_targets_and_group()
    local targets = action_utils.get_targets(targetnames, {group_pattern = group_pattern})
    local filepatterns = option.get("files") and _get_file_patterns(option.get("files")) or nil
    local sourcefiles = _collect_sourcefiles(targets, projectdir, filepatterns)

    -- format files in parallel
    if #sourcefiles > 0 then
        local jobs = tonumber(option.get("jobs"))
        if not jobs or jobs <= 0 then
            jobs = os.default_njob()
        end
        local format_time = os.mclock()
        local runjobs_opt = {
            total = #sourcefiles,
            comax = jobs,
            showtips = false,
            progress_refresh = true
        }
        runjobs("clang-format", function (index, total, opt)
            local sourcefile = sourcefiles[index]
            local format_argv = table.join(argv, {sourcefile})
            progress.show(opt.progress, "clang-format.formatting %s", sourcefile)
            os.execv(clang_format.program, format_argv, {curdir = projectdir})
        end, runjobs_opt)
        format_time = os.mclock() - format_time
        progress.show(100, "${color.success}clang-format formatted %d files, spent %.3fs", #sourcefiles, format_time / 1000)
    end
    os.setenvs(oldenvs)
end
