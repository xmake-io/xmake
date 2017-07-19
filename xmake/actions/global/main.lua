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
import("core.base.global")

-- main
function main()

    -- load the global configure
    --
    -- priority: option > option_default > config_check > global_cache 
    --
    local override = false
    if not option.get("clean") then
        if not global.load() then
            override = true
        end
    end

    -- override the option configure 
    for name, value in pairs(option.options()) do
        if name ~= "verbose" then
            if global.get(name) ~= value then
                global.set(name, value)
                override = true
            end
        end
    end

    -- merge the default options 
    for name, value in pairs(option.defaults()) do
        if name ~= "verbose" and global.get(name) == nil then
            global.set(name, value)
        end
    end

    -- check the global configure 
    if override then
        global.check()
    end
  
    -- save it
    global.save()

    -- dump it
    global.dump()
end
