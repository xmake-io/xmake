--!A cross-platform build utility based on Lua
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
-- @file        application.lua
--

--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tiago.dionizio AT gmail.com)
$Id: application.lua 18 2007-06-21 20:43:52Z tngd $
--------------------------------------------------------------------------]]

-- load modules
local os        = require("base/os")
local log       = require("ui/log")
local curses    = require("ui/curses")
local program   = require("ui/program")

-- define module
local application = application or program()

-- init application
function application:init(name)

    -- init log
    log:clear()
--    log:enable(false)

    -- trace
    log:print("<application: %s>: init ..", name)

    -- init program
    program.init(self, name)

    -- trace
    log:print("<application: %s>: init ok", name)
end

-- exit application
function application:exit()

    -- exit program
    program.exit(self)

    -- flush log
    log:flush()
end

-- run application 
function application.run(name, ...)

    -- init runner
    local argv = {...}
    local runner = function ()

        -- new an application
        local app = application:new(name)
        if app then
            app:loop(argv)
            app:exit()
        end
    end

    -- run application
    local ok, errors = xpcall(runner, debug.traceback)

    -- exit curses
    if not ok then
        if not curses.isdone() then
            curses.done()
        end
        log:flush()
        os.raise(errors)
    end
end

-- return module
return application
