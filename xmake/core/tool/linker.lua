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
-- @file        linker.lua
--

-- define module
local linker = linker or {}

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
local compiler  = require("tool/compiler")

-- add flags from the platform 
function linker:_addflags_from_platform(flags, targetkind)

    -- add flags 
    local toolkind = self:kind()
    for _, flagkind in ipairs(self:_flagkinds()) do

        -- attempt to add special lanugage flags first, .e.g gc-ldflags, dc-arflags
        table.join2(flags, platform.get(toolkind .. 'flags') or platform.get(flagkind))

        -- attempt to add special lanugage flags first for target kind, .e.g gc-ldflags, dc-arflags
        local targetflags = platform.get(targetkind) or {}
        table.join2(flags, targetflags[toolkind .. 'flags'] or targetflags[flagkind])
    end
end

-- add flags from the compiler 
function linker:_addflags_from_compiler(flags, targetkind, sourcekinds)

    -- make flags 
    local flags_of_compiler = {}
    local toolkind = self:kind()
    for _, sourcekind in ipairs(table.wrap(sourcekinds)) do

        -- load compiler
        local instance, errors = compiler.load(sourcekind)
        if instance then
            for _, flagkind in ipairs(self:_flagkinds()) do

                -- attempt to add special lanugage flags first, .e.g gc-ldflags, dc-arflags
                table.join2(flags_of_compiler, instance:get(toolkind .. 'flags') or instance:get(flagkind))

                -- attempt to add special lanugage flags first for target kind, .e.g gc-ldflags, dc-arflags
                local targetflags = instance:get(targetkind) or {}
                table.join2(flags_of_compiler, targetflags[toolkind .. 'flags'] or targetflags[flagkind])
            end
        end
    end

    -- add flags
    table.join2(flags, table.unique(flags_of_compiler))
end

-- add flags from the linker 
function linker:_addflags_from_linker(flags)

    -- add flags
    local toolkind = self:kind()
    for _, flagkind in ipairs(self:_flagkinds()) do

        -- attempt to add special lanugage flags first, .e.g gc-ldflags, dc-arflags
        table.join2(flags, self:get(toolkind .. 'flags') or self:get(flagkind))
    end
end

-- load the linker from the given target kind
function linker.load(targetkind, sourcekinds)

    -- check
    assert(sourcekinds)

    -- wrap sourcekinds first
    sourcekinds = table.wrap(sourcekinds)

    -- get the linker infos
    local linkerinfos, errors = language.linkerinfos_of(targetkind, sourcekinds)
    if not linkerinfos then
        return nil, errors
    end

    -- select the linker
    local linkerinfo = nil
    local linkertool = nil
    for _, _linkerinfo in ipairs(linkerinfos) do
        -- load the linker tool from the linker kind
        linkertool, errors = tool.load(_linkerinfo.linkerkind)
        if linkertool then 
            linkerinfo = _linkerinfo
            break
        end
    end
    if not linkerinfo then
        return nil, errors
    end

    -- get it directly from cache dirst
    builder._INSTANCES = builder._INSTANCES or {}
    if builder._INSTANCES[linkerinfo.linkerkind] then
        return builder._INSTANCES[linkerinfo.linkerkind]
    end

    -- new instance
    local instance = table.inherit(linker, builder)

    -- save linker tool
    instance._TOOL = linkertool
 
    -- load the name flags of archiver 
    local nameflags = {}
    local nameflags_exists = {}
    for _, sourcekind in ipairs(sourcekinds) do

        -- load language 
        result, errors = language.load_sk(sourcekind)
        if not result then 
            return nil, errors
        end

        -- merge name flags
        for _, flaginfo in ipairs(table.wrap(result:nameflags()[targetkind])) do
            local key = flaginfo[1] .. flaginfo[2]
            if not nameflags_exists[key] then
                table.insert(nameflags, flaginfo)
                nameflags_exists[key] = flaginfo
            end
        end
    end
    instance._NAMEFLAGS = nameflags

    -- init target kind
    instance._TARGETKIND = targetkind

    -- init flag kinds
    instance._FLAGKINDS = {linkerinfo.linkerflag}

    -- save this instance
    builder._INSTANCES[linkerinfo.linkerkind] = instance

    -- ok
    return instance
end

-- link the target file
function linker:link(objectfiles, targetfile, opt)
    return sandbox.load(self:_tool().link, self:_tool(), table.concat(table.wrap(objectfiles), " "), self:_targetkind(), targetfile, (self:linkflags(opt)))
end

-- get the link command
function linker:linkcmd(objectfiles, targetfile, opt)
    return self:_tool():linkcmd(table.concat(table.wrap(objectfiles), " "), self:_targetkind(), targetfile, (self:linkflags(opt)))
end

-- get the link flags
function linker:linkflags(opt)

    -- init options
    opt = opt or {}

    -- get target
    local target = opt.target

    -- no target?
    if not target then
        return "", {}
    end

    -- get the target key
    local key = tostring(target)

    -- get it directly from cache dirst
    self._FLAGS = self._FLAGS or {}
    local flags_cached = self._FLAGS[key]
    if flags_cached then
        return flags_cached[1], flags_cached[2]
    end

    -- add flags from the configure 
    local flags = {}
    self:_addflags_from_config(flags)

    -- add flags from the target 
    self:_addflags_from_target(flags, target)

    -- add flags (named) from language
    self:_addflags_from_language(flags, target)

    -- add flags from the platform 
    self:_addflags_from_platform(flags, target:get("kind"))

    -- add flags from the compiler 
    self:_addflags_from_compiler(flags, target:get("kind"), target:sourcekinds())

    -- add flags from the linker 
    self:_addflags_from_linker(flags)

    -- remove repeat
    flags = table.unique(flags)

    -- merge flags
    local flags_str = table.concat(flags, " "):trim()

    -- save flags
    self._FLAGS[key] = {flags_str, flags}

    -- get it
    return flags_str, flags
end

-- return module
return linker
