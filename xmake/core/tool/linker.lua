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

-- get the current flag name
function linker:_flagname()

    -- get it
    return self._FLAGNAME
end

-- add flags from the configure 
function linker:_addflags_from_config(flags)

    -- done
    table.join2(flags, config.get(self:_flagname()))
end

-- add flags from the target 
function linker:_addflags_from_target(flags, target)

    -- add the target flags 
    table.join2(flags, self:_mapflags(target:get(self:_flagname())))

    -- for target options? 
    if target.options then

        -- add the flags for the target options
        for _, opt in ipairs(target:options()) do

            -- add the flags from the option
            table.join2(flags, self:_mapflags(opt:get(self:_flagname())))
        end
    end
end

-- add flags from the platform 
function linker:_addflags_from_platform(flags)

    -- add flags 
    table.join2(flags, platform.get(self:_flagname()))
end

-- add flags from the compiler 
function linker:_addflags_from_compiler(flags, sourcekinds)

    -- done 
    local flags_of_compiler = {}
    for _, sourcekind in ipairs(table.wrap(sourcekinds)) do

        -- load compiler
        local instance, errors = compiler.load(sourcekind)
        if instance then
            table.join2(flags_of_compiler, instance:get(self:_flagname()))
        end
    end

    -- add flags
    table.join2(flags, table.unique(flags_of_compiler))
end

-- add flags from the linker 
function linker:_addflags_from_linker(flags)

    -- done
    table.join2(flags, self:get(self:_flagname()))
end

-- load the linker from the given target kind
function linker.load(targetkind, sourcekinds)

    -- get the linker info
    local linkerinfo, errors = language.linkerinfo_of(targetkind, sourcekinds)
    if not linkerinfo then
        return nil, errors
    end

    -- get it directly from cache dirst
    linker._INSTANCES = linker._INSTANCES or {}
    if linker._INSTANCES[linkerinfo.kind] then
        return linker._INSTANCES[linkerinfo.kind]
    end

    -- new instance
    local instance = table.inherit(linker, builder)

    -- load the linker tool from the source file type
    local result, errors = tool.load(linkerinfo.kind)
    if not result then 
        return nil, errors
    end
    instance._TOOL = result
 
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
        for _, flaginfo in ipairs(table.wrap(result:nameflags()["linker"])) do
            local key = flaginfo[1] .. flaginfo[2]
            if not nameflags_exists[key] then
                table.insert(nameflags, flaginfo)
                nameflags_exists[key] = flaginfo
            end
        end
    end
    instance._NAMEFLAGS = nameflags

    -- init flag name
    instance._FLAGNAME = linkerinfo.flag

    -- save this instance
    linker._INSTANCES[linkerinfo.kind] = instance

    -- ok
    return instance
end

-- link the target file
function linker:link(objectfiles, targetfile, target)

    -- link it
    return sandbox.load(self:_tool().link, table.concat(table.wrap(objectfiles), " "), targetfile, (self:linkflags(target)))
end

-- get the link command
function linker:linkcmd(objectfiles, targetfile, target)

    -- get it
    return self:_tool().linkcmd(table.concat(table.wrap(objectfiles), " "), targetfile, (self:linkflags(target)))
end

-- get the link flags
function linker:linkflags(target)

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
    self:_addflags_from_platform(flags)

    -- add flags from the compiler 
    self:_addflags_from_compiler(flags, target:sourcekinds())

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
