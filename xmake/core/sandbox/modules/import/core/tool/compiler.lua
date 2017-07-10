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
local platform = require("platform/platform")
local language = require("language/language")
local compiler = require("tool/compiler")
local raise    = require("sandbox/modules/raise")
local assert   = require("sandbox/modules/assert")
local import   = require("sandbox/modules/import")
local sandbox  = require("sandbox/sandbox")

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
--
-- @param sourcefiles   the source files
-- @param opt           the argument options (contain all the compiler attributes of target), 
--                      .e.g {target = ..., targetkind = "static", cxflags = "", defines = "", includedirs = "", ...}
--
-- @return              flags string, flags list
--
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

-- get all compiler features
--
-- @param sourcekind    the source kind, .e.g cc, cxx, mm, mxx, sc
-- @param opt           the argument options (contain all the compiler attributes of target), 
--                      .e.g {target = ..., targetkind = "static", cxflags = "", defines = "", includedirs = "", ...}
--
-- @return              the features
--
function sandbox_core_tool_compiler.features(sourcekind, opt)
 
    -- get the compiler instance
    local instance, errors = compiler.load(sourcekind)
    if not instance then
        raise(errors)
    end

    -- import "lib.detect.features"
    sandbox_core_tool_compiler._features = sandbox_core_tool_compiler._features or import("lib.detect.features")
    if sandbox_core_tool_compiler._features then

        -- get flags
        local _, flags = instance:compflags(opt)

        -- get features
        local ok, results_or_errors = sandbox.load(sandbox_core_tool_compiler._features, instance:name(), {flags = flags, program = instance:program()})
        if not ok then
            raise(results_or_errors)
        end

        -- return features
        return results_or_errors
    end

    -- no features
    return {}
end

-- has the given features?
--
-- @param features      the features, .e.g {"c_static_assert", "cxx_constexpr"}
-- @param opt           the argument options (contain all the compiler attributes of target), 
--                      .e.g {target = ..., targetkind = "static", cxflags = "", defines = "", includedirs = "", ...}
--
-- @return              the supported features or nil
--
function sandbox_core_tool_compiler.has_features(features, opt)
 
    -- init maps for c, objc
    local kinds = {c = "cc", m = "mm"}

    -- import "lib.detect.has_features"
    sandbox_core_tool_compiler._has_features = sandbox_core_tool_compiler._has_features or import("lib.detect.has_features")
    if not sandbox_core_tool_compiler._has_features then
        return 
    end

    -- classify features by kind
    local features_by_kind = {}
    for _, feature in ipairs(table.wrap(features)) do

        -- get feature kind
        local kind = feature:match("^(%w-)_")
        assert(kind, "unknown kind for the feature: %s", feature)

        -- fix kind for c, objc
        kind = kinds[kind] or kind
     
        -- add feature
        features_by_kind[kind] = features_by_kind[kind] or {}
        table.insert(features_by_kind[kind], feature)
    end

    -- has features for each compiler?
    local results = nil
    for kind, features in pairs(features_by_kind) do
 
        -- get the compiler instance
        local instance, errors = compiler.load(kind)
        if not instance then
            raise(errors)
        end

        -- get flags
        local _, flags = instance:compflags(opt)

        -- has features?
        local ok, results_or_errors = sandbox.load(sandbox_core_tool_compiler._has_features, instance:name(), features, {flags = flags, program = instance:program()})
        if not ok then
            raise(results_or_errors)
        end

        -- save results
        if results_or_errors then
            results = table.join(results or {}, results_or_errors)
        end
    end

    -- ok?
    return results
end

-- has the given flags?
--
-- @param sourcekind    the source kind 
-- @param flags         the flags
--
-- @return              the supported flags or nil
--
function sandbox_core_tool_compiler.has_flags(sourcekind, flags)
  
    -- get the compiler instance
    local instance, errors = compiler.load(sourcekind)
    if not instance then
        raise(errors)
    end

    -- has flags?
    return instance:has_flags(flags)
end

-- return module
return sandbox_core_tool_compiler
