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
-- @file        compiler.lua
--

-- define module
local sandbox_core_tool_compiler = sandbox_core_tool_compiler or {}

-- load modules
local platform  = require("platform/platform")
local language  = require("language/language")
local compiler  = require("tool/compiler")
local raise     = require("sandbox/modules/raise")
local assert    = require("sandbox/modules/assert")

-- get the feature of compiler
function sandbox_core_tool_compiler.feature(sourcekind, name)
 
    -- get the compiler instance
    local instance, errors = compiler.load(sourcekind)
    if not instance then
        raise(errors)
    end

    -- get feature
    return instance:feature(name)
end

-- make command for compiling source file
function sandbox_core_tool_compiler.compcmd(sourcefiles, objectfile, opt)

    -- init options
    opt = opt or {}

    -- get source kind if only one source file
    local sourcekind = opt.sourcekind
    if not sourcekind and type(sourcefiles) == "string" then
        sourcekind = language.sourcekind_of(sourcefiles)
    end
 
    -- get the compiler instance
    local instance, errors = compiler.load(sourcekind)
    if not instance then
        raise(errors)
    end
 
    -- make command
    return instance:compcmd(sourcefiles, objectfile, opt)
end

-- compile source files
function sandbox_core_tool_compiler.compile(sourcefiles, objectfile, opt)

    -- init options
    opt = opt or {}

    -- get source kind if only one source file
    local sourcekind = opt.sourcekind
    if not sourcekind and type(sourcefiles) == "string" then
        sourcekind = language.sourcekind_of(sourcefiles)
    end
 
    -- get the compiler instance
    local instance, errors = compiler.load(sourcekind)
    if not instance then
        raise(errors)
    end

    -- compile it
    local ok, errors = instance:compile(sourcefiles, objectfile, opt)
    if not ok then
        raise(errors)
    end
end

-- make compiling flags
function sandbox_core_tool_compiler.compflags(sourcefiles, opt)

    -- get source kind if only one source file
    local sourcekind = opt.sourcekind
    if not sourcekind and type(sourcefiles) == "string" then
        sourcekind = language.sourcekind_of(sourcefiles)
    end
 
    -- get the compiler instance
    local instance, errors = compiler.load(sourcekind)
    if not instance then
        raise(errors)
    end

    -- make flags
    return instance:compflags(opt)
end

-- make command for building source file
function sandbox_core_tool_compiler.buildcmd(sourcefiles, targetfile, opt)

    -- get source kind if only one source file
    local sourcekind = opt.sourcekind
    if not sourcekind and type(sourcefiles) == "string" then
        sourcekind = language.sourcekind_of(sourcefiles)
    end
 
    -- get the compiler instance
    local instance, errors = compiler.load(sourcekind)
    if not instance then
        raise(errors)
    end

    -- make command
    return instance:buildcmd(sourcefiles, targetfile, opt)
end

-- build source files
function sandbox_core_tool_compiler.build(sourcefiles, targetfile, opt)

    -- get source kind if only one source file
    local sourcekind = opt.sourcekind
    if not sourcekind and type(sourcefiles) == "string" then
        sourcekind = language.sourcekind_of(sourcefiles)
    end
 
    -- get the compiler instance
    local instance, errors = compiler.load(sourcekind)
    if not instance then
        raise(errors)
    end

    -- build it
    local ok, errors = instance:build(sourcefiles, targetfile, opt)
    if not ok then
        raise(errors)
    end
end


-- return module
return sandbox_core_tool_compiler
