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
-- @file        tidy.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("core.base.semver")
import("core.project.config")
import("core.project.project")
import("lib.detect.find_tool")
import("async.runjobs")
import("utils.progress")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")

-- the clang.tidy options
local options = {
    {"l", "list",       "k",  nil,  "Show the clang-tidy checks list."},
    {"j", "jobs",       "kv", tostring(os.default_njob()),
                                    "Set the number of parallel check jobs."},
    {"q", "quiet",      "k",  nil,  "Run clang-tidy in quiet mode."},
    {"v", "verbose",    "k",  nil,  "Print lots of verbose information for users."},
    {"D", "diagnosis",  "k",  nil,  "Print lots of diagnosis information (backtrace, check info ..) only for developers."},
    {nil, "fix",        "k",  nil,  "Apply suggested fixes."},
    {nil, "fix_errors", "k",  nil,  "Apply suggested errors fixes."},
    {nil, "fix_notes",  "k",  nil,  "Apply suggested notes fixes."},
    {nil, "create",     "k",  nil,  "Create a .clang-tidy file."},
    {nil, "configfile", "kv", nil,  "Specify the path of .clang-tidy or custom config file."},
    {nil, "compdb",     "kv", nil,  "Specify the path of the compile_commands.json file or the directory containing the file."},
    {nil, "checks",     "kv", nil,  "Set the given checks.",
                                    "e.g.",
                                    "    - xmake check clang.tidy --checks=\"*\""},
    {"f", "files",      "kv", nil,  "Set files path with pattern",
                                    "e.g.",
                                    "    - xmake check clang.tidy -f src/main.c",
                                    "    - xmake check clang.tidy -f 'src/*.c" .. path.envsep() .. "src/**.cpp'"},
    {nil, "targets",    "vs",  nil,  "Check the sourcefiles of the given target.",
                                    ".e.g",
                                    "    - xmake check clang.tidy",
                                    "    - xmake check clang.tidy [targets]"}
}

-- show checks list
function _show_list(clang_tidy)
    os.execv(clang_tidy, {"--list-checks"})
end

-- create .clang-tidy config file
function _create_config(clang_tidy, opt)
    local projectdir = project.directory()
    local argv = {"--dump-config"}
    if opt.checks then
        table.insert(argv, "--checks=" .. opt.checks)
    end
    os.execv(clang_tidy, argv, {stdout = path.join(projectdir, ".clang-tidy"), curdir = projectdir})
end

-- add sourcefiles in target
function _add_target_files(sourcefiles, target)
    for _, sourcebatch in pairs(target:sourcebatches()) do
        -- we can only use rulename to filter them because sourcekind may be bound to multiple rules
        local rulename = sourcebatch.rulename
        if rulename == "c.build" or rulename == "c++.build"
            or rulename == "objc.build" or rulename == "objc++.build"
            or rulename == "cuda.build" or rulename == "c++.build.modules" then
            table.join2(sourcefiles, sourcebatch.sourcefiles)
        end
    end
end

