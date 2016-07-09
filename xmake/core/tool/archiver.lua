--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
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

-- get the named flags
function archiver:_named_flags(names, flags)

    -- map it 
    local flags_mapped = {}
    for _, name in ipairs(table.wrap(names)) do
        table.join2(flags_mapped, self:_mapflags(flags[name]))
    end

    -- get it
    return flags_mapped
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
    table.join2(flags, self:_named_flags(target:get("strip"), {     debug       = "-S"
                                                                ,   all         = "-s"
                                                                }))
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
    utils.verbose("checking for the flags %s ... %s", flags, utils.ifelse(ok, "ok", "no"))
    if not ok then
        utils.verbose(errors)
    end

    -- save the checked result
    self._CHECKED[flags] = ok

    -- ok?
    return ok
end

-- return module
return archiver
