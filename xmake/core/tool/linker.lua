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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        linker.lua
--

-- define module
local linker = linker or {}

-- load modules
local io        = require("base/io")
local path      = require("base/path")
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local option    = require("base/option")
local config    = require("project/config")
local sandbox   = require("sandbox/sandbox")
local language  = require("language/language")
local platform  = require("platform/platform")
local tool      = require("tool/tool")
local builder   = require("tool/builder")
local compiler  = require("tool/compiler")

-- add flags from the platform 
function linker:_add_flags_from_platform(flags, targetkind)

    -- attempt to add special lanugage flags first for target kind, e.g. binary.go.gc-ldflags, static.dc-arflags
    if targetkind then
        local toolkind = self:kind()
        local toolname = self:name()
        for _, flagkind in ipairs(self:_flagkinds()) do
            local toolflags = platform.get(targetkind .. '.' .. toolname .. '.' .. toolkind .. 'flags') or platform.get(targetkind .. '.' .. toolname .. '.' .. flagkind)
            table.join2(flags, toolflags or platform.get(targetkind .. '.' .. toolkind .. 'flags') or platform.get(targetkind .. '.' .. flagkind))
        end
    end
end

-- add flags from the linker 
function linker:_add_flags_from_linker(flags)

    -- add flags
    local toolkind = self:kind()
    for _, flagkind in ipairs(self:_flagkinds()) do

        -- attempt to add special lanugage flags first, e.g. gc-ldflags, dc-arflags
        table.join2(flags, self:get(toolkind .. 'flags') or self:get(flagkind))
    end
end

-- load tool
function linker._load_tool(targetkind, sourcekinds, target)

    -- get the linker infos
    local linkerinfos, errors = language.linkerinfos_of(targetkind, sourcekinds)
    if not linkerinfos then
        return nil, errors
    end

    -- select the linker
    local linkerinfo = nil
    local linkertool = nil
    local firsterror = nil
    for _, _linkerinfo in ipairs(linkerinfos) do

        -- get program from target
        local program = nil
        if target then
            program = target:get("toolchain." .. _linkerinfo.linkerkind)
            if not program then
                local tools = target:get("tools") -- TODO: deprecated
                if tools then
                    program = tools[_linkerinfo.linkerkind]
                end
            end
        end

        -- load the linker tool from the linker kind (with cache)
        linkertool, errors = tool.load(_linkerinfo.linkerkind, program)
        if linkertool then 
            linkerinfo = _linkerinfo
            linkerinfo.program = program
            break
        else
            firsterror = firsterror or errors
        end
    end
    if not linkerinfo then
        return nil, firsterror
    end

    -- done
    return linkertool, linkerinfo
end

-- load the linker from the given target kind
function linker.load(targetkind, sourcekinds, target)

    -- check
    assert(sourcekinds)

    -- wrap sourcekinds first
    sourcekinds = table.wrap(sourcekinds)
    if #sourcekinds == 0 then
        -- we need detect the sourcekinds of all deps if the current target has not any source files
        for _, dep in ipairs(target:orderdeps()) do
            table.join2(sourcekinds, dep:sourcekinds())
        end
        if #sourcekinds > 0 then
            sourcekinds = table.unique(sourcekinds)
        end
    end

    -- load linker tool first (with cache)
    local linkertool, linkerinfo_or_errors = linker._load_tool(targetkind, sourcekinds, target)
    if not linkertool then
        return nil, linkerinfo_or_errors
    end

    -- get linker info
    local linkerinfo = linkerinfo_or_errors

    -- init cache key
    local cachekey = targetkind .. "_" .. linkerinfo.linkerkind .. (linkerinfo.program or "") .. (config.get("arch") or os.arch())

    -- get it directly from cache dirst
    builder._INSTANCES = builder._INSTANCES or {}
    if builder._INSTANCES[cachekey] then
        return builder._INSTANCES[cachekey]
    end

    -- new instance
    local instance = table.inherit(linker, builder)

    -- save linker tool
    instance._TOOL = linkertool
 
    -- load the name flags of archiver 
    local nameflags = {}
    local nameflags_exists = {}
    for _, sourcekind in ipairs(sourcekinds) do

        -- load language 
        local result, errors = language.load_sk(sourcekind)
        if not result then 
            return nil, errors
        end

        -- merge name flags
        for _, flaginfo in ipairs(table.wrap(result:nameflags()[targetkind])) do
            local key = flaginfo[1] .. flaginfo[2]
            if not nameflags_exists[key] then
                table.insert(nameflags, flaginfo)
                nameflags_exists[key] = flaginfo
            end
        end
    end
    instance._NAMEFLAGS = nameflags

    -- init target kind
    instance._TARGETKIND = targetkind

    -- init flag kinds
    instance._FLAGKINDS = {linkerinfo.linkerflag}

    -- save this instance
    builder._INSTANCES[cachekey] = instance

    -- add platform flags to the linker tool
    local toolkind = linkertool:kind()
    local toolname = linkertool:name()
    for _, flagkind in ipairs(instance:_flagkinds()) do

        -- add special lanugage flags first, e.g. go.gc-ldflags or gcc.ldflags or gc-ldflags or ldflags
        linkertool:add(toolkind .. 'flags', platform.get(toolname .. '.' .. toolkind .. 'flags') or platform.get(toolkind .. 'flags'))
        linkertool:add(flagkind, platform.get(toolname .. '.' .. flagkind) or platform.get(flagkind))
    end

    -- ok
    return instance
end

-- link the target file
function linker:link(objectfiles, targetfile, opt)
    opt = opt or {}
    return sandbox.load(self:_tool().link, self:_tool(), table.wrap(objectfiles), self:_targetkind(), targetfile, opt.linkflags or self:linkflags(opt), opt)
end

-- get the link arguments list
function linker:linkargv(objectfiles, targetfile, opt)
    return self:_tool():linkargv(table.wrap(objectfiles), self:_targetkind(), targetfile, opt.linkflags or self:linkflags(opt), opt)
end

-- get the link command
function linker:linkcmd(objectfiles, targetfile, opt)
    return os.args(table.join(self:linkargv(objectfiles, targetfile, opt)))
end

-- get the link flags
--
-- @param opt   the argument options (contain all the linker attributes of target), 
--              e.g. {target = ..., targetkind = "static", configs = {ldflags = "", links = "", linkdirs = "", ...}}
--
function linker:linkflags(opt)

    -- init options
    opt = opt or {}

    -- get target
    local target = opt.target

    -- get target kind
    local targetkind = opt.targetkind
    if not targetkind and target and target.targetkind then
        targetkind = target:targetkind()
    end

    -- add flags from the configure 
    local flags = {}
    self:_add_flags_from_config(flags)

    -- add flags for the target
    self:_add_flags_from_target(flags, target)

    -- add flags for the argument
    local configs = opt.configs or opt.config
    if configs then
        self:_add_flags_from_argument(flags, target, configs)
    end

    -- add flags from the platform 
    self:_add_flags_from_platform(flags, targetkind)

    -- add flags from the linker 
    self:_add_flags_from_linker(flags)

    -- preprocess flags
    return self:_preprocess_flags(flags)
end

-- return module
return linker
