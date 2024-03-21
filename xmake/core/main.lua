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

-- define module: main
local main = main or {}

-- load modules
local env           = require("base/compat/env")
local os            = require("base/os")
local log           = require("base/log")
local path          = require("base/path")
local utils         = require("base/utils")
local option        = require("base/option")
local table         = require("base/table")
local global        = require("base/global")
local privilege     = require("base/privilege")
local task          = require("base/task")
local colors        = require("base/colors")
local process       = require("base/process")
local scheduler     = require("base/scheduler")
local theme         = require("theme/theme")
local config        = require("project/config")
local project       = require("project/project")
local localcache    = require("cache/localcache")
local profiler      = require("base/profiler")
local debugger      = require("base/debugger")

-- init the option menu
local menu =
{
    title = "${bright}xmake v" .. _VERSION .. ", A cross-platform build utility based on " .. (xmake._LUAJIT and "LuaJIT" or "Lua") .. "${clear}"
,   copyright = "Copyright (C) 2015-present Ruki Wang, ${underline}tboox.org${clear}, ${underline}xmake.io${clear}"

    -- the tasks: xmake [task]
,   function ()
        local tasks = task.tasks() or {}
        local ok, project_tasks = pcall(project.tasks)
        if ok then
            table.join2(tasks, project_tasks)
        end
        return task.menu(tasks)
    end

}

-- show help and version info
function main._show_help()
    if option.get("help") then
        option.show_menu(option.taskname())
        return true
    elseif option.get("version") and not option.taskname() then
        if menu.title then
            utils.cprint(menu.title)
        end
        if menu.copyright then
            utils.cprint(menu.copyright)
        end
        option.show_logo()
        return true
    end
end

-- find the root project file
function main._find_root(projectfile)

    -- make all parent directories
    local dirs = {}
    local dir = path.directory(projectfile)
    while os.isdir(dir) do
        table.insert(dirs, 1, dir)
        local parentdir = path.directory(dir)
        if parentdir and parentdir ~= dir and parentdir ~= '.' then
            dir = parentdir
        else
            break
        end
    end

    -- find the first `xmake.lua` from it's parent directory
    for _, dir in ipairs(dirs) do
        local file = path.join(dir, "xmake.lua")
        if os.isfile(file) then
           return file
        end
    end
    return projectfile
end

