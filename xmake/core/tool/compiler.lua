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
local config    = require("project/config")
local sandbox   = require("sandbox/sandbox")
local language  = require("language/language")
local platform  = require("platform/platform")

-- get the tool of compiler
function compiler:_tool()

    -- get it
    return self._TOOL
end

-- get the language of compiler
function compiler:_language()

    -- get it
    return self._LANGUAGE
end

-- get the source flags
function compiler:_sourceflags()

    -- get it
    return self._SOURCEFLAGS
end

-- map gcc flag to the given compiler flag
function compiler:_mapflag(flag, mapflags)

    -- attempt to map it directly
    local flag_mapped = mapflags[flag]
    if flag_mapped then
        return flag_mapped
    end

    -- find and replace it using pattern
    for k, v in pairs(mapflags) do
        local flag_mapped, count = flag:gsub("^" .. k .. "$", function (w) return v end)
        if flag_mapped and count ~= 0 then
            return utils.ifelse(#flag_mapped ~= 0, flag_mapped, nil) 
        end
    end

    -- check it 
    if self:check(flag) then
        return flag
    end
end

-- map gcc flags to the given compiler flags
function compiler:_mapflags(flags)

    -- wrap flags first
    flags = table.wrap(flags)

    -- done
    local results = {}
    local mapflags = self:get("mapflags")
    if mapflags then

        -- map flags
        for _, flag in pairs(flags) do
            local flag_mapped = self:_mapflag(flag, mapflags)
            if flag_mapped then
                table.insert(results, flag_mapped)
            end
        end

    else

        -- check flags
        for _, flag in pairs(flags) do
            if self:check(flag) then
                table.insert(results, flag)
            end
        end

    end

    -- ok?
    return results
end

-- add flags from the configure 
function compiler:_addflags_from_config(flags)

    -- done
    for _, sourceflag in ipairs(self:_sourceflags()) do
        table.join2(flags, config.get(sourceflag))
    end

    -- add the includedirs flags 
    for _, includedir in ipairs(table.wrap(config.get("includedirs"))) do
        table.join2(flags, self:includedir(includedir))
    end
end

-- add flags from the target 
function compiler:_addflags_from_target(flags, target)

    -- add the target flags 
    for _, sourceflag in ipairs(self:_sourceflags()) do
        table.join2(flags, self:_mapflags(target:get(sourceflag)))
    end

    -- add the symbol flags 
    if target.symbolfile then
        local symbolfile = target:symbolfile()
        for _, symbol in ipairs(table.wrap(target:get("symbols"))) do
            table.join2(flags, self:symbol(symbol, symbolfile))
        end
    end

    -- add the warning flags 
    for _, warning in ipairs(table.wrap(target:get("warnings"))) do
        table.join2(flags, self:warning(warning))
    end

    -- add the optimize flags 
    table.join2(flags, self:optimize(target:get("optimize") or ""))

    -- add the vector extensions flags 
    for _, vectorext in ipairs(table.wrap(target:get("vectorexts"))) do
        table.join2(flags, self:vectorext(vectorext))
    end

    -- add the language flags 
    for _, language in ipairs(table.wrap(target:get("languages"))) do
        table.join2(flags, self:language(language))
    end

    -- add the includedirs flags 
    for _, includedir in ipairs(table.wrap(target:get("includedirs"))) do
        table.join2(flags, self:includedir(includedir))
    end

    -- add the defines flags 
    for _, define in ipairs(table.wrap(target:get("defines"))) do
        table.join2(flags, self:define(define))
    end

    -- append the undefines flags 
    for _, undefine in ipairs(table.wrap(target:get("undefines"))) do
        table.join2(flags, self:undefine(undefine))
    end

    -- for target options? 
    if target.options then

        -- add the flags for the target options
        for _, opt in ipairs(target:options()) do

            -- add the flags from the option
            self:_addflags_from_target(flags, opt)

            -- append the defines flags
            for _, define in ipairs(table.wrap(opt:get("defines_if_ok"))) do
                table.join2(flags, self:define(define))
            end

            -- append the undefines flags 
            for _, undefine in ipairs(table.wrap(opt:get("undefines_if_ok"))) do
                table.join2(flags, self:undefine(undefine))
            end
        end
    end
end

-- add flags from the platform 
function compiler:_addflags_from_platform(flags)

    -- add flags 
    for _, sourceflag in ipairs(self:_sourceflags()) do
        table.join2(flags, platform.get(sourceflag))
    end

    -- add the includedirs flags
    for _, includedir in ipairs(table.wrap(platform.get("includedirs"))) do
        table.join2(flags, self:includedir(includedir))
    end

    -- add the defines flags 
    for _, define in ipairs(table.wrap(platform.get("defines"))) do
        table.join2(flags, self:define(define))
    end

    -- append the undefines flags
    for _, undefine in ipairs(table.wrap(platform.get("undefines"))) do
        table.join2(flags, self:undefine(undefine))
    end
end

-- add flags from the compiler 
function compiler:_addflags_from_compiler(flags, kind)

    -- done
    for _, sourceflag in ipairs(self:_sourceflags()) do

        -- add compiler.xxflags
        table.join2(flags, self:get(sourceflag))

        -- add compiler.kind.xxflags
        if kind ~= nil and self:get(kind) ~= nil then
            table.join2(flags, self:get(kind)[sourceflag])
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
    local instance = table.inherit(compiler)

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

    -- get source flags
    instance._SOURCEFLAGS = table.wrap(result:sourceflags()[sourcekind])

    -- save this instance
    compiler._INSTANCES[sourcekind] = instance

    -- ok
    return instance
end

-- get properties of the tool
function compiler:get(name)

    -- get it
    return self:_tool().get(name)
end

-- compile the source file
function compiler:compile(sourcefile, objectfile, incdepfile, target)

    -- compile it
    return sandbox.load(self:_tool().compile, sourcefile, objectfile, incdepfile, (self:compflags(target)))
end

-- get the compile command
function compiler:compcmd(sourcefile, objectfile, target)

    -- get it
    return self:_tool().compcmd(sourcefile, objectfile, (self:compflags(target)))
end

-- get the compling flags
function compiler:compflags(target)

    -- no target?
    if not target then
        return "", {}
    end

    -- get the target key
    local key = tostring(target)

    -- get it directly from cache dirst
    self._FLAGS = self._FLAGS or {}
    local flags_cached = self._FLAGS[key]
    if flags_cached then
        return flags_cached[1], flags_cached[2]
    end

    -- add flags from the configure 
    local flags = {}
    self:_addflags_from_config(flags)

    -- add flags from the target 
    self:_addflags_from_target(flags, target)

    -- add flags from the platform 
    self:_addflags_from_platform(flags)

    -- add flags from the compiler 
    self:_addflags_from_compiler(flags, target:get("kind"))

    -- remove repeat
    flags = table.unique(flags)

    -- concat
    local flags_str = table.concat(flags, " "):trim()

    -- save flags
    self._FLAGS[key] = {flags_str, flags}

    -- get it
    return flags_str, flags 
end

-- make the symbol flag
function compiler:symbol(level, symbolfile)

    -- make it
    return self:_tool().symbol(level, symbolfile)
end

-- make the language flag
function compiler:language(stdname)

    -- make it
    local flags = self:_tool().language(stdname)

    -- check it
    if self:check(flags) then
        return flags
    end

    -- not support
    return ""
end

-- make the vector extension flag
function compiler:vectorext(extension)

    -- make it
    local flags = self:_tool().vectorext(extension)

    -- check it
    if self:check(flags) then
        return flags
    end

    -- not support
    return ""
end

-- make the optimize flag
function compiler:optimize(level)

    -- make it
    return self:_tool().optimize(level)
end

-- make the warning flag
function compiler:warning(level)

    -- make it
    return self:_tool().warning(level)
end

-- make the define flag
function compiler:define(macro)

    -- make it
    return self:_tool().define(macro)
end

-- make the undefine flag
function compiler:undefine(macro)

    -- make it
    return self:_tool().undefine(macro)
end

-- make the includedir flag
function compiler:includedir(dir)

    -- make it
    return self:_tool().includedir(dir)
end

-- check the given flags 
function compiler:check(flags)

    -- the compiler tool
    local ctool = self:_tool()

    -- no check?
    if not ctool.check then
        return true
    end

    -- have been checked? return it directly
    self._CHECKED = self._CHECKED or {}
    if self._CHECKED[flags] ~= nil then
        return self._CHECKED[flags]
    end

    -- check it
    local ok, errors = sandbox.load(ctool.check, flags)

    -- trace
    if option.get("verbose") then
        utils.cprint("checking for the flags %s ... %s", flags, utils.ifelse(ok, "${green}ok", "${red}no"))
        if not ok then
            utils.cprint("${red}" .. errors or "")
        end
    end

    -- save the checked result
    self._CHECKED[flags] = ok

    -- ok?
    return ok
end

-- return module
return compiler
