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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
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

-- add flags from the toolchains
function compiler:_add_flags_from_toolchains(flags, targetkind, target)

    -- add flags for platform with the given target kind, e.g. binary.gcc.cxflags or binary.cxflags
    if targetkind then
        local toolname = self:name()
        if target and target.toolconfig then
            for _, flagkind in ipairs(self:_flagkinds()) do
                local toolflags = target:toolconfig(targetkind .. '.' .. toolname .. '.' .. flagkind)
                table.join2(flags, toolflags or target:toolconfig(targetkind .. '.' .. flagkind))
            end
        else
            for _, flagkind in ipairs(self:_flagkinds()) do
                local toolflags = platform.toolconfig(targetkind .. '.' .. toolname .. '.' .. flagkind)
                table.join2(flags, toolflags or platform.toolconfig(targetkind .. '.' .. flagkind))
            end
        end
    end
end

-- add flags from the compiler
function compiler:_add_flags_from_compiler(flags, targetkind)
    for _, flagkind in ipairs(self:_flagkinds()) do

        -- add compiler, e.g. cxflags
        table.join2(flags, self:get(flagkind))

        -- add compiler, e.g. targetkind.cxflags
        if targetkind then
            table.join2(flags, self:get(targetkind .. '.' .. flagkind))
        end
    end
end

-- add flags from the sourcefile config
function compiler:_add_flags_from_fileconfig(flags, target, sourcefile, fileconfig)

    -- add flags from the current compiler
    local add_sourceflags = self:_tool().add_sourceflags
    if add_sourceflags then
        local flag = add_sourceflags(self:_tool(), sourcefile, fileconfig, target, self:_targetkind())
        if flag and flag ~= "" then
            table.join2(flags, flag)
        end
    end

    -- add flags from the common argument option
    self:_add_flags_from_argument(flags, target, fileconfig)
end

-- load compiler tool
function compiler._load_tool(sourcekind, target)

    -- get program from target
    local program, toolname, toolchain_info
    if target and target.tool then
        program, toolname, toolchain_info = target:tool(sourcekind)
    end

    -- load the compiler tool from the source kind
    local result, errors = tool.load(sourcekind, {program = program, toolname = toolname, toolchain_info = toolchain_info})
    if not result then
        return nil, errors
    end
    return result, program
end

-- load the compiler from the given source kind
function compiler.load(sourcekind, target)
    if not sourcekind then
        return nil, "unknown source kind!"
    end

    -- load compiler tool first (with cache)
    local compiler_tool, program_or_errors = compiler._load_tool(sourcekind, target)
    if not compiler_tool then
        return nil, program_or_errors
    end

    -- init cache key
    local cachekey = sourcekind .. (program_or_errors or "") .. (config.get("arch") or os.arch())

    -- get it directly from cache dirst
    compiler._INSTANCES = compiler._INSTANCES or {}
    if compiler._INSTANCES[cachekey] then
        return compiler._INSTANCES[cachekey]
    end

    -- new instance
    local instance = table.inherit(compiler, builder)

    -- save the compiler tool
    instance._TOOL = compiler_tool

    -- load the compiler language from the source kind
    local result, errors = language.load_sk(sourcekind)
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
    compiler._INSTANCES[cachekey] = instance

    -- add toolchains flags to the compiler tool, e.g. gcc.cxflags or cxflags
    local toolname = compiler_tool:name()
    if target and target.toolconfig then
        for _, flagkind in ipairs(instance:_flagkinds()) do
            compiler_tool:add(flagkind, target:toolconfig(toolname .. '.' .. flagkind) or target:toolconfig(flagkind))
        end
    else
        for _, flagkind in ipairs(instance:_flagkinds()) do
            compiler_tool:add(flagkind, platform.toolconfig(toolname .. '.' .. flagkind) or platform.toolconfig(flagkind))
        end
    end
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
    if not targetkind and opt.target and opt.target.targetkind then
        targetkind = opt.target:kind()
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
    if not targetkind and opt.target and opt.target.targetkind then
        targetkind = opt.target:kind()
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
    return sandbox.load(self:_tool().compile, self:_tool(), sourcefiles, objectfile, opt.dependinfo, compflags, opt)
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
    return self:_tool():compargv(sourcefiles, objectfile, compflags, opt)
end

-- get the compile command
function compiler:compcmd(sourcefiles, objectfile, opt)
    return os.args(table.join(self:compargv(sourcefiles, objectfile, opt)))
end

-- get the compling flags
--
-- @param opt   the argument options (contain all the compiler attributes of target),
--              e.g.
--              {target = ..., targetkind = "static", configs = {defines = "", cxflags = "", includedirs = ""}}
--
-- @return      flags list
--
function compiler:compflags(opt)

    -- init options
    opt = opt or {}

    -- get target
    local target = opt.target

    -- get target kind
    local targetkind = opt.targetkind
    if not targetkind and target and target:type() == "target" then
        targetkind = target:kind()
    end

    -- add flags from compiler/toolchains
    --
    -- we need to add toolchain flags at the beginning to allow users to override them.
    -- but includedirs/links/syslinks/linkdirs will still be placed last, they are in the order defined in languages/xmake.lua
    --
    -- @see https://github.com/xmake-io/xmake/issues/978
    --
    local flags = {}
    self:_add_flags_from_compiler(flags, targetkind)
    self:_add_flags_from_toolchains(flags, targetkind, target)

    -- add flags from user configuration
    self:_add_flags_from_config(flags)

    -- add flags from target
    self:_add_flags_from_target(flags, target)

    -- add flags from source file configuration
    if opt.sourcefile and target and target.fileconfig then
        local fileconfig = target:fileconfig(opt.sourcefile)
        if fileconfig then
            self:_add_flags_from_fileconfig(flags, target, opt.sourcefile, fileconfig)
        end
    end

    -- add flags from argument
    local configs = opt.configs or opt.config
    if configs then
        self:_add_flags_from_argument(flags, target, configs)
    end

    -- preprocess flags
    return self:_preprocess_flags(flags)
end

-- return module
return compiler