-- get project directory and project file from the argument option
--
-- @note we need to put `-P` in the first argument avoid option.parse() parsing errors
-- e.g. `xmake f -c -P xxx` will be parsed as `-c=-P`, it's incorrect.
--
-- @see https://github.com/xmake-io/xmake/issues/4857
--
function main._basicparse()

    -- check command
    if xmake._ARGV[1] and not xmake._ARGV[1]:startswith('-') then
        -- regard it as command name
        xmake._COMMAND = xmake._ARGV[1]
        xmake._COMMAND_ARGV = table.move(xmake._ARGV, 2, #xmake._ARGV, 1, table.new(#xmake._ARGV - 1, 0))
    else
        xmake._COMMAND_ARGV = xmake._ARGV
    end

    -- parse options, only parse -P xxx/-F xxx/--project=xxx/--file=xxx
    local options = {}
    local argv = xmake._COMMAND_ARGV
    local idx = 1
    while idx <= #argv do
        local arg = argv[idx]
        if arg == "-P" and idx < #argv then
            options.project = argv[idx + 1]
            idx = idx + 1
        elseif arg == "-F" and idx < #argv then
            options.file = argv[idx + 1]
            idx = idx + 1
        elseif arg:startswith("--project=") then
            options.project = arg:sub(11)
        elseif arg:startswith("--file=") then
            options.file = arg:sub(8)
        end
        idx = idx + 1
        if options.project and options.file then
            break
        end
    end
    return options
end

-- get the project configuration from cache if we are in the independent working directory
-- @see https://github.com/xmake-io/xmake/issues/3342
--
function main._projectconf(name)
    local rootdir = os.getenv("XMAKE_CONFIGDIR")
    -- we switch to independent working directory
    -- @see https://github.com/xmake-io/xmake/issues/820
    if not rootdir and os.isdir(path.join(os.workingdir(), "." .. xmake._NAME)) then
        rootdir = os.workingdir()
    end
    local cachefile = path.join(rootdir, "." .. xmake._NAME, os.host(), os.arch(), "cache", "project")
    if os.isfile(cachefile) then
        local cacheinfo = io.load(cachefile)
        if cacheinfo then
            return cacheinfo[name]
        end
    end
end

-- the init function for main
function main._init()

    -- start debugger
    if debugger:enabled() then
        local ok, errors = debugger:start()
        if not ok then
            return false, errors
        end
    end

    -- disable scheduler first
    scheduler:enable(false)

    -- get project directory and project file from the argument option
    local options, errors = main._basicparse()
    if not options then
        return false, errors
    end

    -- init project paths only for xmake engine
    if xmake._NAME == "xmake" then
        local opt_projectdir, opt_projectfile = options.project, options.file

        -- init the project directory
        local projectdir = opt_projectdir or main._projectconf("projectdir") or xmake._PROJECT_DIR
        if projectdir and not path.is_absolute(projectdir) then
            projectdir = path.absolute(projectdir)
        elseif projectdir then
            projectdir = path.translate(projectdir)
        end
        xmake._PROJECT_DIR = projectdir
        assert(projectdir)

        -- init the xmake.lua file path
        local projectfile = opt_projectfile or main._projectconf("projectfile") or xmake._PROJECT_FILE
        if projectfile and not path.is_absolute(projectfile) then
            projectfile = path.absolute(projectfile, projectdir)
        end
        xmake._PROJECT_FILE = projectfile
        assert(projectfile)

        -- find the root project file
        if not os.isfile(projectfile) or (not opt_projectdir and not opt_projectfile) then
            projectfile = main._find_root(projectfile)
        end

        -- update and enter project
        xmake._PROJECT_DIR  = path.directory(projectfile)
        xmake._PROJECT_FILE = projectfile

        -- enter the project directory
        if os.isdir(os.projectdir()) then
            os.cd(os.projectdir())
        end
    else
        -- patch a fake project file and directory for other lua programs with xmake/engine
        xmake._PROJECT_DIR  = path.join(os.tmpdir(), "local")
        xmake._PROJECT_FILE = path.join(xmake._PROJECT_DIR, xmake._NAME .. ".lua")
    end
    return true
end

-- exit main program
function main._exit(ok, errors)

    -- run all exit callbacks
    os._run_exit_cbs(ok, errors)

    -- show errors
    local retval = 0
    if not ok then
        retval = -1
        if errors then
            utils.error(errors)
        end
    end

    -- show warnings
    utils.show_warnings()

    -- close log
    log:close()

    -- return exit code
    return retval
end

-- limit root? @see https://github.com/xmake-io/xmake/pull/4513
function main._limit_root()
    return not option.get("root") and os.getenv("XMAKE_ROOT") ~= 'y' and os.host() ~= 'haiku'
end

-- the main entry function
function main.entry()

    -- init
    local ok, errors = main._init()
    if not ok then
        return main._exit(ok, errors)
    end

    -- load global configuration
    ok, errors = global.load()
    if not ok then
        return main._exit(ok, errors)
    end

    -- load theme
    local theme_inst = theme.load(os.getenv("XMAKE_THEME") or global.get("theme")) or theme.load("default")
    if theme_inst then
        colors.theme_set(theme_inst)
    end

    -- init option
    ok, errors = option.init(menu)
    if not ok then
        return main._exit(ok, errors)
    end

    -- check run command as root
    if main._limit_root() then
        if os.isroot() then
            errors = [[Running xmake as root is extremely dangerous and no longer supported.
As xmake does not drop privileges on installation you would be giving all
build scripts full access to your system.
Or you can add `--root` option or XMAKE_ROOT=y to allow run as root temporarily.
            ]]
            return main._exit(false, errors)
        end
    end

    -- show help?
    if main._show_help() then
        return main._exit(true)
    end

    -- save command lines to history and we need to make sure that the .xmake directory is not generated everywhere
    local skip_history = (os.getenv('XMAKE_SKIP_HISTORY') or ''):trim()
    if os.projectfile() and os.isfile(os.projectfile()) and os.isdir(config.directory()) and skip_history == '' then
        local cmdlines = table.wrap(localcache.get("history", "cmdlines"))
        if #cmdlines > 64 then
            table.remove(cmdlines, 1)
        end
        table.insert(cmdlines, option.cmdline())
        localcache.set("history", "cmdlines", cmdlines)
        localcache.save("history")
    end

    -- get task instance
    local taskname = option.taskname() or "build"
    local taskinst = task.task(taskname) or project.task(taskname)
    if not taskinst then
        return main._exit(false, string.format("do unknown task(%s)!", taskname))
    end

    -- run task
    scheduler:enable(true)
    scheduler:co_start_named("xmake " .. taskname, function ()
        local ok, errors = taskinst:run()
        if not ok then
            os.raise(errors)
        end

    end)
    ok, errors = scheduler:runloop()
    if not ok then
        return main._exit(ok, errors)
    end

    -- stop profiling
    if profiler:enabled() then
        profiler:stop()
    end

    -- exit normally
    return main._exit(true)
end

-- return module: main
return main
