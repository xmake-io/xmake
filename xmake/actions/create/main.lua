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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.project")
import("core.project.template")

-- main
function main()

    -- enter the original working directory, because the default directory is in the project directory 
    os.cd(os.workingdir())

    -- the target name
    local targetname = option.get("target") or option.get("name") or path.basename(project.directory()) or "demo"

    -- trace
    cprint("${bright}create %s ...", targetname)

    -- create project from template
    template.create(option.get("language"), option.get("template"), targetname)

    -- trace
    cprint("${bright}create ok!${ok_hand}")
end
