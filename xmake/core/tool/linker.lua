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
local platform  = require("platform/platform")
local tool      = require("tool/tool")
local compiler  = require("tool/compiler")

-- get the current tool
function linker:_tool()

    -- get it
    return self._TOOL
end

-- get the current flag name
function linker:_flagname()

    -- get it
    return self._FLAGNAME
end

-- get the link kind of the target kind
function linker._kind_of_target(targetkind, sourcekinds)

    -- link the target of golang objects
    if sourcekinds then
        for _, sourcekind in ipairs(sourcekinds) do
            if sourcekind == "go" then
                return "go"
            end
        end
    end

    -- the kinds
    local kinds = 
    {
        ["binary"] = "ld"
    ,   ["shared"] = "sh"
    }

    -- get kind
    return kinds[targetkind]
end

-- map gcc flag to the given linker flag
function linker:_mapflag(flag, mapflags)

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

-- map gcc flags to the given linker flags
function linker:_mapflags(flags)

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
function linker:_addflags_from_compiler(flags, srckinds)

    -- done 
    local flags_of_compiler = {}
    for _, srckind in ipairs(table.wrap(srckinds)) do

        -- load compiler
        local instance, errors = compiler.load(srckind)
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

-- get the current kind
function linker:kind()

    -- get it
    return self._KIND
end

-- load the linker from the given target kind
function linker.load(targetkind, sourcekinds)

    -- get the linker kind
    local kind = linker._kind_of_target(targetkind, sourcekinds)
    if not kind then
        return nil, string.format("unknown target kind: %s", targetkind)
    end

    -- get it directly from cache dirst
    linker._INSTANCES = linker._INSTANCES or {}
    if linker._INSTANCES[kind] then
        return linker._INSTANCES[kind]
    end

    -- new instance
    local instance = table.inherit(linker)

    -- load the linker tool from the source file type
    local result, errors = tool.load(kind)
    if not result then 
        return nil, errors
    end
        
    -- save tool
    instance._TOOL = result

    -- save kind 
    instance._KIND = kind 

    -- save flagname
    local flagname =
    {
        ld = "ldflags"
    ,   sh = "shflags"
    ,   go = "goflags"
    }
    instance._FLAGNAME = flagname[kind]

    -- check
    if not instance._FLAGNAME then
        return nil, string.format("unknown linker for kind: %s", kind)
    end

    -- save this instance
    linker._INSTANCES[kind] = instance

    -- ok
    return instance
end

-- get properties of the tool
function linker:get(name)

    -- get it
    return self:_tool().get(name)
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

-- check the given flags 
function linker:check(flags)

    -- the linker tool
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
return linker
