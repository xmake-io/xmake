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
-- @file        xmake.lua
--

-- imports
import("core.base.option")

-- build package
function build(package)
    local argv    = {"f", "-y"}
    local configs = {"plat", "arch", "ndk", "ndk_sdkver", "vs", "sdk", "bin", "cross", "ld", "sh", "ar", "cc", "cxx", "mm", "mxx"}
    for _, name in ipairs(configs) do
        local value = get_config(name)
        if value ~= nil then
            if value:find(" ", 1, true) then
                value = '"' .. value .. '"'
            end
            table.insert(argv, "--" .. name .. "=" .. value)
        end
    end
    table.insert(argv, "--mode=" .. (is_mode("debug") and "debug" or "release"))
    os.vrunv("xmake", argv)
    os.vrun("xmake" .. (option.get("verbose") and " -v" or ""))
end

-- install package
function install(package)
    os.vrunv("xmake", {"install", "-o", package:installdir()})
end
