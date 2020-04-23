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
-- @file        _xmake_main.lua
--

-- init namespace: xmake
xmake                   = xmake or {}
xmake._NAME             = _NAME or "xmake"
xmake._ARGV             = _ARGV
xmake._HOST             = _HOST
xmake._ARCH             = _ARCH
xmake._SUBHOST          = _SUBHOST
xmake._SUBARCH          = _SUBARCH
xmake._VERSION          = _VERSION
xmake._VERSION_SHORT    = _VERSION_SHORT
xmake._PROGRAM_DIR      = _PROGRAM_DIR
xmake._PROGRAM_FILE     = _PROGRAM_FILE
xmake._PROJECT_DIR      = _PROJECT_DIR
xmake._PROJECT_FILE     = "xmake.lua"
xmake._WORKING_DIR      = os.curdir()
xmake._FEATURES         = _FEATURES

function _loadfile_impl(filepath, mode, opt)

    -- init options
    opt = opt or {}

    -- init displaypath
    local binary = false
    local displaypath = opt.displaypath
    if displaypath == nil then
        displaypath = filepath
        if filepath:startswith(xmake._WORKING_DIR) then
            displaypath = path.translate("./" .. path.relative(filepath, xmake._WORKING_DIR))
        elseif filepath:startswith(xmake._PROGRAM_DIR) then
            binary = true -- read file by binary mode, will be faster
            displaypath = path.translate("@programdir/" .. path.relative(filepath, xmake._PROGRAM_DIR))
        elseif filepath:startswith(xmake._PROJECT_DIR) then
            local projectname = path.filename(xmake._PROJECT_DIR)
            displaypath = path.translate("@projectdir(" .. projectname .. ")/" .. path.relative(filepath, xmake._PROJECT_DIR))
        end
    end

    -- load script data from file
    local file, ferrors = io.file_open(filepath, binary and "rb" or "r")
    if not file then
        ferrors = string.format("file(%s): %s", filepath, ferrors or "open failed!")
        return nil, ferrors
    end

    local data, rerrors = io.file_read(file, "a")
    if not data then
        rerrors = string.format("file(%s): %s", filepath, rerrors or "read failed!")
        return nil, rerrors
    end
    io.file_close(file)

    -- do on_load()
    if opt.on_load then
        data = opt.on_load(data) or data
    end

    -- load script from string
    return load(data, "@" .. displaypath, mode)
end

-- init loadfile
--
-- @param filepath      the lua file path
-- @param mode          the load mode, e.g 't', 'b' or 'bt' (default)
-- @param opt           the arguments option, e.g. {displaypath = "", nocache = true}
--
local _loadcache = {}
function loadfile(filepath, mode, opt)

    -- init options
    opt = opt or {}

    -- get absolute path
    filepath = path.absolute(filepath)

    -- attempt to load script from cache first
    local mtime = nil
    local cache = (not opt.nocache) and _loadcache[filepath] or nil
    if cache and cache.script then
        mtime = os.mtime(filepath)
        if mtime > 0 and cache.mtime == mtime then
            return cache.script, nil
        end
    end

    -- load file
    local script, errors = _loadfile_impl(filepath, mode, opt)
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
