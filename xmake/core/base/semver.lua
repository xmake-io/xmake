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

-- load modules
local string = require("base/string")

-- A semantic versioner
--
-- A "version" is described by the v2.0.0 specification found at http://semver.org/.
--
-- More refernces:
-- - https://github.com/npm/node-semver 
-- - https://github.com/kikito/semver.lua
-- - https://getcomposer.org/doc/articles/versions.md

local MAX_LENGTH = 256
local MAX_SAFE_INTEGER = 9007199254740991

-- TODO
--
-- semver.parse('1.2.3') => { major = 1, minor = 2, patch = 3, ... }
-- semver.parse('a.b.c') => nil
function semver.parse(version)
    if isa(version, semver) then
        return version
    end

    if type(version) ~= 'string' then
        return nil
    end

    if version:len() > MAX_LENGTH then
        return nil
    end

    local version, errors = semver(version)
    if errors then
        return null
    end

    return version
end

-- TODO
--
-- semver.valid('1.2.3') => '1.2.3'
-- semver.valid('a.b.c') => nil
--
function semver.valid(version)
    local v = semver(version)
    if v then
        return v.version
    end
    return nil
end

-- TODO
--
function semver.compare(v1, v2)
    local errors

    if not isa(v1, semver) then
        v1, errors = semver(v1)
    end
    if errors then
        return nil, errors
    end

    return v1:compare(v2)
end

-- TODO
--
-- semver.gt('1.2.3', '9.8.7') => false
--
function semver.gt(v1, v2)
    local errors

    if not isa(v1, semver) then
        v1, errors = semver(v1)
    end
    if errors then
        return nil, errors
    end

    return v1 > v2
end

-- TODO
--
-- semver.lt('1.2.3', '9.8.7') => true
--
function semver.lt(v1, v2)
    local errors

    if not isa(v1, semver) then
        v1, errors = semver(v1)
    end
    if errors then
        return nil, errors
    end

    return v1 < v2
end

-- TODO
--
-- semver.gte('1.2.3', '9.8.7') => false
--
function semver.gte(v1, v2, loose)
    local errors

    if not isa(v1, semver) then
        v1, errors = semver(v1)
    end
    if errors then
        return nil, errors
    end

    return v1 >= v2
end

-- TODO
--
-- semver.lte('1.2.3', '9.8.7') => true
--
function semver.lte(v1, v2, loose)
    local errors

    if not isa(v1, semver) then
        v1, errors = semver(v1)
    end
    if errors then
        return nil, errors
    end

    return v1 <= v2
end

-- TODO
--
-- semver.eq('1.2.3', '9.8.7') => false
--
function semver.eq(v1, v2, loose)
    local errors

    if not isa(v1, semver) then
        v1, errors = semver(v1)
    end
    if errors then
        return nil, errors
    end

    return v1 == v2
end

-- TODO
--
-- semver.neq('1.2.3', '9.8.7') => true
--
function semver.neq(v1, v2, loose)
    local errors

    if not isa(v1, semver) then
        v1, errors = semver(v1)
    end
    if errors then
        return nil, errors
    end

    return v1 ~= v2
end

-- TODO
--
function semver.cmp(v1, op, v2, loose)
    local errors

    if not isa(v1, semver) then
        v1, errors = semver(v1)
    end
    if errors then
        return nil, errors
    end

    return v1:compare(v2)
end

-- TODO
--
-- semver.satisfies('1.2.3', '1.x || >=2.5.0 || 5.0.0 - 7.2.3') => true
--
function semver.satisfies(version, range, loose)
    return true
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
function semver.select(range, versions, tags, branches)

    -- TODO only select the first one now.
    if versions and versions[1] then
        return {version = versions[1], source = "versions"}
    elseif tags and tags[1] then
        return {version = tags[1], source = "tags"}
    elseif branches and branches[1] then
        return {version = branches[1], source = "branches"}
    end

    -- not found
    return nil, string.format("cannot select version %s", range)
end

function semver:format()
    local buffer = { ("%d.%d.%d"):format(self.major, self.minor, self.patch) }
    local a = table.concat(self.prerelease, ".")
    if a and a:len() > 0 then table.insert(buffer, "-" .. a) end
    self.version = table.concat(buffer)
end

function semver:__tostring()
    return self.version
end

local function compare_ids(a, b)
    local anum, bnum;

    if a and tostring(a):match('^%d+$') then
        anum = tonumber(a)
    end
    if b and tostring(b):match('^%d+$') then
        anum = tonumber(b)
    end

    if anum and not bnum then
        return -1
    elseif bnum and not anum then
        return 1
    elseif a < b then
        return -1
    elseif a > b then
        return 1
    else
        return 0
    end
end

local function rcompare_ids(a, b)
    return compare_ids(b, a)
end

