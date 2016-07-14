--!The Make-like Build Utility based on Lua
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

-- define module
local sandbox_core_project_task = sandbox_core_project_task or {}

-- load modules
local os        = require("base/os")
local io        = require("base/io")
local table     = require("base/table")
local option    = require("base/option")
local string    = require("base/string")
local task      = require("project/task")
local raise     = require("sandbox/modules/raise")

-- run the given task
function sandbox_core_project_task.run(taskname, options, ...)

    -- init options
    options = table.wrap(options)

    -- inherit some parent options
    for _, name in ipairs({"file", "project", "verbose"}) do
        if not options[name] and option.get(name) then
            options[name] = option.get(name)
        end
    end

    -- save the current option and push a new option context
    option.save(taskname)

    -- init the new options
    for name, value in pairs(options) do
        option.set(name, value)
    end

    -- run the task
    local ok, errors = task.run(taskname, ...)
    if not ok then
        raise(errors)
    end

    -- restore the previous option context
    option.restore()
end

-- return module
return sandbox_core_project_task
