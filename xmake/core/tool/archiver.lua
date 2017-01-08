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
-- @file        archiver.lua
--

-- define module
local archiver = archiver or {}

-- load modules
local io        = require("base/io")
local path      = require("base/path")
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local option    = require("base/option")
local config    = require("project/config")
local sandbox   = require("sandbox/sandbox")
local platform  = require("platform/platform")
local tool      = require("tool/tool")

-- get the current tool
function archiver:_tool()

    -- get it
    return self._TOOL
end

-- get the current flag name
function archiver:_flagname()

    -- get it
    return self._FLAGNAME
end

-- get the flags
function archiver:_flags(target)

    -- get the target key
    local key = tostring(target)

    -- get it directly from cache dirst
    self._FLAGS = self._FLAGS or {}
    if self._FLAGS[key] then
        return self._FLAGS[key]
    end

    -- add flags from the configure 
    local flags = {}
    self:_addflags_from_config(flags)

    -- add flags from the target 
    self:_addflags_from_target(flags, target)

    -- add flags from the platform 
    self:_addflags_from_platform(flags)

    -- add flags from the archiver 
    self:_addflags_from_archiver(flags)

    -- remove repeat
    flags = table.unique(flags)

    -- merge flags
    flags = table.concat(flags, " "):trim()

    -- save flags
    self._FLAGS[key] = flags

    -- get it
    return flags
end

-- map gcc flag to the given archiver flag
function archiver:_mapflag(flag, mapflags)

    -- attempt to map it directly
    local flag_mapped = mapflags[flag]
    if flag_mapped then
        return flag_mapped
    end

    -- find and replace it using pattern
    for k, v in pairs(mapflags) do
        local flag_mapped, count = flag:gsub("^" .. k .. "$", function (w) return v end)
        if flag_mapped and count ~= 0 then
            return utils.ifelse(#flag_mapped ~= 0, flag_mapped, nil) 
        end
    end

    -- check it 
    if self:check(flag) then
        return flag
    end
end

-- map gcc flags to the given archiver flags
function archiver:_mapflags(flags)

    -- wrap flags first
    flags = table.wrap(flags)

    -- done
    local results = {}
    local mapflags = self:get("mapflags")
    if mapflags then

        -- map flags
        for _, flag in pairs(flags) do
            local flag_mapped = self:_mapflag(flag, mapflags)
            if flag_mapped then
                table.insert(results, flag_mapped)
            end
        end

    else

        -- check flags
        for _, flag in pairs(flags) do
            if self:check(flag) then
                table.insert(results, flag)
            end
        end

    end

    -- ok?
    return results
end

-- add flags from the configure 
function archiver:_addflags_from_config(flags)

    -- done
    table.join2(flags, config.get(self:_flagname()))
end

-- add flags from the target 
function archiver:_addflags_from_target(flags, target)

    -- add the target flags 
    table.join2(flags, self:_mapflags(target:get(self:_flagname())))

    -- add the strip flags 
    for _, strip in ipairs(table.wrap(target:get("strip"))) do
        table.join2(flags, self:strip(strip))
    end

    -- add the symbol flags 
    local symbolfile = target:symbolfile()
    for _, symbol in ipairs(table.wrap(target:get("symbols"))) do
        table.join2(flags, self:symbol(symbol, symbolfile))
    end
end

-- add flags from the platform 
function archiver:_addflags_from_platform(flags)

    -- add flags 
    table.join2(flags, platform.get(self:_flagname()))
end

-- add flags from the archiver 
function archiver:_addflags_from_archiver(flags)

    -- done
    table.join2(flags, self:get(self:_flagname()))
end

-- load the archiver 
function archiver.load()

    -- get it directly from cache dirst
    if archiver._INSTANCE then
        return archiver._INSTANCE
    end

    -- new instance
    local instance = table.inherit(archiver)

    -- load the archiver tool from the source file type
    local result, errors = tool.load("ar")
    if not result then 
        return nil, errors
    end
        
    -- save tool
    instance._TOOL = result

    -- init flag name
    instance._FLAGNAME = "arflags"

    -- save this instance
    archiver._INSTANCE = instance

    -- ok
    return instance
end

-- get properties of the tool
function archiver:get(name)

    -- get it
    return self:_tool().get(name)
end

-- archive the library file
function archiver:archive(objectfiles, targetfile, target)

    -- get flags
    local flags = nil
    if target then
        flags = self:_flags(target)
    end

    -- archive it
    return sandbox.load(self:_tool().archive, table.concat(table.wrap(objectfiles), " "), targetfile, flags or "")
end

-- get the archive command
function archiver:archivecmd(objectfiles, targetfile, target)

    -- get flags
    local flags = nil
    if target then
        flags = self:_flags(target)
    end

    -- get it
    return self:_tool().archivecmd(table.concat(table.wrap(objectfiles), " "), targetfile, flags or "")
end

-- make the strip flag
function archiver:strip(level)

    -- make it
    return self:_tool().strip(level)
end

-- make the symbol flag
function archiver:symbol(level, symbolfile)

    -- make it
    return self:_tool().symbol(level, symbolfile)
end

-- check the given flags 
function archiver:check(flags)

    -- the archiver tool
    local ltool = self:_tool()

    -- no check?
    if not ltool.check then
        return true
    end

    -- have been checked? return it directly
    self._CHECKED = self._CHECKED or {}
    if self._CHECKED[flags] ~= nil then
        return self._CHECKED[flags]
    end

    -- check it
    local ok, errors = sandbox.load(ltool.check, flags)

    -- trace
    if option.get("verbose") then
        utils.cprint("checking for the flags %s ... %s", flags, utils.ifelse(ok, "${green}ok", "${red}no"))
        if not ok then
            utils.cprint("${red}" .. errors or "")
        end
    end

    -- save the checked result
    self._CHECKED[flags] = ok

    -- ok?
    return ok
end

-- return module
return archiver