function semver:compare(other)
    local errors

    if not isa(other, semver) then
        other, errors = semver(other)
    end
    if errors then
        return nil, errors
    end

    return self:compare_main(other) or self:compare_pre(other)
end

function semver:compare_main(other)
    local errors

    if not isa(other, semver) then
        other, errors = semver(other)
    end
    if errors then
        return nil, errors
    end

    return compare_ids(self.major, other.major) or
        compare_ids(self.minor, other.minor) or
        compare_ids(self.patch, other.patch)
end

function semver:compare_pre(other)
    local errors

    if not isa(other, semver) then
        other, errors = semver(other)
    end
    if errors then
        return nil, errors
    end

    if self.prerelease:len() and not other.prerelease:len() then
        return -1
    elseif not self.prerelease:len() and other.prerelease:len() then
        return 1
    elseif not self.prerelease:len() and not other.prerelease:len() then
        return 0
    end

    local i = 0
    repeat
        local a = self.prerelease[i];
        local b = other.prerelease[i];
        if not a and not b then
            return 0
        elseif not b then
            return 1
        elseif not a then
            return -1
        elseif a ~= b then
            return compare_ids(a, b);
        end
        i = i + 1
    until i
end

function semver:__eq(other)
    return self:compare(other) == 0
end

function semver:__lt(other)
    return self:compare(other) < 0
end

function semver:__pow(other)
    return self:compare(other)
end

local function parse_version(s)
    local major, minor, patch, next

    major, minor, patch, next = s:match('^[v=%s]*(%d+)%.(%d+)%.(%d+)(.-)$')
    if not major then
        return nil, nil, nil, nil, string.format("invalid version %s", s)
    end

    return tonumber(major), tonumber(minor), tonumber(patch), next
end

local function parse_prerelease(s)
    local prerelease, next = s:match('^(%d*[%a-][%a%d-]*)(.-)$')
    if not prerelease or prerelease:len() == 0 then
        prerelease, next = s:match('^(%d+)(.-)$')
        if prerelease and prerelease:len() > 0 then
            local n = tonumber(prerelease)
            if n >= 0 and n < MAX_SAFE_INTEGER then
                prerelease = n
            end
        end
    end
    if next and next:sub(1, 1) == '.' then
        local p
        p, next = parse_prerelease(next:sub(2))
        if not p or (type(p) == 'string' and p:len() == 0) then
            return nil, nil, string.format("invalid prerelease %s", s)
        end
        prerelease = prerelease .. '.' .. p
    end
    return prerelease, next
end

local function parse_build(s)
    local build, next = s:match('^([%d%a-]+)(.-)$')
    if next and next:len() > 0 and next:sub(1, 1) == '.' then
        local b
        b, next = parse_build(next:sub(2))
        if not b or b:len() == 0 then
            return nil, nil, string.format("invalid build %s", s)
        end
        build = build .. '.' .. b
    end
    return build, next
end

local function new(version)
    if isa(version, semver) then
        version = version.version
    elseif type(version) ~= 'string' then
        return nil, "invalid build" .. version
    end

    version = version:trim()
    if version:len() > MAX_LENGTH then
        return nil, string.format("version is longer than %d characters", MAX_LENGTH)
    end

    local s = setmetatable({
        __index = semver
        ,   raw = version
        ,   prerelease = nil
        ,   build = nil
    }, semver)

    local next, errors
    s.major, s.minor, s.patch, next, errors = parse_version(version)
    if errors then
        return nil, errors
    end
    if next and next:len() > 0 then
        if next:sub(1, 1) == '-' then
            next = next:sub(2)
        end
        s.prerelease, next, errors = parse_prerelease(next)
        if errors then
            return nil, errors
        end
    end
    if next and next:len() > 0 then
        if next:sub(1, 1) ~= '+' then
            return nil, string.format("expected build, got %s", next)
        end
        next = next:sub(2)
        s.build, next, errors = parse_build(next)
        if errors then
            return nil, errors
        end
    end

    if s.major > MAX_SAFE_INTEGER or s.major < 0 then
        return nil, string.format("invalid major version %d", s.major)
    end
    if s.minor > MAX_SAFE_INTEGER or s.minor < 0 then
        return nil, string.format("invalid minor version %d", s.minor)
    end
    if s.patch > MAX_SAFE_INTEGER or s.patch < 0 then
        return nil, string.format("invalid patch version %d", s.patch)
    end

    if s.prerelease then
        s.prerelease = s.prerelease:split(".")
    else
        s.prerelease = {}
    end

    if s.build then
        s.build = s.build:split(".")
    else
        s.build = {}
    end

    s:format()

    return s
end

function isa(entity, super)
    return tostring(getmetatable(entity)) == tostring(getmetatable(super))
end

setmetatable(semver, { __call = function(_, ...) return new(...) end })

-- return module: semver
return semver
