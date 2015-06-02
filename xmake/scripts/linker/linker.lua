--!The Automatic Cross-linker Build Tool
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
            flags_mapped[table.getn(flags_mapped) + 1] = flag_mapped
        end
    end

    -- ok?
    return flags_mapped
end

-- make the command
function linker._make(self, kind, objfiles, targetfile, flags)

    -- check
    assert(self and self._make)

    -- the configure
    local configs = self._CONFIGS
    assert(configs)

    -- get the common flags string for the current linker
    local flags_common = nil
    if kind == "binary" then flags_common = configs.ldflags
    elseif kind == "static" then flags_common = configs.arflags
    elseif kind == "shared" then flags_common = configs.shflags
    end
    flags_common = flags_common or ""

    -- map flags
    flags = linker._mapflags(self, utils.wrap(flags))
    assert(flags)
    
    -- make flags string
    flags = table.concat(flags)
    assert(flags)

    -- make it
    return self._make(configs, table.concat(objfiles), targetfile, flags_common .. " " .. flags)
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
