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

    -- add the linkdirs flags 
    for _, linkdir in ipairs(table.wrap(config.get("linkdirs"))) do
        table.join2(flags, self:linkdir(linkdir))
    end
end

-- add flags from the target 
function linker:_addflags_from_target(flags, target)

    -- add the target flags 
    table.join2(flags, self:_mapflags(target:get(self:_flagname())))

    -- add the linkdirs flags 
    for _, linkdir in ipairs(table.wrap(target:get("linkdirs"))) do
        table.join2(flags, self:linkdir(linkdir))
    end

    -- for target options? 
    if target.options then

        -- add the flags for the target options
        for _, opt in ipairs(target:options()) do

            -- add the flags from the option
            table.join2(flags, self:_mapflags(opt:get(self:_flagname())))
            
            -- add the linkdirs flags from the option
            for _, linkdir in ipairs(table.wrap(opt:get("linkdirs"))) do
                table.join2(flags, self:linkdir(linkdir))
            end
        end
    end

    -- add the strip flags 
    for _, strip in ipairs(table.wrap(target:get("strip"))) do
        table.join2(flags, self:strip(strip))
    end

    -- add the symbol flags 
    if target.symbolfile then
        local symbolfile = target:symbolfile()
        for _, symbol in ipairs(table.wrap(target:get("symbols"))) do
            table.join2(flags, self:symbol(symbol, symbolfile))
        end
    end
end

-- add flags from the platform 
function linker:_addflags_from_platform(flags)

    -- add flags 
    table.join2(flags, platform.get(self:_flagname()))

    -- add the linkdirs flags 
    for _, linkdir in ipairs(table.wrap(platform.get("linkdirs"))) do
        table.join2(flags, self:linkdir(linkdir))
    end
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

-- add links from the configure 
function linker:_addlinks_from_config(flags)

    -- add the links flags 
    for _, link in ipairs(table.wrap(config.get("links"))) do
        table.join2(flags, self:linklib(link))
    end
end

-- add links from the target 
function linker:_addlinks_from_target(flags, target)

    -- add the links flags 
    for _, link in ipairs(table.wrap(target:get("links"))) do
        table.join2(flags, self:linklib(link))
    end

    -- for target options? 
    if target.options then

        -- add the flags for the target options
        for _, opt in ipairs(target:options()) do

            -- add the links flags from the option
            for _, link in ipairs(table.wrap(opt:get("links"))) do
                table.join2(flags, self:linklib(link))
            end
        end
    end
end

-- add links from the platform 
function linker:_addlinks_from_platform(flags)

    -- add the links flags
    for _, link in ipairs(table.wrap(platform.get("links"))) do
        table.join2(flags, self:linklib(link))
    end
end

-- load the linker from the given target kind
function linker.load(targetkind, sourcekinds)

    -- get the linker kind
    local linkerkind, errors = language.linkerkind_of(targetkind, sourcekinds)
    if not linkerkind then
        return nil, errors
    end

    -- get it directly from cache dirst
    linker._INSTANCES = linker._INSTANCES or {}
    if linker._INSTANCES[linkerkind] then
        return linker._INSTANCES[linkerkind]
    end

    -- new instance
    local instance = table.inherit(linker, builder)

    -- load the linker tool from the source file type
    local result, errors = tool.load(linkerkind)
    if not result then 
        return nil, errors
    end
    instance._TOOL = result

    -- save flagname
    local flagname =
    {
        ld = "ldflags"
    ,   sh = "shflags"
    ,   go = "goflags"
    }
    instance._FLAGNAME = flagname[linkerkind]

    -- check
    if not instance._FLAGNAME then
        return nil, string.format("unknown linker for kind: %s", linkerkind)
    end

    -- save this instance
    linker._INSTANCES[linkerkind] = instance

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

    -- add flags from the platform 
    self:_addflags_from_platform(flags)

    -- add flags from the compiler 
    self:_addflags_from_compiler(flags, target:sourcekinds())

    -- add flags from the linker 
    self:_addflags_from_linker(flags)

    -- add links from the target 
    self:_addlinks_from_target(flags, target)

    -- add flags from the platform 
    self:_addlinks_from_platform(flags)

    -- add links from the configure 
    self:_addlinks_from_config(flags)

    -- remove repeat
    flags = table.unique(flags)

    -- merge flags
    local flags_str = table.concat(flags, " "):trim()

    -- save flags
    self._FLAGS[key] = {flags_str, flags}

    -- get it
    return flags_str, flags
end

-- make the strip flag
function linker:strip(level)

    -- make it
    return self:_tool().strip(level)
end

-- make the symbol flag
function linker:symbol(level, symbolfile)

    -- make it
    return self:_tool().symbol(level, symbolfile)
end

-- make the linklib flag
function linker:linklib(lib)

    -- make it
    return self:_tool().linklib(lib)
end

-- make the linkdir flag
function linker:linkdir(dir)

    -- make it
    return self:_tool().linkdir(dir)
end

-- return module
return linker
