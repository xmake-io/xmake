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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        task.lua
--

-- define module: task
local task = task or {}

-- load modules
local table         = require("base/table")
local utils         = require("base/utils")
local string        = require("base/string")
local global        = require("base/global")
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

    -- register api: set_task_menu() 
    interp:api_register_set_values("task", "task", "menu")

    -- save interpreter
    task._INTERPRETER = interp

    -- ok?
    return interp
end

-- load the given task from the given directory
function task._load_from(dir, taskname)

    -- the file path
    local filepath = path.join(dir, taskname .. ".lua")

    -- get interpreter
    local interp = task._interpreter()
    assert(interp) 

    -- load task
    local results, errors = interp:load(filepath, nil, true, true)
    if not results then
        -- trace
        utils.error(errors)
        utils.abort()
    end
end


-- return module: task
return task
