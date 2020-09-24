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
-- @file        cache.lua
--

-- define module
local sandbox_lib_detect_cache = sandbox_lib_detect_cache or {}

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

-- get detect cache instance
function sandbox_lib_detect_cache._instance()

    -- get it
    local detectcache = sandbox_lib_detect_cache._INSTANCE or cache(os.isfile(project.rootfile()) and "local.detect" or "memory.detect")
    sandbox_lib_detect_cache._INSTANCE = detectcache
    return detectcache
end

-- load detect cache
--
-- @param name  the cache name. e.g. find_program, find_programver, ..
--
function sandbox_lib_detect_cache.load(name)

    -- get detect cache
    local detectcache = sandbox_lib_detect_cache._instance()

    -- attempt to get result from cache first
    local cacheinfo = detectcache:get(name)
    if cacheinfo == nil then
        cacheinfo = {}
        detectcache:set(name, cacheinfo)
    end

    -- ok?
    return cacheinfo
end

-- save detect cache
--
-- @param name  the cache name. e.g. find_program, find_programver, ..
-- @param info  the cache info
--
function sandbox_lib_detect_cache.save(name, info)

    -- get detect cache
    local detectcache = sandbox_lib_detect_cache._instance()

    -- save cache info
    detectcache:set(name, info)
    detectcache:flush()
end

-- clear detect cache
--
-- @param name  the cache name. e.g. find_program, find_programver, ..
--
function sandbox_lib_detect_cache.clear(name)

    -- get detect cache
    local detectcache = sandbox_lib_detect_cache._instance()

    -- clear cache info
    if name then
        detectcache:set(name, {})
    else
        detectcache:clear()
    end
    detectcache:flush()
end

-- return module
return sandbox_lib_detect_cache
