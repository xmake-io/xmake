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
-- See the License for the specific tool governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
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
local config        = require("project/config")
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
    instance._INFO    = {}

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

-- set the value to the platform info
function _instance:set(name, ...)
    self._INFO[name] = table.unwrap({...})
end

-- add the value to the platform info
function _instance:add(name, ...)
    local info = table.wrap(self._INFO[name])
    self._INFO[name] = table.unwrap(table.join(info, ...))
end

-- get the platform configure
function _instance:get(name)
    if self._super_get then
        local value = self:_super_get(name)
        if value ~= nil then
            return value
        end
    end
    return self._INFO[name]
end

-- has the given flag?
function _instance:has_flags(flags, flagkind, opt)

    -- init options
    opt = opt or {}
    opt.program = opt.program or self:program()
    opt.toolkind = opt.toolkind or self:kind()
    opt.flagkind = opt.flagkind or flagkind

    -- get system flags
    opt.sysflags = opt.sysflags or self:get(self:kind() .. 'flags')
    if not opt.sysflags and flagkind then
        opt.sysflags = self:get(flagkind)
    end

    -- import has_flags()
    self._has_flags = self._has_flags or import("lib.detect.has_flags", {anonymous = true})

    -- has flags?
    return self._has_flags(self:name(), flags, opt)
end

-- load the given tool from the given kind
--
-- @param kind      the tool kind e.g. cc, cxx, mm, mxx, as, ar, ld, sh, ..
-- @param program   the tool program, e.g. /xxx/arm-linux-gcc, gcc@mipscc.exe
--
function tool.load(kind, program)

    -- init key
    local key = kind .. (program or "") .. (config.get("arch") or os.arch())

    -- get it directly from cache dirst
    tool._TOOLS = tool._TOOLS or {}
    if tool._TOOLS[key] then
        return tool._TOOLS[key]
    end

    -- contain toolname? parse it, e.g. 'gcc@xxxx.exe'
    local toolname = nil
    if program then
        local pos = program:find('@', 1, true)
        if pos then
            toolname = program:sub(1, pos - 1)
            program = program:sub(pos + 1)
        end
    end

    -- get the tool program and name
    if not program then
        program, toolname = platform.tool(kind)
    end
    if not program then
        return nil, string.format("cannot get program for %s", kind)
    end

    -- import find_toolname()
    tool._find_toolname = tool._find_toolname or import("lib.detect.find_toolname")

    -- get the tool name from the program
    local ok, name_or_errors = sandbox.load(tool._find_toolname, toolname or program, {program = program})
    if not ok then
        return nil, name_or_errors
    end

    -- get name
    local name = name_or_errors
    if not name then
        return nil, string.format("cannot find known tool script for %s", toolname or program)
    end

    -- new an instance
    local instance, errors = _instance.new(kind, name, program)
    if not instance then
        return nil, errors
    end

    -- save instance to the cache
    tool._TOOLS[key] = instance

    -- ok
    return instance
end

-- return module
return tool
