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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        _xmake_main.lua
--

-- init namespace: xmake
xmake                   = xmake or {}
xmake._ARGV             = _ARGV
xmake._HOST             = _HOST
xmake._ARCH             = _ARCH
xmake._VERSION          = _VERSION
xmake._VERSION_SHORT    = _VERSION_SHORT
xmake._PROGRAM_DIR      = _PROGRAM_DIR
xmake._PROGRAM_FILE     = _PROGRAM_FILE
xmake._PROJECT_DIR      = _PROJECT_DIR
xmake._PROJECT_FILE     = "xmake.lua"

-- init loadfile
local _loadfile = _loadfile or loadfile
local _loadcache = {}
function loadfile(filepath)

    -- get absolute path
    filepath = path.absolute(filepath)

    -- attempt to load script from cache first
    local mtime = nil
    local cache = _loadcache[filepath]
    if cache and cache.script then
        mtime = os.mtime(filepath)
        if mtime > 0 and cache.mtime == mtime then
            return cache.script, nil
        end
    end

    -- init displaypath
    local readopt = {}
    local displaypath = filepath
    if filepath:startswith(xmake._WORKING_DIR) then
        displaypath = path.join(".", path.relative(filepath, xmake._WORKING_DIR))
    elseif filepath:startswith(xmake._PROGRAM_DIR) then
        readopt.encoding = "binary" -- read file by binary mode, will be faster
        displaypath = path.join("$(programdir)", path.relative(filepath, xmake._PROGRAM_DIR))
    elseif filepath:startswith(xmake._PROJECT_DIR) then
        displaypath = path.join("$(projectdir)", path.relative(filepath, xmake._PROJECT_DIR))
    end

    -- load script data from file
    local data, rerrors = io.readfile(filepath, readopt)
    if not data then
        return nil, rerrors
    end

    -- load script from string
    local script, errors = load(data, "@" .. displaypath)
    if script then
        _loadcache[filepath] = {script = script, mtime = mtime or os.mtime(filepath)}
    end
    return script, errors
end

-- init package path
package.path = xmake._PROGRAM_DIR .. "/core/?.lua;" .. package.path

-- load modules
local main = require("main")

-- the main function
function _xmake_main()
    return main.entry()
end
