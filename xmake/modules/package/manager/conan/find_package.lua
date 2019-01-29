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
-- @file        find_package.lua
--

-- imports
import("core.base.option")
import("core.project.config")

-- get build info file
function _get_buildinfo_file(name)
    return path.absolute(path.join(config.buildir() or os.tmpdir(), ".conan", name, "conanbuildinfo.xmake.lua"))
end

-- find package using the conan package manager
--
-- @param name  the package name
-- @param opt   the options, .e.g {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- get the build info
    local buildinfo_file = _get_buildinfo_file(name)
    if not os.isfile(buildinfo_file) then
        return 
    end

    -- load build info
    local buildinfo = io.load(buildinfo_file)

    -- get the package info of the given platform, architecture and mode
    local found = false
    local result = {}
    for k, v in pairs(buildinfo[opt.plat .. "_" .. opt.arch .. "_" .. opt.mode]) do
        if #table.wrap(v) > 0 then
            result[k] = v
            found = true
        end
    end
    if found then
        return result
    end
end
