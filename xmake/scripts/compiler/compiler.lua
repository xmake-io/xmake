--!The Automatic Cross-compiler Build Tool
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
-- @file        compiler.lua
--

-- define module: compiler
local compiler = compiler or {}

-- load modules
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")
local config    = require("base/config")

-- map gcc flags to the given compiler flags
function compiler._mapflags(self, flags)

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
    return flag_mapped
end

-- make the compile command
function compiler._make(self, filetype, srcfile, objfile, flags)

    -- check
    assert(self and filetype);

    -- the configure
    local configs = self._CONFIGS
    assert(configs)

    -- get the common flags string for the current compiler
    local flags_common = nil
    if filetype == "cc" then flags_common = configs.cflags
    elseif filetype == "cxx" then flags_common = configs.cxxflags
    elseif filetype == "mm" then flags_common = configs.mflags
    elseif filetype == "mxx" then flags_common = configs.mxxflags
    elseif filetype == "as" then flags_common = configs.asflags
    end
    flags_common = flags_common or ""

    -- map flags
    flags = compiler._mapflags(self, utils.wrap(flags))
    assert(flags)
    
    -- make flags string
    flags = table.concat(flags)
    assert(flags)

    -- get it
    return self._make(configs, srcfile, objfile, flags_common .. " " .. flags)
end

-- load the given compiler 
function compiler.load(name)

    -- check
    assert(name and type(name) == "string")

    -- gcc?
    local module = nil
    if name:find("gcc", 1, true) then module = "gcc"
    -- clang?
    elseif name:find("clang", 1, true) then module = "clang"
    -- cl.exe?
    elseif name:find("cl.exe", 1, true) then module = "msvc"
    -- icc?
    elseif name:find("icc", 1, true) then module = "icc"
    -- as?
    elseif name:find("as", 1, true) then module = "as"
    -- unknown?
    else
        -- error
        utils.error("unknown compiler: %s", name)
        return nil
    end

    -- load the given compiler 
    local c = require("compiler/_" .. module)
    if not c then
        return nil
    end

    -- the compiler has been loaded? return it directly
    if c._CONFIGS then 
        return c
    end

    -- make the compiler configure
    c._CONFIGS = {}
    local configs = c._CONFIGS

    -- init the compiler name
    configs.name = name

    -- init the compiler configure
    c._init(configs)

    -- init interfaces
    c["make"] = compiler._make

    -- ok?
    return c
end

-- get the source file type
function compiler.filetype(srcfile)

    -- get the source file type
    local filetype = path.extension(srcfile)
    if not filetype then
        return nil
    end

    -- get the lower file type
    filetype = filetype:lower()

    -- get the compiler name
    local name = nil
    if filetype == ".c" then name = "cc"
    elseif filetype == ".cpp" or filetype == ".cc" then name = "cxx"
    elseif filetype == ".m" then name = "mm"
    elseif filetype == ".mm" then name = "mxx"
    elseif filetype == ".s" or filetype == ".asm" then name = "as"
    end
    
    -- ok
    return name
end
    
-- return module: compiler
return compiler
