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
-- @file        task.lua
--

-- define module: task
local task = task or {}

-- load modules
local os            = require("base/os")
local table         = require("base/table")
local string        = require("base/string")
local global        = require("base/global")
local hashset       = require("base/hashset")
local interpreter   = require("base/interpreter")
local sandbox       = require("sandbox/sandbox")
local config        = require("project/config")
local sandbox_os    = require("sandbox/modules/os")

function task.common_options()
    local common_options = task._COMMON_OPTIONS
    if not common_options then
        common_options = {
            {'q', "quiet",     "k",  nil,   "Quiet operation."                                          }
        ,   {'y', "yes",       "k",  nil,   "Input yes by default if need user confirm."                }
        ,   {nil, "confirm",   "kv", nil,   "Input the given result if need user confirm."
                                        ,   values = function ()
                                                return {"yes", "no", "def"}
                                            end                                                         }
        ,   {'v', "verbose",   "k",  nil,   "Print lots of verbose information for users."              }
        ,   {nil, "root",      "k",  nil,   "Allow to run xmake as root."                               }
        ,   {'D', "diagnosis", "k",  nil,   "Print lots of diagnosis information (backtrace, check info ..) only for developers."
                                        ,   "And we can append -v to get more whole information."
                                        ,   "    e.g. $ xmake -vD"                                      }
        ,   {'h', "help",      "k",  nil,   "Print this help message and exit."                         }
        ,   {}
        ,   {'F', "file",      "kv", nil,   "Read a given xmake.lua file."                              }
        ,   {'P', "project",   "kv", nil,   "Change to the given project directory."
                                        ,   "Search priority:"
                                        ,   "    1. The Given Command Argument"
                                        ,   "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                        ,   "    3. The Current Directory"                              }
        ,   {category = "action"}
        }
        task._COMMON_OPTIONS = common_options
    end
    return task._COMMON_OPTIONS
end

function task._common_option_names()
    local common_names = task._COMMON_OPTION_NAMES
    if not common_names then
        common_names = hashset.new()
        for i, v in ipairs(task.common_options()) do
            if v and v[1] then
                common_names:insert(v[1])
            end
            if v and v[2] then
                common_names:insert(v[2])
            end
        end
        task._COMMON_OPTION_NAMES = common_names
    end
    return common_names
end

-- the directories of tasks
function task._directories()
    return {path.join(global.directory(), "plugins"),
            path.join(os.programdir(), "plugins"),
            path.join(os.programdir(), "actions")}
end

-- translate menu
function task._translate_menu(taskname, menu)
    local interp = task._interpreter()
    local options = menu.options
    if options then

        -- make full options
        local options_full = {}
        for _, opt in ipairs(options) do
            if type(opt) == "function" then
                local ok, results = sandbox.load(opt)
                if ok then
                    if results then
                        for _, opt in ipairs(results) do
                            table.insert(options_full, opt)
                        end
                    end
                else
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
                                return nil, string.format("taskmenu: %s", results)
                            end
                            return results
                        end
                    end
                end
            end
        end

        -- add common options, we need to avoid repeat because the main/build task will be inserted twice
        if not menu._common_options then
            local common_option_names = task._common_option_names()
            for _, v in ipairs(options) do
                local option_name = v[2] or v[1]
                if option_name and common_option_names:has(option_name) then
                    utils.warning("task(%s): option name '%s' is a built-in name and may cause conflicts, please rename it.", taskname, option_name)
                end
            end

            for i, v in ipairs(task.common_options()) do
                table.insert(options, i, v)
            end
            menu._common_options = true
        end
    end
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
            ,   subhost     = os.subhost()
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

-- bind script with a sandbox instance
function task._bind_script(interp, script)
    local instance, errors = sandbox.new(script, {
        filter = interp:filter(), rootdir = interp:rootdir(), namespace = interp:namespace()})
    if not instance then
        return nil, errors
    end
    assert(instance:script())
    return instance:script()
end

-- bind tasks for menu with a sandbox instance
function task._bind(tasks, interp)

    -- check
    assert(tasks)

    -- get interpreter
    interp = interp or task._interpreter()
    assert(interp)

    -- bind sandbox for menus
    for _, taskinst in pairs(tasks) do

        -- has task menu?
        local taskmenu = taskinst:get("menu")
        if taskmenu then

            -- translate options
            local options = taskmenu.options
            if options then

                -- make full options
                local errors = nil
                local options_full = {}
                for _, opt in ipairs(options) do

                    -- this option is function? translate it
                    if type(opt) == "function" then
                        opt, errors = task._bind_script(interp, opt)
                        if not opt then
                            return false, errors
                        end
                    end

                    -- insert option
                    table.insert(options_full, opt)
                end

                -- update the options
                options = options_full
                taskmenu.options = options_full

                -- bind sandbox for scripts in option
                for _, opt in ipairs(options) do

                    -- bind description and values
                    if type(opt) == "table" then

                        -- bind description
                        for i = 5, 64 do

                            -- the description, @note some option may be nil
                            local description = opt[i]
                            if not description then break end

                            -- the description is function? wrap it for calling it in the sandbox
                            if type(description) == "function" then
                                description, errors = task._bind_script(interp, description)
                                if not description then
                                    return false, errors
                                end
                                opt[i] = description
                            end
                        end

                        -- bind values
                        if type(opt.values) == "function" then
                            local values, errors = task._bind_script(interp, opt.values)
                            if not values then
                                return false, errors
                            end
                            opt.values = values
                        end
                    end
                end
            end
        end
    end
    return true
end

-- load the given task script file
function task._load(filepath)

    -- get interpreter
    local interp = task._interpreter()
    assert(interp)

    -- load script
    local ok, errors = interp:load(filepath)
    if not ok and os.isfile(filepath) then
        return nil, errors
    end

    -- load tasks
    local tasks, errors = interp:make("task", true, true)
    if not tasks then
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

-- new a task instance
function task.new(name, info)
    local instance = table.inherit(task)
    if name then
        local parts = name:split("::", {plain = true})
        instance._NAME = parts[#parts]
        table.remove(parts)
        if #parts > 0 then
            instance._NAMESPACE = table.concat(parts, "::")
        end
    end
    instance._INFO = info
    return instance
end

-- get global tasks
function task.tasks()
    if task._TASKS then
        return task._TASKS
    end

    -- load tasks
    local tasks = {}
    local dirs = task._directories()
    for _, dir in ipairs(dirs) do
        local files = os.files(path.join(dir, "*", "xmake.lua"))
        if files then
            for _, filepath in ipairs(files) do
                local results, errors = task._load(filepath)
                if results then
                    table.join2(tasks, results)
                else
                    os.raise(errors)
                end
            end
        end
    end
    local instances = {}
    for taskname, taskinfo in pairs(tasks) do
        instances[taskname] = task.new(taskname, taskinfo)
    end
    task._TASKS = instances
    return instances
end

-- get the given global task
function task.task(name)
    return task.tasks()[name]
end

-- get the task menu
function task.menu(tasks)
    local menu = {}
    for taskname, taskinst in pairs(tasks) do
        local taskmenu = taskinst:get("menu")
        if taskmenu then
            -- delay to load main menu
            if taskinst:get("category") == "main" then
                menu.main = function ()

                    -- translate main menu
                    local mainmenu, errors = task._translate_menu(taskname, taskmenu)
                    if not mainmenu then
                        os.raise(errors)
                    end

                    -- make tasks for the main menu
                    mainmenu.tasks = {}
                    for name, inst in pairs(tasks) do
                        local m = inst:get("menu")
                        if m then
                            mainmenu.tasks[name] = {
                                category    = inst:get("category")
                            ,   shortname   = m.shortname
                            ,   description = m.description
                            }
                        end
                    end
                    return mainmenu
                end
            end

            -- delay to load task menu
            menu[taskname] = function ()
                local result, errors = task._translate_menu(taskname, taskmenu)
                if not result then
                    os.raise(errors)
                end
                return result
            end
        end
    end
    return menu
end

-- get the task info
function task:get(name)
    return self._INFO:get(name)
end

-- get the task name
function task:name()
    return self._NAME
end

-- get the namespace
function task:namespace()
    return self._NAMESPACE
end

-- get the full name
function task:fullname()
    local namespace = self:namespace()
    return namespace and namespace .. "::" .. self:name() or self:name()
end

-- run given task
function task:run(...)

    -- check
    local on_run = self:get("run")
    if not on_run then
        return false, string.format("task(\"%s\"): no run script, please call on_run() first!", self:fullname())
    end

    -- save the current directory
    local curdir = os.curdir()

    -- run task
    local ok, errors = sandbox.load(on_run, ...)

    -- restore the current directory
    os.cd(curdir)
    return ok, errors
end

-- return module: task
return task
