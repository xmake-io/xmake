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

-- add flags from the archiver 
function archiver:_addflags_from_archiver(flags)

    -- add flags
    for _, flagkind in ipairs(self:_flagkinds()) do
        table.join2(flags, self:get(flagkind))
    end
end

-- load the archiver 
function archiver.load(sourcekinds)

    -- load linker
    return builder.load_linker(archiver, "archiver", "static", sourcekinds)
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
