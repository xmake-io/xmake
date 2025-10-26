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
-- Copyright (C) 2015-present, Xmake Open Source Community.
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
local profiler  = require("base/profiler")
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
    local program, toolname, toolchain_info
    if target and target.tool then
        program, toolname, toolchain_info = target:tool(sourcekind)
    end

    -- is host?
    local is_host
    if target and target.is_host then
        is_host = target:is_host()
    end

    -- load the compiler tool from the source kind
    local result, errors = tool.load(sourcekind, {
        host = is_host,
        program = program,
        toolname = toolname,
        toolchain_info = toolchain_info})
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

    -- init cache key
    -- @note we need plat/arch,
    -- because it is possible for the compiler to do cross-compilation with the -target parameter
    local plat = config.plat() or os.host()
    local arch = config.arch() or os.arch()
    if target and target.tool then
        local _, _, toolchain_info = target:tool(sourcekind)
        if toolchain_info then
            plat = toolchain_info.plat
            arch = toolchain_info.arch
        end
    end
    local cachekey = sourcekind .. (program_or_errors or "") .. plat .. arch
    if target then
        cachekey = cachekey .. tostring(target)
    end

    -- get it directly from cache dirst
    compiler._INSTANCES = compiler._INSTANCES or {}
    local instance = compiler._INSTANCES[cachekey]
    if not instance then
        instance = table.inherit(compiler, builder)

        -- load compiler tool
        -- @NOTE We cannot cache the tool, otherwise it may cause duplicate toolchain flags to be added
        local compiler_tool, program_or_errors = compiler._load_tool(sourcekind, target)
        if not compiler_tool then
            return nil, program_or_errors
        end
        instance._TOOL = compiler_tool

        -- load the compiler language from the source kind
        local result, errors = language.load_sk(sourcekind)
        if not result then
            return nil, errors
        end
        instance._LANGUAGE = result

        -- init target (optional)
        instance._TARGET = target

        -- init target kind
        instance._TARGETKIND = "object"

        -- init name flags
        instance._NAMEFLAGS = result:nameflags()[instance:_targetkind()]

        -- init flag kinds
        instance._FLAGKINDS = table.wrap(result:sourceflags()[sourcekind])

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

        -- @note we can't call _load_once before caching the instance,
        -- it may call has_flags to trigger the concurrent scheduling.
        --
        -- this will result in more compiler/linker instances being created at the same time,
        -- and they will access the same tool instance at the same time.
        --
        -- @see https://github.com/xmake-io/xmake/issues/3429
        compiler._INSTANCES[cachekey] = instance
    end

    -- we need to load it at the end because in tool.load().
    -- because we may need to call has_flags, which requires the full platform toolchain flags
    local ok, errors = instance:_tool():_load_once()
    if not ok then
        return nil, errors
    end
    return instance
end

-- build the source files (compile and link)
function compiler:build(sourcefiles, targetfile, opt)
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
    return sandbox.load(self:_tool().build, self:_tool(), sourcefiles, targetkind or "binary", targetfile, flags)
end

-- get the build arguments list (compile and link)
function compiler:buildargv(sourcefiles, targetfile, opt)
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
    return self:_tool():buildargv(sourcefiles, targetkind or "binary", targetfile, flags)
end

-- get the build command
function compiler:buildcmd(sourcefiles, targetfile, opt)
    return os.args(table.join(self:buildargv(sourcefiles, targetfile, opt)))
end

-- compile the source files
function compiler:compile(sourcefiles, objectfile, opt)

    -- get compile flags
    opt = opt or {}
    local compflags = opt.compflags
    if not compflags then
        -- patch sourcefile to get flags of the given source file
        if type(sourcefiles) == "string" then
            opt.sourcefile = sourcefiles
        end
        compflags = self:compflags(opt)
    end

    -- compile it
    opt = table.copy(opt)
    opt.target = self:target()
    profiler:enter(self:name(), "compile", sourcefiles)
    local ok, errors = sandbox.load(self:_tool().compile, self:_tool(), sourcefiles, objectfile, opt.dependinfo, compflags, opt)
    profiler:leave(self:name(), "compile", sourcefiles)
    return ok, errors
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
    opt = opt or {}

    -- get target
    local target = opt.target or self:target()
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

    -- add flags from user configuration
    self:_add_flags_from_config(flags)

    -- preprocess flags
    return self:_preprocess_flags(flags)
end

-- return module
return compiler
