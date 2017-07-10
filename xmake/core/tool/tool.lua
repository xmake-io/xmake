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
-- See the License for the specific tool governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        tool.lua
--

-- define module
local tool      = tool or {}
local _instance = _instance or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local table         = require("base/table")
local string        = require("base/string")
local sandbox       = require("sandbox/sandbox")
local platform      = require("platform/platform")
local import        = require("sandbox/modules/import")

-- new an instance
function _instance.new(kind, name, program)

    -- import "core.tools.xxx"
    local toolclass = nil
    if os.isfile(path.join(os.programdir(), "modules", "core", "tools", name .. ".lua")) then
        toolclass = import("core.tools." .. name)
    end

    -- not found?
    if not toolclass then
        return nil, string.format("cannot import \"core.tool.%s\" module!", name)
    end

    -- new an instance
    local instance = table.inherit(_instance, toolclass)

    -- save name, kind and program
    instance._NAME    = name
    instance._KIND    = kind
    instance._PROGRAM = program

    -- init instance
    if instance.init then
        local ok, errors = sandbox.load(instance.init, instance)
        if not ok then
            return nil, errors
        end
    end

    -- ok
    return instance
end

-- get the tool name
function _instance:name()
    return self._NAME
end

-- get the tool kind
function _instance:kind()
    return self._KIND
end

-- get the tool program
function _instance:program()
    return self._PROGRAM
end

-- has the given flag?
function _instance:has_flags(flag)

    -- import has_flags()
    self._has_flags = self._has_flags or import("lib.detect.has_flags")

    -- has flags?
    return self._has_flags(self:name(), flag, {program = self:program(), toolkind = self:kind()})
end

-- load the given tool from the given kind
--
-- the kinds:
-- 
-- .e.g cc, cxx, mm, mxx, as, ar, ld, sh, ..
--
function tool.load(kind)

    -- get it directly from cache dirst
    tool._TOOLS = tool._TOOLS or {}
    if tool._TOOLS[kind] then
        return tool._TOOLS[kind]
    end

    -- get the tool program
    local program = platform.tool(kind)
    if not program then
        return nil, string.format("cannot get tool for %s", kind)
    end

    -- import find_toolname()
    tool._find_toolname = tool._find_toolname or import("lib.detect.find_toolname")

    -- get the tool name from the program
    local ok, name_or_errors = sandbox.load(tool._find_toolname, program)
    if not ok then
        return nil, name_or_errors
    end

    -- get name
    local name = name_or_errors
    if not name then
        return nil, string.format("cannot find tool name for %s", program)
    end

    -- new an instance
    local instance, errors = _instance.new(kind, name, program)
    if not instance then
        return nil, errors
    end

    -- save instance to the cache
    tool._TOOLS[kind] = instance

    -- ok
    return instance
end

-- return module
return tool
