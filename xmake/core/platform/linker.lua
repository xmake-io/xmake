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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        linker.lua
--

-- define module
local linker = linker or {}

-- load modules
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local option    = require("base/option")
local config    = require("project/config")
local compiler  = require("platform/compiler")
local tool      = require("platform/tool")
local platform  = require("platform/platform")

-- map gcc flag to the given linker flag
function linker._mapflag(self, flag)

    -- check
    assert(self.mapflags and flag)

    -- attempt to map it directly
    local flag_mapped = self.mapflags[flag]
    if flag_mapped and type(flag_mapped) == "string" then
        return flag_mapped
    end

    -- find and replace it using pattern
    for k, v in pairs(self.mapflags) do
        local flag_mapped, count = flag:gsub("^" .. k .. "$", function (w) 
                                                    if type(v) == "function" then
                                                        return v(self, w)
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
function linker._mapflags(self, flags)

    -- check
    assert(self)

    -- wrap flags first
    flags = table.wrap(flags)

    -- need not map flags? return it directly
    if not self.mapflags then
        return flags
    end

    -- map flags
    local flags_mapped = {}
    for _, flag in pairs(flags) do
        -- map it
        local flag_mapped = linker._mapflag(self, flag)
        if flag_mapped then
            table.insert(flags_mapped, flag_mapped)
        end
    end

    -- ok?
    return flags_mapped
end

-- get the linker flags from names
function linker._getflags(self, names, flags)

    -- check
    assert(flags)

    -- the mapped flags
    local flags_mapped = {}

    -- wrap it first
    names = table.wrap(names)
    for _, name in ipairs(names) do
        table.join2(flags_mapped, linker._mapflags(self, flags[name]))
    end

    -- get it
    return flags_mapped
end


-- add flags from the links
function linker._addflags_from_links(self, flags, links)

    -- check
    assert(self and flags and links)

    -- done
    if self.flag_link then
        for _, link in ipairs(table.wrap(links)) do
            table.join2(flags, self:flag_link(link))
        end
    end
end

-- add flags from the linker 
function linker._addflags_from_linker(self, flags, flagname)

    -- check
    assert(self and flags and flagname)

    -- done
    table.join2(flags, self[flagname])
end

-- add flags from the compiler 
function linker._addflags_from_compiler(self, flags, flagname, srcfiles)

    -- check
    assert(self and flags and flagname)
    
    -- add the flags for compiler
    local flags_for_compiler = {}
    if srcfiles then
        for _, srcfile in ipairs(table.wrap(srcfiles)) do

            -- init a compiler instance
            local c, errors = compiler.init(srcfile)
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
    table.join2(flags, table.unique(flags_for_compiler))
end

-- add flags from the configure 
function linker._addflags_from_config(self, flags, flagname)

    -- check
    assert(self and flags and flagname)

    -- done
    table.join2(flags, config.get(flagname))
end

-- add flags from the platform 
function linker._addflags_from_platform(self, flags, flagname)

    -- check
    assert(self and flags and flagname)

    -- add flags
    table.join2(flags, linker._mapflags(self, platform.get(flagname)))

    -- add the linkdirs flags 
    if self.flag_linkdir then
        for _, linkdir in ipairs(table.wrap(platform.get("linkdirs"))) do
            table.join2(flags, self:flag_linkdir(linkdir))
        end
    end

    -- add the links flags 
    if self.flag_link then
        for _, link in ipairs(table.wrap(platform.get("links"))) do
            table.join2(flags, self:flag_link(link))
        end
    end
end

-- add flags from the target 
function linker._addflags_from_target(self, flags, flagname, target)

    -- check
    assert(self and flags and flagname and target)

    -- add the target flags from the current project
    table.join2(flags, linker._mapflags(self, target[flagname]))

    -- add the linkdirs flags from the current project
    if self.flag_linkdir then
        for _, linkdir in ipairs(table.wrap(target:get("linkdirs"))) do
            table.join2(flags, self:flag_linkdir(linkdir))
        end
    end

    -- add the links flags from the current project
    if self.flag_link then
        for _, link in ipairs(table.wrap(target:get("links"))) do
            table.join2(flags, self:flag_link(link))
        end
    end

    -- the options
    for _, name in ipairs(table.wrap(target:get("options"))) do

        -- get option if be enabled
        local opt = nil
        if config.get(name) then opt = config.get("__" .. name) end
        if nil ~= opt then

            -- add the flags from the option
            table.join2(flags, linker._mapflags(self, opt[flagname]))
            
            -- add the linkdirs flags from the option
            if self.flag_linkdir then
                for _, linkdir in ipairs(table.wrap(opt.linkdirs)) do
                    table.join2(flags, self:flag_linkdir(linkdir))
                end
            end

            -- add the links flags from the option
            if self.flag_link then
                for _, link in ipairs(table.wrap(opt.links)) do
                    table.join2(flags, self:flag_link(link))
                end
            end
        end
    end

    -- add the flags from the configure
    table.join2(flags, linker._mapflags(self, config.get(flagname)))

    -- add the strip flags from the current project
    table.join2(flags, linker._getflags(self, target:get("strip"), {  debug       = "-S"
                                                                    ,   all         = "-s"
                                                                    }))
end

-- add flags from the option 
function linker._addflags_from_option(self, flags, flagname, opt)

    -- check
    assert(self and flags and flagname and opt)

    -- append the option flags
    table.join2(flags, linker._mapflags(self, opt:get("flagname")))

    -- append the linkdirs flags 
    if opt.linkdirs and self.flag_linkdir then
        for _, linkdir in ipairs(table.wrap(opt:get("linkdirs"))) do
            table.join2(flags, self:flag_linkdir(linkdir))
        end
    end
end

-- init a linker instance from the given kind
function linker.init(kind)

    -- check
    assert(kind)

    -- get the linker name from the kind
    local name = nil
    if kind == "binary" then name = "ld"
    elseif kind == "static" then name = "ar"
    elseif kind == "shared" then name = "sh"
    else 
        return nil, string.format("unknown kind: %s for linker", kind)
    end

    -- init instance
    local instance = table.inherit(linker)
 
    -- get the linker tool
    instance._TOOL, errors = tool.get(name)
    if not instance._TOOL then
        return nil, errors   
    end

    -- ok?
    return instance
end

-- get flags from the given flag name
function linker.flags(self, flagname, target)

    -- init flags
    local flags = {}

    -- add flags from the configure
    self:_addflags_from_config(flags, flagname)

    -- add flags from the target 
    self:_addflags_from_target(flags, flagname, target)

    -- add flags from the platform
    self:_addflags_from_platform(flags, flagname)

    -- add flags from the compiler 
    self:_addflags_from_compiler(flags, flagname, target:sourcefiles())

    -- add flags from the linker 
    self:_addflags_from_linker(flags, flagname)

    -- remove repeat
    flags = table.unique(flags)

    -- ok?
    return flags
end

-- make the link command
function linker.makecmd(self, target, objfiles, targetfile, logfile)

    -- check
    assert(self and self._TOOL and target)

    -- the target kind
    local kind = target:get("kind") or ""

    -- the flag name
    local flagname = nil
    if kind == "binary" then flagname = "ldflags"
    elseif kind == "static" then flagname = "arflags"
    elseif kind == "shared" then flagname = "shflags"
    else
        -- error
        os.raise("unknown type for linker: %s", kind)
    end

    -- get flags
    local flags = self:flags(flagname, target)

    -- make the link command
    return self._TOOL:command_link(table.concat(objfiles, " "), targetfile, table.concat(flags, " "):trim(), logfile)
end

-- check link for the project option
function linker.check_links(opt,  sourcefile, objectfile, targetfile)

    -- check
    assert(opt and objectfile and targetfile)

    -- init the linker
    local self = linker.init("binary")
    assert(self and self._TOOL)

    -- init flags
    local flags = {}

    -- add flags from the configure
    linker._addflags_from_config(self, flags, "ldflags")

    -- add flags from the option
    linker._addflags_from_option(self, flags, "ldflags", opt)

    -- add flags from the platform
    linker._addflags_from_platform(self, flags, "ldflags")

    -- add flags from the links
    linker._addflags_from_links(self, flags, opt:get("links"))

    -- add flags from the compiler 
    linker._addflags_from_compiler(self, flags, "ldflags", sourcefile)

    -- add flags from the linker 
    linker._addflags_from_linker(self, flags, "ldflags")

    -- remove repeat
    flags = table.unique(flags)

    -- execute the link command
    return self._TOOL:main(self._TOOL:command_link(objectfile, targetfile, table.concat(flags, " "):trim(), utils.ifelse(option.get("verbose"), nil, xmake._NULDEV)))
end

-- return module
return linker
