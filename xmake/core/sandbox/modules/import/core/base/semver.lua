--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
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

-- new a version instance
function sandbox_core_base_semver.new(version)
    local result, errors = semver.new(version)
    if errors then
        raise(errors)
    end
    return result
end

-- match a valid version from the string
--
-- semver.match('xxx 1.2.3 xxx') => { major = 1, minor = 2, patch = 3, ... }
-- semver.match('a.b.c') => nil
--
function sandbox_core_base_semver.match(str, pos, pattern)
    return semver.match(str, pos)
end

-- is valid version?
function sandbox_core_base_semver.is_valid(version)
    return semver.parse(version) ~= nil
end

-- compare two version strings
--
-- semver.compare('1.2.3', '1.3.0') > 0?
--
function sandbox_core_base_semver.compare(version1, version2)
    local result, errors = semver.compare(version1, version2)
    if errors then
        raise(errors)
    end
    return result
end

-- this version satisfies in the given version range
--
-- semver.satisfies('1.2.3', '1.x || >=2.5.0 || 5.0.0 - 7.2.3') => true
--
function sandbox_core_base_semver.satisfies(version, range)
    local result, errors = semver.satisfies(version, range)
    if errors then
        raise(errors)
    end
    return result
end

-- select required version from versions, tags and branches
--
-- e.g.
--
-- local version, source = semver.select(">=1.5.0 <1.6", {"1.5.0", "1.5.1"}, {"v1.5.0", ..}, {"master", "dev"})
--
-- @version     the selected version number
-- @source      the version source, e.g. versions, tags, branchs
--
function sandbox_core_base_semver.select(range, versions, tags, branches)
    local verinfo, errors = semver.select(range, table.wrap(versions), table.wrap(tags), table.wrap(branches))
    if not verinfo then
        raise(errors)
    end
    return verinfo.version, verinfo.source
end

-- return module
return sandbox_core_base_semver
