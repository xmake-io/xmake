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
-- @file        main.lua
--

-- define module: main
local main = main or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local option        = require("base/option")
local profiler      = require("base/profiler")
local deprecated    = require("base/deprecated")
local task          = require("project/task")
local history       = require("project/history")

-- init the option menu
local menu =
{
    -- title
    title = "XMake v" .. xmake._VERSION .. ", The Make-like Build Utility based on Lua"

    -- copyright
,   copyright = "Copyright (C) 2015-2016 Ruki Wang, ${underline}tboox.org${clear}, ${underline}xmake.io${clear}\nCopyright (C) 2005-2015 Mike Pall, ${underline}luajit.org${clear}"

    -- the tasks: xmake [task]
,   task.menu

}

-- done help
function main._help()

    -- done help
    if option.get("help") then
    
        -- print menu
        option.show_menu(option.taskname())

        -- ok
        return true

    -- done version
    elseif option.get("version") then

        -- print title
        if menu.title then
            utils.cprint(menu.title)
        end

        -- print copyright
        if menu.copyright then
            utils.cprint(menu.copyright)
        end

        -- ok
        return true
    end
end

-- the init function for main
function main._init()

    -- init the project directory
    local projectdir = option.find(xmake._ARGV, "project", "P") or xmake._PROJECT_DIR
    if projectdir and not path.is_absolute(projectdir) then
        projectdir = path.absolute(projectdir)
    elseif projectdir then 
        projectdir = path.translate(projectdir)
    end
    xmake._PROJECT_DIR = projectdir
    assert(projectdir)

    -- init the xmake.lua file path
    local projectfile = option.find(xmake._ARGV, "file", "F") or xmake._PROJECT_FILE
    if projectfile and not path.is_absolute(projectfile) then
        projectfile = path.absolute(projectfile, projectdir)
    end
    xmake._PROJECT_FILE = projectfile
    assert(projectfile)

    -- make all parent directories
    local dirs = {}
    local dir = path.directory(projectfile)
    while os.isdir(dir) do
        table.insert(dirs, 1, dir)
        local parentdir = path.directory(dir)
        if parentdir and parentdir ~= dir and parentdir ~= '.' then
            dir = parentdir
        else 
            break
        end
    end

    -- find the first `xmake.lua` from it's parent directory
    for _, dir in ipairs(dirs) do
        local file = path.join(dir, "xmake.lua")
        if os.isfile(file) then

            -- switch to the project directory
            xmake._PROJECT_DIR  = dir
            xmake._PROJECT_FILE = file
            os.cd(dir)
            break
        end
    end
end

-- check run command as root
function main._check_root()

    -- TODO not check
    if xmake._HOST == "windows" then
        return true
    end

    -- check it
    local ok, code = os.iorun("id -u")
    if ok and code and code:trim() == '0' then
        return false, [[Running xmake as root is extremely dangerous and no longer supported.
        As xmake does not drop privileges on installation you would be giving all
        build scripts full access to your system.]]
    end

    -- not root
    return true
end

-- the main function
function main.done()

    -- init 
    main._init()

    -- init option 
    local ok, errors = option.init(menu)  
    if not ok then
        utils.error(errors)
        return -1
    end

    -- check run command as root
    if not option.get("root") then
        local ok, errors = main._check_root()
        if not ok then
            utils.error(errors)
            return -1
        end
    end

    -- start profiling
    if option.get("profile") then
        profiler:start()
    end

    -- run help?
    if main._help() then
        return 0
    end

    -- save command lines to history
    if os.isfile(xmake._PROJECT_FILE) then
        history.save("cmdlines", option.cmdline())
    end

    -- run task    
    ok, errors = task.run(option.taskname() or "build")
    if not ok then
        utils.error(errors)
        return -1
    end

    -- dump deprecated entries
    deprecated.dump()

    -- stop profiling
    if option.get("profile") then
        profiler:stop()
    end

    -- ok
    return 0
end

-- return module: main
return main
