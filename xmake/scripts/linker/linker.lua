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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        linker.lua
--

-- define module: linker
local linker = linker or {}

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")
local config    = require("base/config")

-- map gcc flags to the given linker flags
function linker._mapflags(self, flags)

    -- check
    assert(self and flags);

    -- need not map flags? return it directly
    if not self.mapflag then
        return flags
    end

    -- the configure
    local configs = self._CONFIGS
    assert(configs)

    -- map flags
    local flags_mapped = {}
    for _, flag in pairs(flags) do
        -- map it
        local flag_mapped = self._mapflag(configs, flag)
        if flag_mapped then
            table.insert(flags_mapped, flag_mapped)
        end
    end

    -- ok?
    return flags_mapped
end

-- make the command
function linker._make(self, target, objfiles, targetfile)

    -- check
    assert(self and self._make and target)

    -- the configure
    local configs = self._CONFIGS
    assert(configs)

    -- the target kind
    local kind = target.kind or ""

    -- the flag name
    local flag_name = nil
    if kind == "binary" then flag_name = "ldflags"
    elseif kind == "static" then flag_name = "arflags"
    elseif kind == "shared" then flag_name = "shflags"
    else
        -- error
        utils.error("unknown type for linker: %s", kind)
        return 
    end

    -- get the common flags from the current linker 
    local flags_common = configs[flag_name] or ""

    -- get the target flags from the current project
    local flags_target = table.concat(linker._mapflags(self, utils.wrap(target[flag_name])), " ")
    assert(flags_target)

    -- get the linkdirs flags from the current project
    if self._make_linkdir then
        local linkdirs = utils.wrap(target.linkdirs)
        for _, linkdir in ipairs(linkdirs) do
            flags_target = string.format("%s %s", flags_target, self._make_linkdir(configs, linkdir))
        end
    end

    -- get the links flags from the current project
    if self._make_link then
        local links = utils.wrap(target.links)
        for _, link in ipairs(links) do
            flags_target = string.format("%s %s", flags_target, self._make_link(configs, link))
        end
    end

    -- get the config flags
    local flags_config = table.concat(linker._mapflags(self, utils.wrap(config.get(flag_name))), " ")
    assert(flags_config)

    -- make the flags string
    local flags = string.format("%s %s %s", flags_common, flags_target, flags_config)

    -- make it
    return self._make(configs, table.concat(objfiles, " "), targetfile, flags)
end

-- load the given linker 
function linker.load(name)

    -- check
    assert(name and type(name) == "string")

    -- gcc?
    local module = nil
    if name:find("gcc", 1, true) then module = "gcc"
    -- clang?
    elseif name:find("clang", 1, true) then module = "clang"
    -- ar?
    elseif name:find("ar", 1, true) then module = "ar"
    -- cl.exe?
    elseif name:find("link.exe", 1, true) then module = "msvc"
    -- unknown?
    else
        -- error
        utils.error("unknown linker: %s", name)
        return nil
    end

    -- load the given linker 
    local l = require("linker/_" .. module)
    if not l then
        return nil
    end

    -- the linker has been loaded? return it directly
    if l._CONFIGS then 
        return l
    end

    -- make the linker configure
    l._CONFIGS = {}
    local configs = l._CONFIGS

    -- init the linker name
    configs.name = name

    -- init the linker configure
    l._init(configs)

    -- init interfaces
    l["make"] = linker._make

    -- ok?
    return l
end
    
-- return module: linker
return linker
