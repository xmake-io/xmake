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
function semver.parse(version, loose)
    return nil
end

-- TODO
--
-- semver.valid('1.2.3') => '1.2.3'
-- semver.valid('a.b.c') => nil
--
function semver.valid(version, loose)
    return true
end

-- TODO
--
function semver.clean(version, loose)
    return nil
end

-- TODO
--
function semver.inc(version, release, loose, identifier)
    return nil
end

-- TODO
--
function semver.diff(v1, v2)
    return nil
end

-- TODO
--
function semver.compare(v1, v2)
    return nil
end

-- TODO
--
function semver.sort(list, loose)
    return nil
end

-- TODO
--
function semver.rsort(list, loose)
    return nil
end

-- TODO
--
-- semver.gt('1.2.3', '9.8.7') => false
--
function semver.gt(v1, v2, loose)
    return true
end

-- TODO
--
-- semver.lt('1.2.3', '9.8.7') => true
--
function semver.lt(v1, v2, loose)
    return true
end

-- TODO
--
-- semver.gte('1.2.3', '9.8.7') => false
--
function semver.gte(v1, v2, loose)
    return true
end

-- TODO
--
-- semver.lte('1.2.3', '9.8.7') => true
--
function semver.lte(v1, v2, loose)
    return true
end

-- TODO
--
-- semver.eq('1.2.3', '9.8.7') => false
--
function semver.eq(v1, v2, loose)
    return true
end

-- TODO
--
-- semver.neq('1.2.3', '9.8.7') => true
--
function semver.neq(v1, v2, loose)
    return true
end

-- TODO
--
function semver.cmp(v1, op, v2, loose)
    return true
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

function semver:__tostring()
    return self.version
end

function semver:__eq(other)
    return false
end

function semver:__lt(other)
    return false
end

function semver:__pow(other)
    return false
end

local function parse_version(s)
    local major, minor, patch, next

    major, minor, patch, next = s:match('^[v=%s]*(%d+)%.(%d+)%.(%d+)(.-)$')
    if not major then
        -- TODO: raise, handle error
        print('Invalid version: ' .. s)
        do return end
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
            -- TODO: raise, handle error
            print('Invalid prerelease: ' .. s)
            do return end
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
            -- TODO: raise, handle error
            print('Invalid build: ' .. s)
            do return end
        end
        build = build .. '.' .. b
    end
    return build, next
end

local function new(version)
    if isa(version, semver) then
        version = version.version
    elseif type(version) ~= 'string' then
        -- TODO: raise, handle error
        print('Invalid Version: ' .. version)
        do return end
    end

    version = version:trim()
    if version:len() > MAX_LENGTH then
        -- TODO: raise, handle error
        print('version is longer than '..MAX_LENGTH..' characters')
        do return end
    end

    local s = setmetatable({
        __index = semver
        ,   raw = version
        ,   prerelease = nil
        ,   build = nil
    }, semver)

    local next
    s.major, s.minor, s.patch, next = parse_version(version)
    if next and next:len() > 0 then
        if next:sub(1, 1) == '-' then
            next = next:sub(2)
        end
        s.prerelease, next = parse_prerelease(next)
    end
    if next and next:len() > 0 then
        if next:sub(1, 1) ~= '+' then
            -- TODO: raise, handle error
            print('expected build, got ' .. next)
            do return end
        end
        next = next:sub(2)
        s.build, next = parse_build(next)
    end

    if s.major > MAX_SAFE_INTEGER or s.major < 0 then
        -- TODO: raise, handle error
        print('Invalid major version')
        do return end
    end
    if s.minor > MAX_SAFE_INTEGER or s.minor < 0 then
        -- TODO: raise, handle error
        print('Invalid minor version')
        do return end
    end
    if s.patch > MAX_SAFE_INTEGER or s.patch < 0 then
        -- TODO: raise, handle error
        print('Invalid patch version')
        do return end
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

    local buffer = { ("%d.%d.%d"):format(s.major, s.minor, s.patch) }
    local a = table.concat(s.prerelease, ".")
    if a and a:len() > 0 then table.insert(buffer, "-" .. a) end
    s.version = table.concat(buffer)

    return s
end

function isa(entity, super)
    return tostring(getmetatable(entity)) == tostring(getmetatable(super))
end

setmetatable(semver, { __call = function(_, ...) return new(...) end })

-- return module: semver
return semver