-- get clang-tidy
function _get_clang_tidy()
    local clang_tidy = find_tool("clang-tidy")
    if clang_tidy then
        return clang_tidy
    end

    -- enter the environments of llvm
    local oldenvs = packagenv.enter("llvm")

    -- find clang-tidy
    local packages = {}
    local clang_tidy = find_tool("clang-tidy")
    if not clang_tidy then
        table.join2(packages, install_packages("llvm"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need to force detect and flush detect cache after loading all environments
    if not clang_tidy then
        clang_tidy = find_tool("clang-tidy", {force = true})
    end

    os.setenvs(oldenvs)
    return clang_tidy
end

-- get compile_commands.json file
function _get_compdb_file(opt)
    local db_path = opt.compdb
    if not db_path then
        -- @see https://github.com/xmake-io/xmake/issues/5583#issuecomment-2337696628
        local outputdir
        local extraconf = project.extraconf("target.rules", "plugin.compile_commands.autoupdate")
        if extraconf then
            outputdir = extraconf.outputdir
        end
        if outputdir then
            db_path = path.join(outputdir, "compile_commands.json")
        end
    end
    if not db_path then
        db_path = "compile_commands.json"
    end
    if os.isdir(db_path) then
        local db_file_path = path.join(db_path, "compile_commands.json")
        if os.isfile(db_file_path) then
            db_path = db_file_path
        end
    end
    if not os.isfile(db_path) then
        local outputdir = os.tmpfile() .. ".dir"
        local filename = path.filename(db_path)
        db_path = outputdir and path.join(outputdir, filename) or filename
        task.run("project", {quiet = true, kind = "compile_commands", lsp = "clangd", outputdir = outputdir})
    end
    return path.absolute(db_path)
end

-- check a single sourcefile
function _check_sourcefile(clang_tidy, sourcefile, opt)
    progress.show(opt.progress, "clang-tidy.analyzing %s", sourcefile)
    try
    {
        function ()
            local outdata, errdata = os.iorunv(clang_tidy.program, opt.tidy_argv, {curdir = opt.projectdir})
            return (outdata or "") .. (errdata or "")
        end,
        catch
        {
            function (errors)
                -- execution failed or returned non-zero
                local error_text = ""
                if type(errors) == "table" then
                    error_text = (errors.stdout or "") .. (errors.stderr or "")
                    if #error_text:trim() == 0 then
                        error_text = errors.errors or "check failed"
                    end
                else
                    error_text = tostring(errors)
                end
                progress.show_output("${color.error}%s:\n%s", sourcefile, error_text)
                progress.show_abort()
                raise(error_text)
            end
        },
        finally
        {
            function (ok, outdata, errdata)
                -- show output if any
                if ok then
                    local output = (outdata or "") .. (errdata or "")
                    if output and #output:trim() > 0 then
                        progress.show_output("${color.warning}%s:\n%s", sourcefile, output)
                    end
                end
            end
        }
    }
end

-- check sourcefiles
function _check_sourcefiles(clang_tidy, sourcefiles, opt)
    opt = opt or {}
    local projectdir = project.directory()
    local argv = {}
    if opt.checks then
        table.insert(argv, "--checks=" .. opt.checks)
    end
    if opt.fix then
        table.insert(argv, "--fix")
    end
    if opt.fix_errors then
        table.insert(argv, "--fix-errors")
    end
    if opt.fix_notes then
        table.insert(argv, "--fix-notes")
    end
    if opt.compdbfile then
        table.insert(argv, "-p")
        table.insert(argv, opt.compdbfile)
    end
    if opt.configfile then
        table.insert(argv, "--config-file=" .. opt.configfile)
    end
    if opt.quiet then
        table.insert(argv, "--quiet")
    end

    -- run clang-tidy
    local analyze_time = os.mclock()
    local runjobs_opt = {
        total = #sourcefiles,
        comax = opt.jobs or os.default_njob(),
        showtips = false,
        progress_refresh = true
    }
    runjobs("checker.tidy", function (index, total, job_opt)
        local sourcefile = sourcefiles[index]
        local tidy_argv = table.join(argv, {sourcefile})
        _check_sourcefile(clang_tidy, sourcefile, {
            tidy_argv = tidy_argv,
            projectdir = projectdir,
            progress = job_opt.progress
        })
    end, runjobs_opt)
    analyze_time = os.mclock() - analyze_time
    progress.show(100, "${color.success}clang-tidy analyzed %d files, spent %.3fs", #sourcefiles, analyze_time / 1000)
end

-- do check
function _check(clang_tidy, opt)
    opt = opt or {}

    -- generate compile_commands.json first
    opt.compdbfile = _get_compdb_file(opt)

    -- save option context
    option.save()

    -- set verbose and diagnosis if specified
    if opt.verbose then
        option.set("verbose", true)
    end
    if opt.diagnosis then
        option.set("diagnosis", true)
    end

    -- get sourcefiles
    local sourcefiles = {}
    if opt.files then
        local files = path.splitenv(opt.files)
        for _, file in ipairs(files) do
            for _, filepath in ipairs(os.files(file)) do
                table.insert(sourcefiles, filepath)
            end
        end
    else
        local targetnames = opt.targets
        if targetnames then
            for _, targetname in ipairs(targetnames) do
                local target = assert(project.target(targetname), "unknown target(%s)", targetname)
                _add_target_files(sourcefiles, target)
            end
        else
            for _, target in ipairs(project.ordertargets()) do
                _add_target_files(sourcefiles, target)
            end
        end
    end

    -- check files
    _check_sourcefiles(clang_tidy, sourcefiles, opt)

    -- restore option context
    option.restore()
end

function main(argv)

    -- parse arguments
    local args = option.parse(argv or {}, options, "Use clang-tidy to check project code."
                                           , ""
                                           , "Usage: xmake check clang.tidy [options]")

    -- find clang-tidy
    local clang_tidy = _get_clang_tidy()
    assert(clang_tidy, "clang-tidy not found!")

    -- list checks
    if args.list then
        _show_list(clang_tidy.program)
    elseif args.create then
        _create_config(clang_tidy.program, args)
    else
        _check(clang_tidy, args)
    end
end

