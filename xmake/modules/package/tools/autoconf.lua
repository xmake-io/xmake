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
-- @file        autoconf.lua
--

-- install package
function install(package, configs)

    -- generate configure file
    if not os.isfile("configure") then
        if os.isfile("autogen.sh") then
            os.vrunv("sh", {"./autogen.sh"})
        elseif os.isfile("configure.ac") then
            os.vrun("autoreconf --install --symlink")
        end
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
            table.insert(argv, "--" .. name .. "=" .. value)
        end
    end

    -- inherit flags from configs
    local flags_prev = {}
    for _, name in ipairs({"cflags", "cxxflags", "ldflags"}) do
        local flags = package:config(name) or (configs and configs[name] or nil)
        if flags then
            flags_prev[name] = os.getenv(name:upper())
            os.addenv(name:upper(), flags)
        end
    end

    -- do configure
    os.vrunv("./configure", argv)

    -- do make and install
    os.vrun("make -j4")
    os.vrun("make install")

    -- restore flags
    for name, flags in pairs(flags_prev) do
        os.setenv(name:upper(), flags)
    end
end

