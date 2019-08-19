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
xmake._WORKING_DIR      = os.curdir()

function _loadfile_impl(filepath, mode)

    -- init displaypath
    local binary = false
    local displaypath = filepath
    if filepath:startswith(xmake._WORKING_DIR) then
        displaypath = path.translate("./" .. path.relative(filepath, xmake._WORKING_DIR))
    elseif filepath:startswith(xmake._PROGRAM_DIR) then
        binary = true -- read file by binary mode, will be faster
        displaypath = path.translate("$(programdir)/" .. path.relative(filepath, xmake._PROGRAM_DIR))
    elseif filepath:startswith(xmake._PROJECT_DIR) then
        displaypath = path.translate("$(projectdir)/" .. path.relative(filepath, xmake._PROJECT_DIR))
    end

    -- load script data from file
    local file, ferrors = io.file_open(filepath, binary and "rb" or "r")
    if not file then
        return nil, ferrors
    end

    local data, rerrors = io.file_read(file, "a")
    if not data then
        return nil, rerrors
    end
    io.file_close(file)

    -- load script from string
    return load(data, "@" .. displaypath, mode)
end

-- init loadfile
local _loadcache = {}
function loadfile(filepath, mode)

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

    -- load file
    local script, errors = _loadfile_impl(filepath, mode)
    if script then
        _loadcache[filepath] = {script = script, mtime = mtime or os.mtime(filepath)}
    end
    return script, errors
end

-- init package path
table.insert(package.loaders, 2, function(v)
    local filepath = xmake._PROGRAM_DIR .. "/core/" .. v .. ".lua"
    local script, serr = _loadfile_impl(filepath)
    if not script then
        return "\n\tfailed to load " .. filepath .. " : " .. serr
    end
    return script
end)

-- load modules
local main = require("main")

-- the main function
function _xmake_main()
    return main.entry()
end
