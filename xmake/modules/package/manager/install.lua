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
-- @file        install.lua
--

-- install package using third-party package manager
--
-- @param name  the package name
-- @param opt   the options, .e.g {verbose = true, brew = "the package name in brew", pacman = "xxx", apt = "xxx", yum = "xxx"}
--
--
function main(name, opt)

    -- init scripts
    local scripts = {}
    local host = os.host()
    if host == "macosx" then
        table.insert(scripts, import("brew.install",   {anonymous = true}))
    elseif host == "linux" then
        table.insert(scripts, import("apt.install",    {anonymous = true}))
        table.insert(scripts, import("yum.install",    {anonymous = true}))
        table.insert(scripts, import("pacman.install", {anonymous = true}))
        table.insert(scripts, import("brew.install",   {anonymous = true}))
    elseif host == "windows" then
        table.insert(scripts, import("pacman.install", {anonymous = true})) -- msys/mingw
    end
    assert(#scripts > 0, "package manager not found!")

    -- run install script
    for _, script in ipairs(scripts) do
        if script(name, opt) then
            break
        end
    end
end
