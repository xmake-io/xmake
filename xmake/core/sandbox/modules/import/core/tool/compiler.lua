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
-- @file        compiler.lua
--

-- define module
local sandbox_core_tool_compiler = sandbox_core_tool_compiler or {}

-- load modules
local platform  = require("platform/platform")
local compiler  = require("tool/compiler")
local raise     = require("sandbox/modules/raise")

-- make command for compiling source file
function sandbox_core_tool_compiler.compcmd(sourcefile, objectfile, target)
 
    -- get the compiler instance
    local instance, errors = compiler.load(compiler.kind_of_file(sourcefile))
    if not instance then
        raise(errors)
    end

    -- make command
    return instance:compcmd(sourcefile, objectfile, target)
end

-- compile source file
function sandbox_core_tool_compiler.compile(sourcefile, objectfile, incdepfile, target)
 
    -- get the compiler instance
    local instance, errors = compiler.load(compiler.kind_of_file(sourcefile))
    if not instance then
        raise(errors)
    end

    -- compile it
    local ok, errors = instance:compile(sourcefile, objectfile, incdepfile, target)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_tool_compiler
