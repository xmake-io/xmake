--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        task.lua
--

-- define module: task
local task = task or {}

-- load modules
local os            = require("base/os")
local table         = require("base/table")
local utils         = require("base/utils")
local string        = require("base/string")
local global        = require("base/global")
local interpreter   = require("base/interpreter")
local sandbox       = require("sandbox/sandbox")
local config        = require("project/config")
local project       = require("project/project")
local sandbox_os    = require("sandbox/modules/os")

-- the directories of tasks
function task._directories()

    return  {   path.join(global.directory(), "plugins")
            ,   path.join(os.programdir(), "plugins")
            ,   path.join(os.programdir(), "actions")
            }
end

-- translate menu
function task._translate_menu(menu)

    -- check
    assert(menu)

    -- the interpreter
    local interp = task._interpreter()
    assert(interp)

    -- translate options
    local options = menu.options
    if options then
    
        -- make full options 
        local options_full = {}
        for _, opt in ipairs(options) do

            -- this option is function? translate it
            if type(opt) == "function" then
                
                -- call menu script in the sandbox
                local ok, results = sandbox.load(opt)
                if ok then
                    if results then
                        for _, opt in ipairs(results) do
                            table.insert(options_full, opt)
                        end
                    end
                else
                    -- errors
                    return nil, string.format("taskmenu: %s", results)
                end
            else
                table.insert(options_full, opt)
            end
        end

        -- update the options
        options = options_full
        menu.options = options_full

        -- filter options
        if interp:filter() then

            -- filter option
            for _, opt in ipairs(options) do

                -- filter default
                local default = opt[4]
                if type(default) == "string" then
                    opt[4] = interp:filter():handle(default)
                end

                -- filter description
                for i = 5, 64 do

                    -- the description, @note some option may be nil
                    local description = opt[i]
                    if not description then break end

                    -- the description is string?
                    if type(description) == "string" then
                        opt[i] = interp:filter():handle(description)

                    -- the description is function? wrap it for calling it in the sandbox
                    elseif type(description) == "function" then
                        opt[i] = function ()

                            -- call it in the sandbox
                            local ok, results = sandbox.load(description)
                            if not ok then
                                -- errors
                                return nil, string.format("taskmenu: %s", results)
                            end

                            -- ok
                            return results
                        end
                    end
                end
            end
        end

        -- add common options
        table.insert(options, 1,  {'q', "quiet",     "k",  nil, "Quiet operation."                           })
        table.insert(options, 2,  {'v', "verbose",   "k",  nil, "Print lots of verbose information."         })
        table.insert(options, 3,  {nil, "root",      "k",  nil, "Allow to run xmake as root."                })
        table.insert(options, 4,  {nil, "backtrace", "k",  nil, "Print backtrace information for debugging." })
        table.insert(options, 5,  {nil, "profile",   "k",  nil, "Print performance data for debugging."      })
        table.insert(options, 6,  {nil, "version",   "k",  nil, "Print the version number and exit."         })
        table.insert(options, 7,  {'h', "help",      "k",  nil, "Print this help message and exit."          })
        table.insert(options, 8,  {})
        table.insert(options, 9,  {'F', "file",      "kv", nil, "Read a given xmake.lua file."               })
        table.insert(options, 10, {'P', "project",   "kv", nil, "Change to the given project directory."
                                                              , "Search priority:"
                                                              , "    1. The Given Command Argument"
                                                              , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                              , "    3. The Current Directory"               })
        table.insert(options, 11, {})

    end

    -- ok
    return menu
end

-- the interpreter
function task._interpreter()

    -- the interpreter has been initialized? return it directly
    if task._INTERPRETER then
        return task._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)
  
    -- define apis
    interp:api_define(task.apis())

    -- set filter
    interp:filter():register("task", function (variable)

        -- check
        assert(variable)

        -- attempt to get it directly from the configure
        local result = config.get(variable)
        if not result or type(result) ~= "string" then 

            -- init maps
            local maps = 
            {
                host        = os.host()
            ,   tmpdir      = function () return os.tmpdir() end
            ,   curdir      = function () return os.curdir() end
            ,   scriptdir   = function () return sandbox_os.scriptdir() end
            ,   globaldir   = global.directory()
            ,   configdir   = config.directory()
            ,   projectdir  = os.projectdir()
            ,   programdir  = os.programdir()
            }

            -- map it
            result = maps[variable]
            if type(result) == "function" then
                result = result()
            end
        end 

        -- ok?
        return result
    end)

    -- save interpreter
    task._INTERPRETER = interp

    -- ok?
    return interp
end

