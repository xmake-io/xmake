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
local tools     = require("tools/tools")

-- map gcc flags to the given linker flags
function linker._mapflags(module, flags)

    -- check
    assert(module and flags);

    -- need not map flags? return it directly
    if not module.mapflag then
        return flags
    end

    -- map flags
    local flags_mapped = {}
    for _, flag in pairs(flags) do
        -- map it
        local flag_mapped = module.flag_map(flag)
        if flag_mapped then
            table.insert(flags_mapped, flag_mapped)
        end
    end

    -- ok?
    return flags_mapped
end

-- make the link command
function linker.make(module, target, objfiles, targetfile)

    -- check
    assert(module and target)

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
    local flags_common = module[flag_name] or ""

    -- get the target flags from the current project
    local flags_target = table.concat(linker._mapflags(module, utils.wrap(target[flag_name])), " ")
    assert(flags_target)

    -- get the linkdirs flags from the current project
    if module._make_linkdir then
        local linkdirs = utils.wrap(target.linkdirs)
        for _, linkdir in ipairs(linkdirs) do
            flags_target = flags_target:append(module.flag_linkdir(linkdir), " ")
        end
    end

    -- get the links flags from the current project
    if module._make_link then
        local links = utils.wrap(target.links)
        for _, link in ipairs(links) do
            flags_target = flags_target:append(module.flag_link(link), " ")
        end
    end

    -- get the config flags
    local flags_config = table.concat(linker._mapflags(module, utils.wrap(config.get(flag_name))), " ")
    assert(flags_config)

    -- make the flags string
    local flags = ""
    flags = flags:append(flags_common, " ")
    flags = flags:append(flags_target, " ")
    flags = flags:append(flags_config, " ")
    flags = flags:trim()

    -- make the link command
    return module.command_link(table.concat(objfiles, " "), targetfile, flags)
end

-- get the linker from the given kind
function linker.get(kind)

    -- check
    assert(kind)

    -- get the linker name from the kind
    local name = nil
    if kind == "binary" then name = "ld"
    elseif kind == "static" then name = "ar"
    elseif kind == "shared" then name = "sh"
    else return end
 
    -- get it
    local module = tools.get(name)

    -- invalid linker?
    if module and not module.command_link then
        return 
    end

    -- ok?
    return module
end

-- return module: linker
return linker
