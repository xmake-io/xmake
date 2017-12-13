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
-- @file        group.lua
--

--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tiago.dionizio AT gmail.com)
$Id: group.lua 18 2007-06-21 20:43:52Z tngd $
--------------------------------------------------------------------------]]

-- load modules
local view   = require("ui/view")
local curses = require("ui/curses")
local dlist  = require("base/dlist")

-- define module
local group = group or view()

-- init group
function group:init(name, bounds)

    -- init view
    view.init(self, name, bounds)

    -- init child views
    self._VIEWS = dlist()
end

-- exit group
function group:exit()

    -- exit view
    view.exit(self)
end

-- get all child views
function group:views()
    return self._VIEWS
end

-- insert view
function group:insert(v)
    self:views():push(v)
end

-- remove view
function group:remove(v)
    self:views():remove(v)
end

-- execute group
function group:execute()
end


-- return module
return group