-- bind tasks for menu with an sandbox instance
function task._bind(tasks, interp)

    -- check
    assert(tasks)

    -- get interpreter
    interp = interp or task._interpreter()
    assert(interp) 

    -- bind sandbox for menus
    for _, taskinfo in pairs(tasks) do

        -- has menu?
        if taskinfo.menu then

            -- translate options
            local options = taskinfo.menu.options
            if options then
            
                -- make full options 
                local options_full = {}
                for _, opt in ipairs(options) do

                    -- this option is function? translate it
                    if type(opt) == "function" then

                        -- make sandbox instance with the given script
                        local instance, errors = sandbox.new(opt, interp:filter(), interp:rootdir())
                        if not instance then
                            return false, errors
                        end

                        -- update option script
                        opt = instance:script()
                    end

                    -- insert option
                    table.insert(options_full, opt)
                end

                -- update the options
                options = options_full
                taskinfo.menu.options = options_full

                -- bind sandbox for option description
                for _, opt in ipairs(options) do

                    -- bind description
                    if type(opt) == "table" then
                        for i = 5, 64 do

                            -- the description, @note some option may be nil
                            local description = opt[i]
                            if not description then break end

                            -- the description is function? wrap it for calling it in the sandbox
                            if type(description) == "function" then

                                -- make sandbox instance with the given script
                                local instance, errors = sandbox.new(description, interp:filter(), interp:rootdir())
                                if not instance then
                                    return false, errors
                                end

                                -- check
                                assert(instance:script())

                                -- update option script
                                opt[i] = instance:script()
                            end
                        end
                    end
                end
            end
        end
    end

    -- ok
    return true
end

-- load the given task script file
function task._load(filepath)

    -- get interpreter
    local interp = task._interpreter()
    assert(interp) 

    -- load tasks
    local tasks, errors = interp:load(filepath, "task", true, true)
    if not tasks and os.isfile(filepath) then
        return nil, errors
    end

    -- bind tasks for menu with an sandbox instance
    local ok, errors = task._bind(tasks)
    if not ok then
        return nil, errors
    end

    -- ok?
    return tasks
end
 
-- get task apis
function task.apis()

    return 
    {
        values =
        {
            -- task.set_xxx
            "task.set_category"     -- main, action, plugin, task (default)
        }
    ,   dictionary = 
        {
            -- task.set_xxx
            "task.set_menu"
        }
    ,   script =
        {
            -- task.on_xxx
            "task.on_run"
        }
    }
end

-- get all tasks
function task.tasks()
 
    -- return it directly if exists
    if task._TASKS then
        return task._TASKS 
    end

    -- load tasks
    local tasks = {}
    local dirs = task._directories()
    for _, dir in ipairs(dirs) do

        -- get files
        local files = os.match(path.join(dir, "**/xmake.lua"))
        if files then
            for _, filepath in ipairs(files) do

                -- load tasks
                local results, errors = task._load(filepath)

                -- save tasks
                if results then
                    table.join2(tasks, results)
                else
                    return nil, errors
                end
            end
        end
    end

    -- merge project tasks if exists
    local projectasks, errors = project.tasks()
    if projectasks then

        -- the project interpreter
        local interp = errors

        -- bind tasks for menu with an sandbox instance
        local ok, errors = task._bind(projectasks, interp)
        if not ok then
            return nil, errors
        end

        -- save tasks
        for taskname, taskinfo in pairs(projectasks) do
            if tasks[taskname] == nil then
                tasks[taskname] = taskinfo
            else
                utils.warning("task(\"%s\") has been defined!", taskname)
            end
        end
    else
        return nil, errors
    end

    -- save it
    task._TASKS = tasks

    -- ok?
    return tasks
end

-- run task with given name
function task.run(name, ...)

    -- check
    assert(name)

    -- load tasks
    local tasks, errors = task.tasks()
    if not tasks then
        return false, errors
    end

    -- the interpreter
    local interp = task._interpreter()
    assert(interp)

    -- get the task info
    local taskinfo = tasks[name]
    if not taskinfo then
        return false, string.format("task(\"%s\"): unknown task", name)
    end

    -- check
    if not taskinfo.run then
        return false, string.format("task(\"%s\"): no run script, please call on_task_run() first!", name)
    end

    -- save the current directory
    local curdir = os.curdir()

    -- run task
    local ok, errors = sandbox.load(taskinfo.run, ...)

    -- restore the current directory
    os.cd(curdir)

    -- ok?
    return ok, errors
end

-- the menu
function task.menu()

    -- load tasks
    local tasks, errors = task.tasks()
    if not tasks then
        return nil, errors
    end

    -- make menu
    local menu = {}
    for taskname, taskinfo in pairs(tasks) do

        -- has menu?
        if taskinfo.menu then

            -- main?
            if taskinfo.category == "main" then

                -- delay to load main menu
                menu.main = function ()

                    -- translate main menu
                    local mainmenu = task._translate_menu(taskinfo.menu)

                    -- make tasks for the main menu
                    mainmenu.tasks = {}
                    for name, info in pairs(tasks) do

                        -- has menu?
                        if info.menu then

                            -- add task
                            mainmenu.tasks[name] = 
                            {
                                category    = info.category
                            ,   shortname   = info.menu.shortname
                            ,   description = info.menu.description
                            }
                        end
                    end

                    -- ok
                    return mainmenu
                end
            end

            -- delay to load task menu
            menu[taskname] = function ()
                return task._translate_menu(taskinfo.menu)
            end
        end
    end

    -- ok?
    return menu
end

-- return module: task
return task
