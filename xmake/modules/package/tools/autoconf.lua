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
-- @file        autoconf.lua
--

-- install package
function install(package, configs)

    -- generate configure file
    if not os.isfile("configure") and os.isfile("configure.ac") then
        os.vrun("autoreconf --install --symlink")
    end

    -- inherit require and option configs
    local argv = {}
    if not configs or not configs.prefix then
        table.insert(argv, "--prefix=" .. package:installdir())
    end
    for name, value in pairs(configs) do
        value = tostring(value):trim()
        if type(name) == "number" then
            if value ~= "" then
                table.insert(argv, value)
            end
        else
            if value:find(" ", 1, true) then
                value = '"' .. value .. '"'
            end
            table.insert(argv, "--" .. name .. "=" .. value)
        end
    end
    os.vrunv("./configure", argv)
    os.vrun("make -j4")
    os.vrun("make install")
end

