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

-- define module: semver
local semver = semver or {}

-- A semantic versioner
--
-- A "version" is described by the v2.0.0 specification found at http://semver.org/.
--
-- More refernces:
-- - https://github.com/npm/node-semver 
-- - https://github.com/kikito/semver.lua
-- - https://getcomposer.org/doc/articles/versions.md

-- TODO
--
-- semver.valid('1.2.3') => '1.2.3'
-- semver.valid('a.b.c') => nil
function semver.valid(version)
end

-- TODO
--
-- semver.satisfies('1.2.3', '1.x || >=2.5.0 || 5.0.0 - 7.2.3') => true
--
function semver.satisfies(version, range, loose)
end

-- TODO
--
-- semver.gt('1.2.3', '9.8.7') => false
--
function semver.gt(v1, v2, loose)
end

-- TODO
--
-- semver.lt('1.2.3', '9.8.7') => true
--
function semver.lt(v1, v2, loose)
end

-- select required version from versions, tags and branches
--
-- .e.g
--
-- local verinfo, errors = semver.select(">=1.5.0 <1.6", {"1.5.0", "1.5.1"}, {"v1.5.0", ..}, {"master", "dev"})
--
-- verinfo = 
-- {
--     version = "1.5.1"
--     source = "versions"    
-- }
--
-- @version     the selected version number
-- @source      the version source, .e.g versions, tags, branchs
--
function semver.select(required_ver, versions, tags, branches)

    -- TODO only select the first one now.
    if versions and versions[1] then
        return {version = versions[1], source = "versions"}
    elseif tags and tags[1] then
        return {version = tags[1], source = "tags"}
    elseif branches and branches[1] then
        return {version = branches[1], source = "branches"}
    end

    -- not found
    return nil, string.format("cannot select version %s", required_ver)
end

-- return module: semver
return semver
