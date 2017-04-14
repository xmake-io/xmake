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
-- @file        semver.lua
--

-- define module
local sandbox_core_base_semver = sandbox_core_base_semver or {}

-- load modules
local table  = require("base/table")
local semver = require("base/semver")
local raise  = require("sandbox/modules/raise")

-- select required version from versions, tags and branches
--
-- .e.g
--
-- local version, kind = semver.select(">=1.5.0 <1.6", {"1.5.0", "1.5.1"}, {"v1.5.0", ..}, {"master", "dev"})
--
-- @version     the selected version number
-- @kind        the version kind, .e.g string, tag, branch
--
function sandbox_core_base_semver.select(required_ver, versions, tags, branches)

    -- select version
    local verinfo, errors = semver.select(required_ver, versions, tags, branches)
    if not results then
        raise(errors)
    end

    -- ok
    return verinfo.version, version.kind
end

-- return module
return sandbox_core_base_semver
