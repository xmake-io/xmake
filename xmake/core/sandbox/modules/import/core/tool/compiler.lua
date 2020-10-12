--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
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

-- load the compiler from the given source kind
function sandbox_core_tool_compiler.load(sourcekind, opt)
    local instance, errors = compiler.load(sourcekind, opt and opt.target or nil)
    if not instance then
        raise(errors)
    end
    return instance
end

-- make command for compiling source file
function sandbox_core_tool_compiler.compcmd(sourcefiles, objectfile, opt)
    return os.args(table.join(sandbox_core_tool_compiler.compargv(sourcefiles, objectfile, opt)))
end

-- make arguments list for compiling source file
function sandbox_core_tool_compiler.compargv(sourcefiles, objectfile, opt)

    -- init options
    opt = opt or {}

    -- get source kind if only one source file
    local sourcekind = opt.sourcekind
    if not sourcekind and type(sourcefiles) == "string" then
        sourcekind = language.sourcekind_of(sourcefiles)
    end

    -- get the compiler instance
    local instance = sandbox_core_tool_compiler.load(sourcekind, opt)

    -- make arguments list
    return instance:compargv(sourcefiles, objectfile, opt)
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
    local instance = sandbox_core_tool_compiler.load(sourcekind, opt)

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
--                      e.g. {target = ..., targetkind = "static", config = {cxflags = "", defines = "", includedirs = "", ...}}
--
-- @return              the flags list
--
function sandbox_core_tool_compiler.compflags(sourcefiles, opt)

    -- init options
    opt = opt or {}

    -- patch sourcefile to get flags of the given source file
    if type(sourcefiles) == "string" then
        opt.sourcefile = sourcefiles
    end

    -- get source kind if only one source file
    local sourcekind = opt.sourcekind
    if not sourcekind and type(sourcefiles) == "string" then
        sourcekind = language.sourcekind_of(sourcefiles)
    end

    -- get the compiler instance
    local instance = sandbox_core_tool_compiler.load(sourcekind, opt)

    -- make flags
    return instance:compflags(opt)
end

-- make command for building source file
function sandbox_core_tool_compiler.buildcmd(sourcefiles, targetfile, opt)
    return os.args(table.join(sandbox_core_tool_compiler.buildargv(sourcefiles, targetfile, opt)))
end

-- make arguments list for building source file
function sandbox_core_tool_compiler.buildargv(sourcefiles, targetfile, opt)

    -- init options
    opt = opt or {}

    -- get source kind if only one source file
    local sourcekind = opt.sourcekind
    if not sourcekind and type(sourcefiles) == "string" then
        sourcekind = language.sourcekind_of(sourcefiles)
    end

    -- get the compiler instance
    local instance = sandbox_core_tool_compiler.load(sourcekind, opt)

    -- make arguments list
    return instance:buildargv(sourcefiles, targetfile, opt)
end

-- build source files
function sandbox_core_tool_compiler.build(sourcefiles, targetfile, opt)

    -- init options
    opt = opt or {}

    -- get source kind if only one source file
    local sourcekind = opt.sourcekind
    if not sourcekind and type(sourcefiles) == "string" then
        sourcekind = language.sourcekind_of(sourcefiles)
    end

    -- get the compiler instance
    local instance = sandbox_core_tool_compiler.load(sourcekind, opt)

    -- build it
    local ok, errors = instance:build(sourcefiles, targetfile, opt)
    if not ok then
        raise(errors)
    end
end

-- get the current compiler name of given language kind
--
-- @param langkind      the language kind, e.g. c, cxx, mm, mxx, swift, go, rust, d, as
--
-- @return              the compiler name
--
function sandbox_core_tool_compiler.name(langkind, opt)

    -- get sourcekind from the language kind
    local sourcekind = language.langkinds()[langkind]
    assert(sourcekind, "unknown language kind: " .. langkind)

    -- get the compiler instance
    local instance = sandbox_core_tool_compiler.load(sourcekind, opt)
    return instance:name()
end

-- get all compiler features
--
-- @param langkind      the language kind, e.g. c, cxx, mm, mxx, swift, go, rust, d, as
-- @param opt           the argument options (contain all the compiler attributes of target),
--                      e.g. {target = ..., targetkind = "static", cxflags = "", defines = "", includedirs = "", ...}
--
-- @return              the features
--
function sandbox_core_tool_compiler.features(langkind, opt)

    -- init options
    opt = opt or {}

    -- get sourcekind from the language kind
    local sourcekind = language.langkinds()[langkind]
    assert(sourcekind, "unknown language kind: " .. langkind)

    -- get the compiler instance
    local instance = sandbox_core_tool_compiler.load(sourcekind, opt)

    -- import "lib.detect.features"
    sandbox_core_tool_compiler._features = sandbox_core_tool_compiler._features or import("lib.detect.features")
    if sandbox_core_tool_compiler._features then

        -- get flags
        local flags = instance:compflags(opt)

        -- get features
        local ok, results_or_errors = sandbox.load(sandbox_core_tool_compiler._features, instance:name(), {flags = flags, program = instance:program(), envs = instance:runenvs()})
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
-- @param features      the features, e.g. {"c_static_assert", "cxx_constexpr"}
-- @param opt           the argument options (contain all the compiler attributes of target),
--                      e.g. {target = ..., targetkind = "static", cxflags = "", defines = "", includedirs = "", ...}
--
-- @return              the supported features or nil
--
function sandbox_core_tool_compiler.has_features(features, opt)

    -- import "lib.detect.has_features"
    sandbox_core_tool_compiler._has_features = sandbox_core_tool_compiler._has_features or import("lib.detect.has_features")
    if not sandbox_core_tool_compiler._has_features then
        return
    end

    -- init options
    opt = opt or {}

    -- get the language kinds
    local langkinds = language.langkinds()

    -- classify features by the source kind
    local features_by_kind = {}
    for _, feature in ipairs(table.wrap(features)) do

        -- get language kind
        local langkind = feature:match("^(%w-)_")
        assert(langkind, "unknown language kind for the feature: %s", feature)

        -- get the sourcekind from the language kind
        local sourcekind = langkinds[langkind]
        assert(sourcekind, "unknown language kind: " .. langkind)

        -- add feature
        features_by_kind[sourcekind] = features_by_kind[sourcekind] or {}
        table.insert(features_by_kind[sourcekind], feature)
    end

    -- has features for each compiler?
    local results = nil
    for sourcekind, features in pairs(features_by_kind) do

        -- get the compiler instance
        local instance = sandbox_core_tool_compiler.load(sourcekind, opt)

        -- get flags
        local flags = instance:compflags(opt)

        -- has features?
        local ok, results_or_errors = sandbox.load(sandbox_core_tool_compiler._has_features, instance:name(), features, {flags = flags, program = instance:program(), envs = instance:runenvs()})
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
-- @param langkind      the language kind, e.g. c, cxx, mm, mxx, swift, go, rust, d, as
-- @param flags         the flags
-- @param options       the options
--
-- @return              the supported flags or nil
--
function sandbox_core_tool_compiler.has_flags(langkind, flags, opt)

    -- init options
    opt = opt or {}

    -- get sourcekind from the language kind
    local sourcekind = language.langkinds()[langkind]
    assert(sourcekind, "unknown language kind: " .. langkind)

    -- get the compiler instance
    local instance = sandbox_core_tool_compiler.load(sourcekind, opt)

    -- has flags?
    return instance:has_flags(flags)
end

-- return module
return sandbox_core_tool_compiler
