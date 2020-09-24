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
-- @file        winos.lua
--

-- define module: winos
local winos = winos or {}

-- load modules
local os     = require("base/os")
local semver = require("base/semver")

winos._ansi_cp  = winos._ansi_cp or winos.ansi_cp
winos._oem_cp   = winos._oem_cp  or winos.oem_cp

function winos.ansi_cp()
    if not winos._ANSI_CP then
         winos._ANSI_CP = winos._ansi_cp()
    end
    return winos._ANSI_CP
end

function winos.oem_cp()
    if not winos._OEM_CP then
         winos._OEM_CP = winos._oem_cp()
    end
    return winos._OEM_CP
end

-- get windows version from name
function winos._version_from_name(name)

    -- make defined values
    winos._VERSIONS = winos._VERSIONS or
    {
        nt4      = "4.0"
    ,   win2k    = "5.0"
    ,   winxp    = "5.1"
    ,   ws03     = "5.2"
    ,   win6     = "6.0"
    ,   vista    = "6.0"
    ,   ws08     = "6.0"
    ,   longhorn = "6.0"
    ,   win7     = "6.1"
    ,   win8     = "6.2"
    ,   winblue  = "6.3"
    ,   win81    = "6.3"
    ,   win10    = "10.0"
    }
    return winos._VERSIONS[name]
end

-- v1 == v2 with name (winxp, win10, ..)?
function winos._version_eq(self, version)
    if type(version) == "string" then
        local namever = winos._version_from_name(version)
        if namever then
            return semver.compare(self:major() .. '.' .. self:minor(), namever) == 0
        else
            return semver.compare(self:rawstr(), version) == 0
        end
    elseif type(version) == "table" then
        return semver.compare(self:rawstr(), version:rawstr()) == 0
    end
end

-- v1 < v2 with name (winxp, win10, ..)?
function winos._version_lt(self, version)
    if type(version) == "string" then
        local namever = winos._version_from_name(version)
        if namever then
            return semver.compare(self:major() .. '.' .. self:minor(), namever) < 0
        else
            return semver.compare(self:rawstr(), version) < 0
        end
    elseif type(version) == "table" then
        return semver.compare(self:rawstr(), version:rawstr()) < 0
    end
end

-- v1 <= v2 with name (winxp, win10, ..)?
function winos._version_le(self, version)
    if type(version) == "string" then
        local namever = winos._version_from_name(version)
        if namever then
            return semver.compare(self:major() .. '.' .. self:minor(), namever) <= 0
        else
            return semver.compare(self:rawstr(), version) <= 0
        end
    elseif type(version) == "table" then
        return semver.compare(self:rawstr(), version:rawstr()) <= 0
    end
end

-- get system version
function winos.version()

    -- get it from cache first
    if winos._VERSION ~= nil then
        return winos._VERSION
    end

    -- get winver
    local winver = nil
    local ok, verstr = os.iorun("cmd /c ver")
    if ok and verstr then
        winver = verstr:match("%[.-([%d%.]+)]")
        if winver then
            winver = winver:trim()
        end
        local sem_winver = nil
        local seg = 0
        for num in winver:gmatch("%d+") do
            if seg == 0 then
                sem_winver = num
            elseif seg == 3 then
                sem_winver = sem_winver .. "+" .. num
            else
                sem_winver = sem_winver .. "." .. num
            end
            seg = seg + 1
        end
        winver = semver.new(sem_winver)
    end

    -- rewrite comparator
    if winver then
        winver.eq = winos._version_eq
        winver.lt = winos._version_lt
        winver.le = winos._version_le
    end

    -- save to cache
    winos._VERSION = winver or false
    return winver
end

-- get command arguments on windows to solve 8192 character command line length limit
function winos.cmdargv(argv, key)

    -- too long arguments?
    local limit = 4096
    local argn = 0
    for _, arg in ipairs(argv) do
        argn = argn + #arg
        if argn > limit then
            break
        end
    end
    if argn > limit then
        local argsfile = os.tmpfile(key or table.concat(argv, '')) .. ".args.txt"
        local f = io.open(argsfile, 'w')
        if f then
            -- we need split args file to solve `fatal error LNK1170: line in command file contains 131071 or more characters`
            -- @see https://github.com/xmake-io/xmake/issues/812
            for _, arg in ipairs(argv) do
                f:write(os.args(arg, {escape = true}) .. "\n")
            end
            f:close()
        end
        argv = {"@" .. argsfile}
    end
    return argv
end

-- return module: winos
return winos
