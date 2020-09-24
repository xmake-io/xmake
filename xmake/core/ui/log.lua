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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        log.lua
--

-- get log
local log = log or (function ()

    -- load modules
    local os    = require("base/os")
    local path  = require("base/path")
    local table = require("base/table")

    -- get log directory
    local logdir = nil
    if os.isfile(os.projectfile()) then
        logdir = path.join(os.projectdir(), "." .. xmake._NAME)
    else
        logdir = os.tmpdir()
    end

    -- return module: log
    local instance = table.inherit(require("base/log"))
    if instance then
        instance._FILE = nil
        instance._LOGFILE = path.join(logdir, "ui.log")
    end
    return instance
end)()
return log
