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
-- @param opt   the options, .e.g {verbose = true, pacman = "the package name"}
--
-- @return      true or false
--
function main(name, opt)

    -- init options
    opt = opt or {}

    -- find pacman
    local pacman = find_tool("pacman")
    if not pacman then
        return false
    end

    -- init argv
    local argv = {"-S", "--noconfirm", "--needed", opt.pacman or name}
    if opt.verbose or option.get("verbose") then
        table.insert(argv, "--verbose")
    end

    -- TODO sudo
    -- install package
    os.vrunv(pacman.program, argv)

    -- ok
    return true
end
