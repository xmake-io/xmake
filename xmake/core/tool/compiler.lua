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
local compiler = compiler or {}

-- load modules
local io        = require("base/io")
local path      = require("base/path")
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local option    = require("base/option")
local tool      = require("tool/tool")
local builder   = require("tool/builder")
local config    = require("project/config")
local sandbox   = require("sandbox/sandbox")
local language  = require("language/language")
local platform  = require("platform/platform")

-- get the language of compiler
function compiler:_language()

    -- get it
    return self._LANGUAGE
end

-- add flags from the platform 
function compiler:_addflags_from_platform(flags, targetkind)

    -- add flags 
    local toolkind = self:kind()
    for _, flagkind in ipairs(self:_flagkinds()) do

        -- add flags for platform
        table.join2(flags, platform.get(flagkind))

        -- add flags for platform and the given taget kind
        if targetkind ~= nil and platform.get(targetkind) ~= nil then
            table.join2(flags, platform.get(targetkind)[flagkind])
        end
    end
end

-- add flags from the compiler 
function compiler:_addflags_from_compiler(flags, targetkind)

    -- done
    for _, flagkind in ipairs(self:_flagkinds()) do

        -- add compiler.xxflags
        table.join2(flags, self:get(flagkind))

        -- add compiler.targetkind.xxflags
        if targetkind ~= nil and self:get(targetkind) ~= nil then
            table.join2(flags, self:get(targetkind)[flagkind])
        end
    end
end

-- load the compiler from the given source kind
function compiler.load(sourcekind)

    -- check
    assert(sourcekind)

    -- get it directly from cache dirst
    compiler._INSTANCES = compiler._INSTANCES or {}
    if compiler._INSTANCES[sourcekind] then
        return compiler._INSTANCES[sourcekind]
    end

    -- new instance
    local instance = table.inherit(compiler, builder)

    -- load the compiler tool from the source kind
    local result, errors = tool.load(sourcekind)
    if not result then 
        return nil, errors
    end
    instance._TOOL = result
        
    -- load the compiler language from the source kind
    result, errors = language.load_sk(sourcekind)
    if not result then 
        return nil, errors
    end
    instance._LANGUAGE = result

    -- init target kind
    instance._TARGETKIND = "object"

    -- init name flags
    instance._NAMEFLAGS = result:nameflags()[instance:_targetkind()]

    -- init flag kinds
    instance._FLAGKINDS = table.wrap(result:sourceflags()[sourcekind])

    -- save this instance
    compiler._INSTANCES[sourcekind] = instance

    -- ok
    return instance
end

-- build the source files (compile and link)
function compiler:build(sourcefiles, targetfile, opt)

    -- init options
    opt = opt or {}

    -- make flags 
    local flags = self:compflags(opt)
    if opt.target then
        flags = flags .. " " .. (opt.target:linkflags())
    end

    -- get target kind
    local targetkind = opt.targetkind
    if not targetkind and opt.target then
        targetkind = opt.target:get("kind")
    end

    -- get it
    return sandbox.load(self:_tool().build, self:_tool(), sourcefiles, targetkind or "binary", targetfile, flags)
end

-- get the build command (compile and link)
function compiler:buildcmd(sourcefiles, targetfile, opt)

    -- init options
    opt = opt or {}

    -- make flags 
    local flags = self:compflags(opt)
    if opt.target then
        flags = flags .. " " .. (opt.target:linkflags())
    end

    -- get target kind
    local targetkind = opt.targetkind
    if not targetkind and opt.target then
        targetkind = opt.target:get("kind")
    end

    -- get it
    return self:_tool():buildcmd(sourcefiles, targetkind or "binary", targetfile, flags)
end

-- compile the source files
function compiler:compile(sourcefiles, objectfile, opt)

    -- init options
    opt = opt or {}

    -- compile it
    return sandbox.load(self:_tool().compile, self:_tool(), sourcefiles, objectfile, opt.incdepfiles, (self:compflags(opt)))
end

-- get the compile command
function compiler:compcmd(sourcefiles, objectfile, opt)
    return self:_tool():compcmd(sourcefiles, objectfile, (self:compflags(opt)))
end

-- get the compling flags
--
-- @param opt   the argument options (contain all the compiler attributes of target), 
--              .e.g {target = ..., targetkind = "static", cxflags = "", defines = "", includedirs = "", ...}
--
-- @return      flags string, flags list
--
function compiler:compflags(opt)

    -- init options
    opt = opt or {}

    -- get target
    local target = opt.target

    -- make the key
    local key = nil
    for _, arg in pairs(opt) do
        key = (key or "") .. tostring(arg)
    end

    -- get it directly from cache dirst
    if key then
        self._FLAGS = self._FLAGS or {}
        local flags_cached = self._FLAGS[key]
        if flags_cached then
            return flags_cached[1], flags_cached[2]
        end
    end

    -- get target kind
    local targetkind = opt.targetkind
    if not targetkind and target then
        targetkind = target:get("kind")
    end

    -- add flags from the configure 
    local flags = {}
    self:_addflags_from_config(flags)

    -- add flags for the target
    if target then
        self:_addflags_from_target(flags, target)
    end
       
    -- add flags (named) from language
    if target then
        self:_addflags_from_language(flags, target)
    end

    -- add flags for the argument
    self:_addflags_from_argument(flags, opt)

    -- add flags from the platform 
    if target then
        self:_addflags_from_platform(flags, targetkind)
    end

    -- add flags from the compiler 
    self:_addflags_from_compiler(flags, targetkind)

    -- remove repeat
    flags = table.unique(flags)

    -- concat
    local flags_str = table.concat(flags, " "):trim()

    -- save flags
    if key then
        self._FLAGS[key] = {flags_str, flags}
    end

    -- get it
    return flags_str, flags 
end

-- return module
return compiler
