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
-- @file        clear_cache.lua
--

-- define module
local sandbox_lib_detect_clear_cache = sandbox_lib_detect_clear_cache or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local option    = require("base/option")
local cache     = require("project/cache")
local project   = require("project/project")
local sandbox   = require("sandbox/sandbox")
local raise     = require("sandbox/modules/raise")

-- clear detect cache
--
-- @param name  the cache name. .e.g find_program, find_programver, ..
--
function sandbox_lib_detect_clear_cache.main(name)

    -- get detect cache 
    local detectcache = cache(utils.ifelse(os.isfile(project.file()), "local.detect", "memory.detect"))
 
    -- clear cache info
    if name then
        detectcache:set(name, {})
    else
        detectcache:clear()
    end
    detectcache:flush()
end

-- return module
return sandbox_lib_detect_clear_cache
