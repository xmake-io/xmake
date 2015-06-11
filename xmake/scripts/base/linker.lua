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
local table     = require("base/table")
local string    = require("base/string")
local config    = require("base/config")
local tools     = require("tools/tools")

-- map gcc flag to the given linker flag
function linker._mapflag(module, flag)

    -- check
    assert(module.mapflags and flag)

    -- attempt to map it directly
    local flag_mapped = module.mapflags[flag]
    if flag_mapped and type(flag_mapped) == "string" then
        return flag_mapped
    end

    -- find and replace it using pattern
    for k, v in pairs(module.mapflags) do
        local flag_mapped, count = flag:gsub(k, v)
        if flag_mapped and count ~= 0 then
            return utils.ifelse(#flag_mapped ~= 0, flag_mapped, nil) 
        end
    end

    -- return it directly
    return flag
end

-- map gcc flags to the given linker flags
function linker._mapflags(module, flags)

    -- check
    assert(module)

    -- wrap flags first
    flags = utils.wrap(flags)

    -- need not map flags? return it directly
    if not module.mapflags then
        return flags
    end

    -- map flags
    local flags_mapped = {}
    for _, flag in pairs(flags) do
        -- map it
        local flag_mapped = linker._mapflag(module, flag)
        if flag_mapped then
            table.insert(flags_mapped, flag_mapped)
        end
    end

    -- ok?
    return flags_mapped
end

-- get the linker flags from names
function linker._getflags(module, names, flags)

    -- check
    assert(flags)

    -- the mapped flags
    local flags_mapped = {}

    -- wrap it first
    names = utils.wrap(names)
    for _, name in ipairs(names) do
        table.join2(flags_mapped, linker._mapflags(module, flags[name]))
    end

    -- get it
    return flags_mapped
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

    -- append the common flags from the current linker 
    local flags = {}
    table.join2(flags, module[flag_name])

    -- append the target flags from the current project
    table.join2(flags, linker._mapflags(module, target[flag_name]))

    -- append the linkdirs flags from the current project
    if module.flag_linkdir then
        local linkdirs = utils.wrap(target.linkdirs)
        for _, linkdir in ipairs(linkdirs) do
            table.join2(flags, module.flag_linkdir(linkdir))
        end
    end

    -- append the links flags from the current project
    if module.flag_link then
        local links = utils.wrap(target.links)
        for _, link in ipairs(links) do
            table.join2(flags, module.flag_link(link))
        end
    end

    -- append the flags from the configure
    table.join2(flags, linker._mapflags(module, config.get(flag_name)))

    -- append the strip flags from the current project
    table.join2(flags, linker._getflags(module, target.strip, {     debug       = "-S"
                                                                ,   all         = "-s"
                                                                }))

    -- make the link command
    return module.command_link(table.concat(objfiles, " "), targetfile, table.concat(flags, " "):trim())
end

-- check link for the project option
function linker.check_links(opt, links, objectfile, targetfile)

    -- check
    assert(opt and links and objectfile and targetfile)

    -- get the linker
    local l = linker.get("binary")
    assert(l and l.flag_link)

    -- append the common flags 
    local flags = {}
    table.join2(flags, l.ldflags)

    -- append the option flags
    table.join2(flags, linker._mapflags(l, opt.ldflags))

    -- append the linkdirs flags 
    if opt.linkdirs and l.flag_linkdir then
        for _, linkdir in ipairs(utils.wrap(opt.linkdirs)) do
            table.join2(flags, l.flag_linkdir(linkdir))
        end
    end

    -- append the links flags
    for _, link in ipairs(utils.wrap(links)) do
        table.join2(flags, l.flag_link(link))
    end

    -- make the compile command
    local cmd = string.format("%s > %s 2>&1", l.command_link(objectfile, targetfile, table.concat(flags, " "):trim()), xmake._NULDEV)
    if not cmd then return end

    -- execute the link command
    return l.main(cmd)
end

-- return module: linker
return linker
