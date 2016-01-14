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
local compiler  = require("base/compiler")
local tools     = require("tools/tools")
local platform  = require("base/platform")

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
        local flag_mapped, count = flag:gsub("^" .. k .. "$", function (w) 
                                                    if type(v) == "function" then
                                                        return v(module, w)
                                                    else
                                                        return v
                                                    end
                                                end)
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


-- add flags from the links
function linker._addflags_from_links(module, flags, links)

    -- check
    assert(module and flags and links)

    -- done
    if module.flag_link then
        for _, link in ipairs(utils.wrap(links)) do
            table.join2(flags, module:flag_link(link))
        end
    end
end

-- add flags from the linker 
function linker._addflags_from_linker(module, flags, flagname)

    -- check
    assert(module and flags and flagname)

    -- done
    table.join2(flags, module[flagname])
end

-- add flags from the compiler 
function linker._addflags_from_compiler(module, flags, flagname, srcfiles)

    -- check
    assert(module and flags and flagname)
    
    -- add the flags for compiler
    local flags_for_compiler = {}
    if srcfiles then
        for _, srcfile in ipairs(utils.wrap(srcfiles)) do

            -- get the compiler 
            local c, errors = compiler.get(srcfile)
            if not c then
                -- error
                utils.error(errors)
                return 
            end

            -- add flags
            table.join2(flags_for_compiler, c[flagname])
        end
    end

    -- done
    table.join2(flags, utils.unique(flags_for_compiler))
end

-- add flags from the configure 
function linker._addflags_from_config(module, flags, flagname)

    -- check
    assert(module and flags and flagname)

    -- done
    table.join2(flags, config.get(flagname))
end

-- add flags from the platform 
function linker._addflags_from_platform(module, flags, flagname)

    -- check
    assert(module and flags and flagname)

    -- add flags
    table.join2(flags, linker._mapflags(module, platform.get(flagname)))

    -- add the linkdirs flags 
    if module.flag_linkdir then
        for _, linkdir in ipairs(utils.wrap(platform.get("linkdirs"))) do
            table.join2(flags, module:flag_linkdir(linkdir))
        end
    end

    -- add the links flags 
    if module.flag_link then
        for _, link in ipairs(utils.wrap(platform.get("links"))) do
            table.join2(flags, module:flag_link(link))
        end
    end
end

-- add flags from the target 
function linker._addflags_from_target(module, flags, flagname, target)

    -- check
    assert(module and flags and flagname and target)

    -- add the target flags from the current project
    table.join2(flags, linker._mapflags(module, target[flagname]))

    -- add the linkdirs flags from the current project
    if module.flag_linkdir then
        for _, linkdir in ipairs(utils.wrap(target.linkdirs)) do
            table.join2(flags, module:flag_linkdir(linkdir))
        end
    end

    -- add the links flags from the current project
    if module.flag_link then
        for _, link in ipairs(utils.wrap(target.links)) do
            table.join2(flags, module:flag_link(link))
        end
    end

    -- the options
    if target.options then
        for _, name in ipairs(utils.wrap(target.options)) do

            -- get option if be enabled
            local opt = nil
            if config.get(name) then opt = config.get("__" .. name) end
            if nil ~= opt then

                -- add the flags from the option
                table.join2(flags, linker._mapflags(module, opt[flagname]))
                
                -- add the linkdirs flags from the option
                if module.flag_linkdir then
                    for _, linkdir in ipairs(utils.wrap(opt.linkdirs)) do
                        table.join2(flags, module:flag_linkdir(linkdir))
                    end
                end

                -- add the links flags from the option
                if module.flag_link then
                    for _, link in ipairs(utils.wrap(opt.links)) do
                        table.join2(flags, module:flag_link(link))
                    end
                end
            end
        end
    end

    -- add the flags from the configure
    table.join2(flags, linker._mapflags(module, config.get(flagname)))

    -- add the strip flags from the current project
    table.join2(flags, linker._getflags(module, target.strip, {     debug       = "-S"
                                                                ,   all         = "-s"
                                                                }))
end

-- add flags from the option 
function linker._addflags_from_option(module, flags, flagname, opt)

    -- check
    assert(module and flags and flagname and opt)

    -- append the option flags
    table.join2(flags, linker._mapflags(module, opt[flagname]))

    -- append the linkdirs flags 
    if opt.linkdirs and module.flag_linkdir then
        for _, linkdir in ipairs(utils.wrap(opt.linkdirs)) do
            table.join2(flags, module:flag_linkdir(linkdir))
        end
    end
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
function linker.make(module, target, srcfiles, objfiles, targetfile, logfile)

    -- check
    assert(module and target)

    -- the target kind
    local kind = target.kind or ""

    -- the flag name
    local flagname = nil
    if kind == "binary" then flagname = "ldflags"
    elseif kind == "static" then flagname = "arflags"
    elseif kind == "shared" then flagname = "shflags"
    else
        -- error
        utils.error("unknown type for linker: %s", kind)
        return 
    end

    -- init flags
    local flags = {}

    -- add flags from the configure
    linker._addflags_from_config(module, flags, flagname)

    -- add flags from the target 
    linker._addflags_from_target(module, flags, flagname, target)

    -- add flags from the platform
    linker._addflags_from_platform(module, flags, flagname)

    -- add flags from the compiler 
    linker._addflags_from_compiler(module, flags, flagname, srcfiles)

    -- add flags from the linker 
    linker._addflags_from_linker(module, flags, flagname)

    -- remove repeat
    flags = utils.unique(flags)

    -- make the link command
    return module:command_link(table.concat(objfiles, " "), targetfile, table.concat(flags, " "):trim(), logfile)
end

-- check link for the project option
function linker.check_links(opt, links, sourcefile, objectfile, targetfile)

    -- check
    assert(opt and links and objectfile and targetfile)

    -- get the linker
    local module = linker.get("binary")
    assert(module and module.flag_link)

    -- init flags
    local flags = {}

    -- add flags from the configure
    linker._addflags_from_config(module, flags, "ldflags")

    -- add flags from the option
    linker._addflags_from_option(module, flags, "ldflags", opt)

    -- add flags from the platform
    linker._addflags_from_platform(module, flags, "ldflags")

    -- add flags from the links
    linker._addflags_from_links(module, flags, links)

    -- add flags from the compiler 
    linker._addflags_from_compiler(module, flags, "ldflags", sourcefile)

    -- add flags from the linker 
    linker._addflags_from_linker(module, flags, "ldflags")

    -- remove repeat
    flags = utils.unique(flags)

    -- execute the link command
    return module:main(module:command_link(objectfile, targetfile, table.concat(flags, " "):trim(), utils.ifelse(xmake._OPTIONS.verbose, nil, xmake._NULDEV)))
end

-- return module: linker
return linker
