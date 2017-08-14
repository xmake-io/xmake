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
local privilege     = require("base/privilege")
local task          = require("base/task")
local project       = require("project/project")
local history       = require("project/history")
local package       = require("package/package")

-- init the option menu
local menu =
{
    -- title
    title = "${bright}xmake v" .. xmake._VERSION .. ", A make-like build utility based on Lua${clear}"

    -- copyright
,   copyright = "Copyright (C) 2015-2017 Ruki Wang, ${underline}tboox.org${clear}, ${underline}xmake.io${clear}\nCopyright (C) 2005-2015 Mike Pall, ${underline}luajit.org${clear}"

    -- the tasks: xmake [task]
,   task.menu

}

-- show logo
function main._show_logo()

    -- define logo
    local logo = [[
                         _        
    __  ___ __  __  __ _| | ______ 
    \ \/ / |  \/  |/ _  | |/ / __ \
     >  <  | \__/ | /_| |   <  ___/
    /_/\_\_|_|  |_|\__ \|_|\_\____| 

                         by ruki, ${underline}tboox.org${clear}

    ${point_right}  ${bright}Manual${clear}: ${underline}http://xmake.io/#/home${clear}
    ${pray}  ${bright}Donate${clear}: ${underline}http://xmake.io/pages/donation.html#donate${clear}
                                      ]]

    -- show logo
    utils.cprint(logo)
end

-- show help and version info
function main._show_help()

    -- show help
    if option.get("help") then
    
        -- print menu
        option.show_menu(option.taskname())

        -- ok
        return true

    -- show version
    elseif option.get("version") then

        -- show title
        if menu.title then
            utils.cprint(menu.title)
        end

        -- show copyright
        if menu.copyright then
            utils.cprint(menu.copyright)
        end

        -- show logo
        main._show_logo()

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

    -- add the directory of the program file (xmake) to $PATH environment
    local programfile = os.programfile()
    if programfile and os.isfile(programfile) then
        os.addenv("PATH", path.directory(programfile))
    else
        os.addenv("PATH", os.programdir())
    end

    -- define task and package apis first before loading project's xmake.lua - calling option.init()
    project.define_apis(task.apis())
    project.define_apis(package.apis())
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
        if os.isroot() then
            if not privilege.store() or os.isroot() then
                utils.error([[Running xmake as root is extremely dangerous and no longer supported.
As xmake does not drop privileges on installation you would be giving all
build scripts full access to your system. 
Or you can add `--root` option to allow run as root temporarily.
                ]])
                return -1
            end
        end
    end

    -- start profiling
    if option.get("profile") then
        profiler:start()
    end

    -- show help?
    if main._show_help() then
        return 0
    end

    -- save command lines to history
    if os.isfile(xmake._PROJECT_FILE) then
        history("local.history"):save("cmdlines", option.cmdline())
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
