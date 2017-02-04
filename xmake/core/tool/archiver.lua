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
local language  = require("language/language")
local platform  = require("platform/platform")
local tool      = require("tool/tool")
local builder   = require("tool/builder")

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

    -- add flags (named) from language
    self:_addflags_from_language(flags, target)

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

-- add flags from the configure 
function archiver:_addflags_from_config(flags)

    -- done
    table.join2(flags, config.get(self:_flagname()))
end

-- add flags from the target 
function archiver:_addflags_from_target(flags, target)

    -- add the target flags 
    table.join2(flags, self:_mapflags(target:get(self:_flagname())))
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
function archiver.load(sourcekinds)

    -- get it directly from cache dirst
    if archiver._INSTANCE then
        return archiver._INSTANCE
    end

    -- new instance
    local instance = table.inherit(archiver, builder)

    -- load the archiver tool from the source file type
    local result, errors = tool.load("ar")
    if not result then 
        return nil, errors
    end
    instance._TOOL = result
 
    -- load the named flags of archiver 
    local namedflags = {}
    local namedflags_exists = {}
    for _, sourcekind in ipairs(sourcekinds) do

        -- load language 
        result, errors = language.load_sk(sourcekind)
        if not result then 
            return nil, errors
        end

        -- merge named flags
        for _, flaginfo in ipairs(table.wrap(result:namedflags()["archiver"])) do
            local key = flaginfo[1] .. flaginfo[2]
            if not namedflags_exists[key] then
                table.insert(namedflags, flaginfo)
                namedflags_exists[key] = flaginfo
            end
        end
    end
    instance._NAMEDFLAGS = namedflags

    -- init flag name
    instance._FLAGNAME = "arflags"

    -- save this instance
    archiver._INSTANCE = instance

    -- ok
    return instance
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

-- return module
return archiver
