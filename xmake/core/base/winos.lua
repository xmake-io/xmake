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
-- @file        winos.lua
--

-- define module: winos
local winos = winos or {}

-- load modules
local os     = require("base/os")
local path   = require("base/path")
local semver = require("base/semver")

winos._ansi_cp         = winos._ansi_cp or winos.ansi_cp
winos._oem_cp          = winos._oem_cp  or winos.oem_cp
winos._registry_query  = winos._registry_query or winos.registry_query
winos._registry_keys   = winos._registry_keys or winos.registry_keys
winos._registry_values = winos._registry_values or winos.registry_values

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
    local winver = winos._VERSION
    if winver == nil then

        -- get winver
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
        if not winver then
            winver = semver.new("0.0")
        end

        -- rewrite comparator
        winver.eq = winos._version_eq
        winver.lt = winos._version_lt
        winver.le = winos._version_le
        winos._VERSION = winver
    end
    return winver
end

-- get command arguments on windows to solve 8192 character command line length limit
function winos.cmdargv(argv, opt)

    -- too long arguments?
    local limit = 4096
    local argn = 0
    for _, arg in ipairs(argv) do
        arg = tostring(arg)
        argn = argn + #arg
        if argn > limit then
            break
        end
    end
    if argn > limit then
        opt = opt or {}
        local argsfile = os.tmpfile(opt.tmpkey or os.args(argv)) .. ".args.txt"
        local f = io.open(argsfile, 'w', {encoding = "ansi"})
        if f then
            -- we need split args file to solve `fatal error LNK1170: line in command file contains 131071 or more characters`
            -- @see https://github.com/xmake-io/xmake/issues/812
            local idx = 1
            while idx <= #argv do
                arg = tostring(argv[idx])
                arg1 = argv[idx + 1]
                if arg1 then
                    arg1 = tostring(arg1)
                end
                -- we need ensure `/name value` in same line,
                -- otherwise cl.exe will prompt that the corresponding parameter value cannot be found
                --
                -- e.g.
                --
                -- /sourceDependencies xxxx.json
                -- -Dxxx
                -- foo.obj
                --
                if idx + 1 <= #argv and arg:find("^[-/]") and not arg1:find("^[-/]") then
                    f:write(os.args(arg, {escape = opt.escape}) .. " ")
                    f:write(os.args(arg1, {escape = opt.escape}) .. "\n")
                    idx = idx + 2
                else
                    f:write(os.args(arg, {escape = opt.escape}) .. "\n")
                    idx = idx + 1
                end
            end
            f:close()
        end
        argv = {"@" .. argsfile}
    end
    return argv
end

-- query registry value
--
-- @param keypath   the key path
-- @return          the value and errors
--
-- @code
-- local value, errors = winos.registry_query("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug")
-- local value, errors = winos.registry_query("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug;Debugger")
-- @endcode
--
function winos.registry_query(keypath)

    -- get value name
    local splitinfo = keypath:split(';', {plain = true})
    local valuename = splitinfo[2] or ""
    keypath = splitinfo[1]

    -- get rootkey, e.g. HKEY_LOCAL_MACHINE
    local rootkey
    local p = keypath:find("\\", 1, true)
    if p then
        rootkey = keypath:sub(1, p - 1)
    end
    if not rootkey then
        return nil, "root key not found!"
    end

    -- get the root directory
    local rootdir = keypath:sub(p + 1)

    -- query value
    return winos._registry_query(rootkey, rootdir, valuename)
end

-- get registry key paths
--
-- @param keypath   the key path (support key pattern, e.g. \\a\\b;xx*yy)
--                  uses "*" to match any part of a key path,
--                  uses "**" to recurse into subkey paths.
-- @return          the result array and errors
--
-- @code
-- local keys, errors = winos.registry_keys("HKEY_LOCAL_MACHINE\\SOFTWARE\\*\\Windows NT\\*\\CurrentVersion\\AeDebug")
-- local keys, errors = winos.registry_keys("HKEY_LOCAL_MACHINE\\SOFTWARE\\**")
-- @endcode
--
function winos.registry_keys(keypath)

    -- get rootkey, e.g. HKEY_LOCAL_MACHINE
    local rootkey
    local p = keypath:find("\\", 1, true)
    if p then
        rootkey = keypath:sub(1, p - 1)
    end
    if not rootkey then
        return
    end
    keypath = keypath:sub(p + 1)

    -- get the root directory
    local pattern
    local rootdir = keypath
    p = rootdir:find("*", 1, true)
    if p then
        pattern = path.pattern(rootdir)
        rootdir = path.directory(rootdir:sub(1, p - 1))
    end

    -- compute the recursion level
    --
    -- infinite recursion: aaa\\**
    -- limit recursion level: aaa\\*\\*
    local recursion = 0
    if keypath:find("**", 1, true) then
        recursion = -1
    else
        -- "aaa\\*\\*" -> "*\\" -> recursion level: 1
        -- "aaa\\*\\xxx" -> "*\\" -> recursion level: 1
        -- "aaa\\*\\subkey\\xxx" -> "*\\\\" -> recursion level: 2
        if p then
            local _, seps = keypath:sub(p):gsub("\\", "")
            if seps > 0 then
                recursion = seps
            end
        end
    end

    -- get keys
    local keys = {}
    local count, errors = winos._registry_keys(rootkey, rootdir, recursion, function (key)
        if not pattern or key:match("^" .. pattern .. "$") then
            table.insert(keys, rootkey .. '\\' .. key)
            if #keys > 4096 then
                return false
            end
        end
        return true
    end)
    if #keys > 4096 then
        return nil, "too much registry keys: " .. keypath
    end
    if count ~= nil then
        return keys
    else
        return nil, errors
    end
end

-- get registry values from the given key path
--
-- @param keypath   the key path (support value pattern, e.g. \\a\\b;xx*yy)
--                  uses "*" to match value name,
-- @return          the values array and errors
--
-- @code
-- local values, errors = winos.registry_values("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug")
-- local values, errors = winos.registry_values("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug;Debug*")
-- @endcode
--
function winos.registry_values(keypath)

    -- get value pattern
    local splitinfo = keypath:split(';', {plain = true})
    local pattern = splitinfo[2]
    if pattern then
        pattern = path.pattern(pattern)
    end
    keypath = splitinfo[1]

    -- get rootkey, e.g. HKEY_LOCAL_MACHINE
    local rootkey
    local p = keypath:find("\\", 1, true)
    if p then
        rootkey = keypath:sub(1, p - 1)
    end
    if not rootkey then
        return nil, "root key not found!"
    end

    -- get the root directory
    local rootdir = keypath:sub(p + 1)

    -- get value names
    local value_names = {}
    local count, errors = winos._registry_values(rootkey, rootdir, function (value_name)
        if not pattern or value_name:match("^" .. pattern .. "$") then
            table.insert(value_names, rootkey .. "\\" .. rootdir .. ";" .. value_name)
        end
        return true
    end)
    if count ~= nil then
        return value_names
    else
        return nil, errors
    end
end

-- inherit handles in CreateProcess safely?
-- https://github.com/xmake-io/xmake/issues/2902#issuecomment-1326934902
--
function winos.inherit_handles_safely()
    local inherit_handles_safely = winos._INHERIT_HANDLES_SAFELY
    if inherit_handles_safely == nil then
        inherit_handles_safely = winos.version():ge("win7") or false
        winos._INHERIT_HANDLES_SAFELY = inherit_handles_safely
    end
    return inherit_handles_safely
end

-- return module: winos
return winos
