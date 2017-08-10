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

    -- get compile flags
    local compflags = opt.compflags
    if not compflags then
        -- patch sourcefile to get flags of the given source file
        if type(sourcefiles) == "string" then
            opt.sourcefile = sourcefiles
        end
        compflags = self:compflags(opt)
    end

    -- make flags 
    local flags = compflags
    if opt.target then
        flags = table.join(flags, opt.target:linkflags())
    end

    -- get target kind
    local targetkind = opt.targetkind
    if not targetkind and opt.target then
        targetkind = opt.target:get("kind")
    end

    -- get it
    return sandbox.load(self:_tool().build, self:_tool(), sourcefiles, targetkind or "binary", targetfile, flags)
end

-- get the build arguments list (compile and link)
function compiler:buildargv(sourcefiles, targetfile, opt)

    -- init options
    opt = opt or {}

    -- get compile flags
    local compflags = opt.compflags
    if not compflags then
        -- patch sourcefile to get flags of the given source file
        if type(sourcefiles) == "string" then
            opt.sourcefile = sourcefiles
        end
        compflags = self:compflags(opt)
    end

    -- make flags 
    local flags = compflags
    if opt.target then
        flags = table.join(flags, opt.target:linkflags())
    end

    -- get target kind
    local targetkind = opt.targetkind
    if not targetkind and opt.target then
        targetkind = opt.target:get("kind")
    end

    -- get it
    return self:_tool():buildargv(sourcefiles, targetkind or "binary", targetfile, flags)
end

-- get the build command
function compiler:buildcmd(sourcefiles, targetfile, opt)
    return os.args(table.join(self:buildargv(sourcefiles, targetfile, opt)))
end

-- compile the source files
function compiler:compile(sourcefiles, objectfile, opt)

    -- init options
    opt = opt or {}

    -- get compile flags
    local compflags = opt.compflags
    if not compflags then
        -- patch sourcefile to get flags of the given source file
        if type(sourcefiles) == "string" then
            opt.sourcefile = sourcefiles
        end
        compflags = self:compflags(opt)
    end

    -- compile it
    return sandbox.load(self:_tool().compile, self:_tool(), sourcefiles, objectfile, opt.depinfo, compflags)
end

-- get the compile arguments list
function compiler:compargv(sourcefiles, objectfile, opt)

    -- init options
    opt = opt or {}

    -- get compile flags
    local compflags = opt.compflags
    if not compflags then
        -- patch sourcefile to get flags of the given source file
        if type(sourcefiles) == "string" then
            opt.sourcefile = sourcefiles
        end
        compflags = self:compflags(opt)
    end
    return self:_tool():compargv(sourcefiles, objectfile, compflags)
end

-- get the compile command
function compiler:compcmd(sourcefiles, objectfile, opt)
    return os.args(table.join(self:compargv(sourcefiles, objectfile, opt)))
end

-- get the compling flags
--
-- @param opt   the argument options (contain all the compiler attributes of target), 
--              .e.g
--              {target = ..., targetkind = "static", config = {defines = "", cxflags = "", includedirs = ""}}
--
-- @return      flags string, flags list
--
function compiler:compflags(opt)

    -- init options
    opt = opt or {}

    -- get target
    local target = opt.target

    -- get target kind
    local targetkind = opt.targetkind
    if not targetkind and target then
        targetkind = target:get("kind")
    end

    -- add flags from the configure 
    local flags = {}
    self:_addflags_from_config(flags)

    -- add flags for the target
    self:_addflags_from_target(flags, target)

    -- add flags for the source file
    if opt.sourcefile and target and target.fileconfig then
        local fileconfig = target:fileconfig(opt.sourcefile)
        if fileconfig then
            self:_addflags_from_argument(flags, target, fileconfig)
        end
    end

    -- add flags for the argument
    if opt.config then
        self:_addflags_from_argument(flags, target, opt.config)
    end

    -- add flags from the platform 
    if target then
        self:_addflags_from_platform(flags, targetkind)
    end

    -- add flags from the compiler 
    self:_addflags_from_compiler(flags, targetkind)

    -- remove repeat
    flags = table.unique(flags)

    -- split flag group, .e.g "-I /xxx" => {"-I", "/xxx"}
    local results = {}
    for _, flag in ipairs(flags) do
        flag = flag:trim()
        if #flag > 0 then
            if flag:find(" ", 1, true) then
                table.join2(results, os.argv(flag))
            else
                table.insert(results, flag)
            end
        end
    end

    -- get it
    return results 
end

-- return module
return compiler
