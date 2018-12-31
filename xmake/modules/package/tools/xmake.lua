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
-- @file        xmake.lua
--

-- imports
import("core.base.option")

-- install package
function install(package, configs)

    -- inherit builtin configs
    local argv    = {"f", "-y"}
    local names   = {"plat", "arch", "ndk", "ndk_sdkver", "vs", "sdk", "bin", "cross", "ld", "sh", "ar", "cc", "cxx", "mm", "mxx"}
    for _, name in ipairs(names) do
        local value = get_config(name)
        if value ~= nil then
            table.insert(argv, "--" .. name .. "=" .. tostring(value))
        end
    end
    table.insert(argv, "--mode=" .. (package:debug() and "debug" or "release"))

    -- inherit require and option configs
    for name, value in pairs(table.join(package:configs() or {}, configs or {})) do
        table.insert(argv, "--" .. name .. "=" .. tostring(value))
    end
    if option.get("verbose") then
        table.insert(argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(argv, "--diagnosis")
    end
    os.vrunv("xmake", argv)

    -- do build
    argv = {}
    if option.get("verbose") then
        table.insert(argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(argv, "--diagnosis")
    end
    os.vrunv("xmake", argv)

    -- do install
    argv = {"install", "-y", "-o", package:installdir()}
    if option.get("verbose") then
        table.insert(argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(argv, "--diagnosis")
    end
    os.vrunv("xmake", argv)
end
