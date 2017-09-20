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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        install.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- install package
--
-- @param name  the package name
-- @param opt   the options, .e.g {verbose = true, apt = "the package name"}
--
-- @return      true or false
--
function main(name, opt)

    -- init options
    opt = opt or {}

    -- find apt
    local apt = find_tool("apt")
    if not apt then
        return false
    end

    -- init argv
    local argv = {"install", "-y", opt.apt or name}
    if opt.verbose or option.get("verbose") then
        table.insert(argv, "--verbose")
    end

    -- TOOD sudo
    -- install package
    os.vrunv(apt.program, argv)

    -- ok
    return true
end
