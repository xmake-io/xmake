--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
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
local filter        = require("base/filter")
local string        = require("base/string")
local global        = require("base/global")
local sandbox       = require("base/sandbox")
local interpreter   = require("base/interpreter")

-- the directories of tasks
function task._directories()

    return  {   path.join(global.directory(), "plugins")
            ,   path.join(xmake._PROGRAM_DIR, "plugins")
            ,   path.join(xmake._CORE_DIR, "tasks")
            }
end

-- the interpreter
function task._interpreter()

    -- the interpreter has been initialized? return it directly
    if task._INTERPRETER then
        return task._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.init()
    assert(interp)
 
    -- register api: task()
    interp:api_register_scope("task")

    -- register api: set_task_category()
    --
    -- category: main, action, plugin
    interp:api_register_set_values("task", "task", "category")

    -- register api: set_task_menu() 
    interp:api_register_set_values("task", "task", "menu")

    -- register api: on_task_run(), on_task_before(), on_task_after(), on_task_failure() 
    interp:api_register_on_script("task", "task", "run"
                                                , "after"
                                                , "before"
                                                , "failure")

    -- set filter
    interp:filter_set(filter.init(function (variable)

        -- check
        assert(variable)

        -- init maps
        local maps = 
        {
            host = xmake._HOST
        }

        -- map it
        result = maps[variable]

        -- ok?
        return result
    end))

    -- save interpreter
    task._INTERPRETER = interp

    -- ok?
    return interp
end

-- load the given task script file
function task._load(filepath)

    -- get interpreter
    local interp = task._interpreter()
    assert(interp) 

    -- load task
    local results, errors = interp:load(filepath, "task", true, true)
    if not results and os.isfile(filepath) then
        -- trace
        utils.error(errors)
    end

    -- ok?
    return results
end

-- call the sandbox script
function task._call(script, ...)

    -- get interpreter
    local interp = task._interpreter()
    assert(interp) 

    -- bind script and get new script with sandbox
    local newscript, errors = sandbox.bind(script, interp)
    if not newscript then
        return false, errors
    end

    -- load it
    return sandbox.load(script, ...)
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
        local files = os.match(path.join(dir, "*.lua"))
        if files then
            for _, filepath in ipairs(files) do

                -- load it
                local results = task._load(filepath)
                if results then
                    table.join2(tasks, results)
                end
            end
        end

    end

    -- save it
    task._TASKS = tasks

    -- ok?
    return tasks
end

-- run task with given name
function task.run(name)

    -- check
    assert(name)

    -- load tasks
    local tasks = task.tasks()
    assert(tasks)

    -- the interpreter
    local interp = task._interpreter()
    assert(interp)

    -- get the task info
    local taskinfo = tasks[name]
    if not taskinfo then
        utils.error("unknown task: %s", name)
        return false
    end

    -- run on_before, on_run, on_after
    local ok = true
    local on_scripts = {taskinfo.before, taskinfo.run, taskinfo.after}
    for i = 1, 3 do

        -- get script
        local on_script = on_scripts[i]
        if on_script then

            -- call it in the sandbox
            ok, errors = task._call(on_script)
            if not ok then
                utils.error(errors)
                break
            end
        end
    end

    -- run on_failure if be failed?
    if not ok and taskinfo.failure then

        -- call it in the sandbox
        ok, errors = task._call(taskinfo.failure)
        if not ok then
            utils.error(errors)
        end

        -- failed
        ok = false
    end

    -- ok?
    return ok
end

-- the menu
function task.menu()

    -- load tasks
    local tasks = task.tasks()
    assert(tasks)

    -- the interpreter
    local interp = task._interpreter()
    assert(interp)

    -- make menu
    local menu = {}
    for taskname, taskinfo in pairs(tasks) do

        -- has menu?
        if taskinfo.menu then

            -- translate options
            local options = taskinfo.menu.options
            if options then
            
                -- make full options 
                local options_full = {}
                for _, option in ipairs(options) do

                    -- this option is function? translate it
                    if type(option) == "function" then
                        
                        -- call menu script in the sandbox
                        local ok, results = task._call(option)
                        if ok then
                            if results then
                                for _, opt in ipairs(results) do
                                    table.insert(options_full, opt)
                                end
                            end
                        else
                            -- errors
                            os.raise("taskmenu: %s", results)
                        end
                    else
                        table.insert(options_full, option)
                    end
                end

                -- update the options
                options = options_full
                taskinfo.menu.options = options_full

                -- filter options
                if interp:filter() then

                    -- filter option
                    for _, option in ipairs(options) do

                        -- filter default
                        local default = option[4]
                        if type(default) == "string" then
                            option[4] = interp:filter():handle(default)
                        end

                        -- filter description
                        for i = 5, 64 do

                            -- the description, @note some option may be nil
                            local description = option[i]
                            if not description then break end

                            -- the description is string?
                            if type(description) == "string" then
                                option[i] = interp:filter():handle(description)

                            -- the description is function? wrap it for calling it in the sandbox
                            elseif type(description) == "function" then
                                option[i] = function ()
 
                                    -- call it in the sandbox
                                    local ok, results = task._call(description)
                                    if not ok then
                                        -- errors
                                        os.raise("taskmenu: %s", results)
                                    end

                                    -- ok
                                    return results
                                end
                            end
                        end
                    end
                end

                -- add common options
                table.insert(options, 1, {'v', "verbose",    "k",  nil, "Print lots of verbose information." })
                table.insert(options, 2, {nil, "version",    "k",  nil, "Print the version number and exit." })
                table.insert(options, 3, {'h', "help",       "k",  nil, "Print this help message and exit."  })
                table.insert(options, 4, {})
                table.insert(options, 5, {'f', "file",       "kv", nil, "Read a given xmake.lua file."       })
                table.insert(options, 6, {'P', "project",    "kv", nil, "Change to the given project directory."
                                                                      , "Search priority:"
                                                                      , "    1. The Given Command Argument"
                                                                      , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                                      , "    3. The Current Directory"       })
                table.insert(options, 7, {})

            end

            -- main?
            if taskinfo.category == "main" then
                menu.main = taskinfo.menu
            end
                
            -- add menu
            menu[taskname] = taskinfo.menu
        end
    end

    -- add tasks to the main menu
    if menu.main then

        -- make tasks for the main menu
        menu.main.tasks = menu.main.tasks or {}
        for taskname, taskinfo in pairs(tasks) do

            -- has menu?
            if taskinfo.menu then

                -- add task
                menu.main.tasks[taskname] = taskinfo
            end
        end
    end

    -- ok?
    return menu
end

-- return module: task
return task
