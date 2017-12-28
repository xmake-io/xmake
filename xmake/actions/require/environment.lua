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
-- @file        environment.lua
--

-- imports
import("core.project.config")
import("core.platform.environment")
import("lib.detect.find_tool")
import("package")

-- enter environment
--
-- ensure that we can find some basic tools: git, make/nmake/cmake, msbuild ...
--
-- If these tools not exist, we will install it first.
--
function enter()

    -- set search pathes of toolchains 
    environment.enter("toolchains")

    -- git not found? install it first
    if not find_tool("git") then
        package.install_packages("git")
    end

    -- set the environment variables of toolchains 
    _g.toolenvs = {}
    for _, name in ipairs("cc", "cxx", "mm", "mxx", "ld", "ar", "sh") do
        local value = config.get(name)
        if value then
            _g.toolenvs[name] = os.getenv(name:upper()) or ""
            os.setenv(name:upper(), value)
        end
    end
end

-- leave environment
function leave()

    -- restore the environment variables of toolchains 
    for _, name in ipairs("cc", "cxx", "mm", "mxx", "ld", "ar", "sh") do
        local value = _g.toolenvs[name]
        if value then
            os.setenv(name:upper(), value)
        end
    end

    -- restore search pathes of toolchains
    environment.leave("toolchains")
end
