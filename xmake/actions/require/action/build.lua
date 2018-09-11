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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        build.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.sandbox.sandbox")
import("filter")

-- build the given package
function main(package)

    -- the package scripts
    local scripts =
    {
        package:script("build_before") 
    ,   package:script("build")
    ,   package:script("build_after") 
    }

    -- save the current directory
    local oldir = os.curdir()

    -- build it
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            filter.call(script, package)
        end
    end

    -- restore the current directory
    os.cd(oldir)
end
