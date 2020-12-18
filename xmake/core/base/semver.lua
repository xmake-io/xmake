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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        semver.lua
--

-- define module: semver
local semver = semver or {}
local _instance = _instance or {}

-- load modules
local os        = require("base/os")
local string    = require("base/string")

-- get the version info
function _instance:get(name)

    -- get it from info first
    local value = self._INFO[name]
    if value ~= nil then
        return value
    end
end

-- get the major version, e.g. v{major}.{minor}.{patch}
function _instance:major()
    return self:get("major")
end

-- get the minor version
function _instance:minor()
    return self:get("minor")
end

-- get the patch version
function _instance:patch()
    return self:get("patch")
end

-- get the build version, e.g. v1.0.1+{build}
function _instance:build()
    return self:get("build")
end

-- get the prerelease version, e.g. v1.0.1-{prerelease}
function _instance:prerelease()
    return self:get("prerelease")
end

-- get the raw version string
function _instance:rawstr()
    return self:get("raw")
end

-- get the short version string
function _instance:shortstr()
    local str = self:major()
    if self:minor() then
        str = str .. "." .. self:minor()
    end
    if self:patch() then
        str = str .. "." .. self:patch()
    end
    return str
end

-- satisfies the given semantic version(e.g. '> 1.0 < 2.0', '~1.5')?
function _instance:satisfies(version)
    return semver.satisfies(self:rawstr(), version)
end

-- is in the given version range, [version1, version2]?
function _instance:at(version1, version2)
    return self:ge(version1) and self:le(version2)
end

-- add string compatible interface, string.sub
function _instance:sub(...)
    return self:rawstr():sub(...)
end

-- add string compatible interface, string.gsub
function _instance:gsub(...)
    return self:rawstr():gsub(...)
end

-- add string compatible interface, string.split
function _instance:split(...)
    return self:rawstr():split(...)
end

-- add string compatible interface, string.startswith
function _instance:startswith(...)
    return self:rawstr():startswith(...)
end

-- add string compatible interface, string.endswith
function _instance:endswith(...)
    return self:rawstr():endswith(...)
end

-- v1 == v2 (str/ver)?
function _instance:eq(version)
    if type(version) == "string" then
        return semver.compare(self:rawstr(), version) == 0
    elseif type(version) == "table" then
        return semver.compare(self:rawstr(), version:rawstr()) == 0
    end
end

-- v1 < v2 (str/ver)?
function _instance:lt(version)
    if type(version) == "string" then
        return semver.compare(self:rawstr(), version) < 0
    elseif type(version) == "table" then
        return semver.compare(self:rawstr(), version:rawstr()) < 0
    end
end

-- v1 <= v2 (str/ver)?
function _instance:le(version)
    if type(version) == "string" then
        return semver.compare(self:rawstr(), version) <= 0
    elseif type(version) == "table" then
        return semver.compare(self:rawstr(), version:rawstr()) <= 0
    end
end

-- v1 > v2 (str/ver)?
function _instance:gt(version)
    return not self:le(version)
end

-- v1 >= v2 (str/ver)?
function _instance:ge(version)
    return not self:lt(version)
end

-- v1 == v2?
function _instance:__eq(version)
    return self:eq(version)
end

-- v1 < v2?
function _instance:__lt(version)
    return self:lt(version)
end

-- v1 <= v2?
function _instance:__le(version)
    return self:le(version)
end

-- get the raw version string
function _instance:__tostring()
    return self:rawstr()
end

-- add string compatible interface, e.g. version .. str
function _instance.__concat(op1, op2)
    if type(op1) == "string" then
        return op1 .. op2:rawstr()
    elseif type(op2) == "string" then
        return op1:rawstr() .. op2
    else
        return op1:rawstr() .. op2:rawstr()
    end
end

-- new an instance
function semver.new(version)

    -- parse version first
    local info, errors = semver.parse(version)
    if not info then
        return nil, errors
    end

    -- new an instance
    local instance = table.inherit(_instance)
    instance._INFO = info
    return instance
end

-- try to match valid version from string
function semver.match(str, pos, pattern)
    local patterns = pattern or {"%d+[.]%d+[-+.%w]*", "%d+[.]%d+[.]%d+", "%d+[.]%d+"}
    for _, pattern in ipairs(table.wrap(patterns)) do
        local version_str = str:match(pattern, pos)
        if version_str then
            local info = semver.parse(version_str)
            if info then
                local instance = table.inherit(_instance)
                instance._INFO = info
                return instance
            end
        end
    end
end

-- return module: semver
return semver
