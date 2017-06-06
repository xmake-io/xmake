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
-- @file        tool.lua
--

-- define module
local sandbox_core_tool = sandbox_core_tool or {}

-- load modules
local tool      = require("tool/tool")
local config    = require("project/config")
local platform  = require("platform/platform")
local raise     = require("sandbox/modules/raise")

-- get the tool shell name
function sandbox_core_tool.shellname(name)

    -- get it
    return platform.tool(name)
end

-- check the tool and return the absolute path if exists
function sandbox_core_tool.check(shellname, dirs, check)

    -- check it
    return tool.check(shellname, dirs, check)
end

-- return module
return sandbox_core_tool
