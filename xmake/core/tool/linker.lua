--!The Make-like Build Utility based on Lua
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
function linker._kind_of_target(targetkind)

    -- the kinds
    local kinds = 
    {
        ["binary"] = "ld"
    ,   ["shared"] = "sh"
    }

    -- get kind
    return kinds[targetkind]
end

-- get the flags
function linker:_flags(target)

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

    -- add flags from the compiler 
    self:_addflags_from_compiler(flags, target:sourcekinds())

    -- add flags from the linker 
    self:_addflags_from_linker(flags)

    -- remove repeat
    flags = table.unique(flags)

    -- merge flags
    flags = table.concat(flags, " "):trim()

    -- save flags
    self._FLAGS[key] = flags

    -- get it
    return flags
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
end

-- add flags from the target 
function linker:_addflags_from_target(flags, target)

    -- add the target flags 
    table.join2(flags, self:_mapflags(target:get(self:_flagname())))

    -- add the linkdirs flags 
    for _, linkdir in ipairs(table.wrap(target:get("linkdirs"))) do
        table.join2(flags, self:linkdir(linkdir))
    end

    -- add the links flags 
    for _, link in ipairs(table.wrap(target:get("links"))) do
        table.join2(flags, self:linklib(link))
    end

    -- for target options? 
    if target.options then

        -- add the flags for the target options
        for _, opt in pairs(target:options()) do

            -- add the flags from the option
            table.join2(flags, self:_mapflags(opt:get(self:_flagname())))
            
            -- add the linkdirs flags from the option
            for _, linkdir in ipairs(table.wrap(opt:get("linkdirs"))) do
                table.join2(flags, self:linkdir(linkdir))
            end

            -- add the links flags from the option
            for _, link in ipairs(table.wrap(opt:get("links"))) do
                table.join2(flags, self:linklib(link))
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

    -- add the links flags
    for _, link in ipairs(table.wrap(platform.get("links"))) do
        table.join2(flags, self:linklib(link))
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

-- get the current kind
function linker:kind()

    -- get it
    return self._KIND
end

-- load the linker from the given target kind
function linker.load(targetkind)

    -- get the linker kind
    local kind = linker._kind_of_target(targetkind)
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

    -- get flags
    local flags = nil
    if target then
        flags = self:_flags(target)
    end

    -- link it
    return sandbox.load(self:_tool().link, table.concat(table.wrap(objectfiles), " "), targetfile, flags or "")
end

-- get the link command
function linker:linkcmd(objectfiles, targetfile, target)

    -- get flags
    local flags = nil
    if target then
        flags = self:_flags(target)
    end

    -- get it
    return self:_tool().linkcmd(table.concat(table.wrap(objectfiles), " "), targetfile, flags or "")
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
