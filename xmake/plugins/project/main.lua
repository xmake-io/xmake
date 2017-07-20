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

-- imports
import("core.base.option")
import("core.base.task")
import("core.platform.environment")
import("makefile.makefile")
import("vstudio.vs2002")
import("vstudio.vs2003")
import("vstudio.vs2005")
import("vstudio.vs2008")
import("vstudio.vs2010")
import("vstudio.vs2012")
import("vstudio.vs2013")
import("vstudio.vs2015")
import("vstudio.vs2017")
import("clang.compile_commands")

-- make project
function _make(kind)

    -- the maps
    local maps = 
    {
        makefile         = makefile.make
    ,   vs2002           = vs2002.make
    ,   vs2003           = vs2003.make
    ,   vs2005           = vs2005.make
    ,   vs2008           = vs2008.make
    ,   vs2010           = vs2010.make
    ,   vs2012           = vs2012.make
    ,   vs2013           = vs2013.make
    ,   vs2015           = vs2015.make
    ,   vs2017           = vs2017.make
    ,   compile_commands = compile_commands.make
    }
    assert(maps[kind], "the project kind(%s) is not supported!", kind)
    
    -- make it
    maps[kind](option.get("outputdir"))
end

-- main
function main()

    -- config it first
    task.run("config")

    -- enter toolchains environment
    environment.enter("toolchains")

    -- make project
    _make(option.get("kind"))

    -- leave toolchains environment
    environment.leave("toolchains")

    -- trace
    cprint("${bright}create ok!${ok_hand}")
end
