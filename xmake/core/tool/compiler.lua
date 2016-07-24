--!The Make-like Build Utility based on Lua
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
local platform  = require("platform/platform")

-- get the current tool
function compiler:_tool()

    -- get it
    return self._TOOL
end

-- get the current flag names
function compiler:_flagnames()

    -- get it
    return self._FLAGNAMES
end

-- get the flags
function compiler:_flags(target)

    -- get the target key
    local key = tostring(target)

    -- get it directly from cache dirst
    self._FLAGS = self._FLAGS or {}
    if self._FLAGS[key] then
        return self._FLAGS[key]
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

    -- merge flags
    flags = table.concat(flags, " "):trim()

    -- save flags
    self._FLAGS[key] = flags

    -- get it
    return flags
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
    for _, flagname in ipairs(self:_flagnames()) do
        table.join2(flags, config.get(flagname))
    end
end

-- add flags from the target 
function compiler:_addflags_from_target(flags, target)

    -- add the target flags 
    for _, flagname in ipairs(self:_flagnames()) do
        table.join2(flags, self:_mapflags(target:get(flagname)))
    end

    -- add the symbol flags 
    for _, symbol in ipairs(table.wrap(target:get("symbols"))) do
        table.join2(flags, self:symbol(symbol))
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
        for _, opt in pairs(target:options()) do

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
    for _, flagname in ipairs(self:_flagnames()) do
        table.join2(flags, platform.get(flagname))
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
    for _, flagname in ipairs(self:_flagnames()) do

        -- add compiler.xxflags
        table.join2(flags, self:get(flagname))

        -- add compiler.kind.xxflags
        if kind ~= nil and self:get(kind) ~= nil then
            table.join2(flags, self:get(kind)[flagname])
        end
    end
end

-- get the compiler kind of the source file 
function compiler.kind_of_file(sourcefile)

    -- get the source file type
    local filetype = path.extension(sourcefile)
    if not filetype then
        return nil
    end

    -- the kinds
    local kinds = 
    {
        [".c"]      = "cc"
    ,   [".cc"]     = "cxx"
    ,   [".cpp"]    = "cxx"
    ,   [".m"]      = "mm"
    ,   [".mm"]     = "mxx"
    ,   [".s"]      = "as"
    ,   [".asm"]    = "as"
    ,   [".swift"]  = "sc"
    }

    -- get kind
    return kinds[filetype:lower()]
end

-- get the current kind
function compiler:kind()

    -- get it
    return self._KIND
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

    -- load the compiler tool from the source file type
    local result, errors = tool.load(sourcekind)
    if not result then 
        return nil, errors
    end
        
    -- save tool
    instance._TOOL = result

    -- save kind 
    instance._KIND = sourcekind 

    -- save flagnames
    local flagnames =
    {
        cc =    { "cxflags", "cflags"   }
    ,   cxx =   { "cxflags", "cxxflags" }
    ,   mm =    { "mxflags", "mflags"   }
    ,   mxx =   { "mxflags", "mxxflags" }
    ,   as =    { "asflags"             }
    ,   sc =    { "scflags"             }
    }
    instance._FLAGNAMES = flagnames[sourcekind]

    -- check
    if not instance._FLAGNAMES then
        return nil, string.format("unknown compiler for kind: %s", sourcekind)
    end

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

    -- get flags
    local flags = nil
    if target then
        flags = self:_flags(target)
    end

    -- compile it
    return sandbox.load(self:_tool().compile, sourcefile, objectfile, incdepfile, flags or "")
end

-- get the compile command
function compiler:compcmd(sourcefile, objectfile, target)

    -- get flags
    local flags = nil
    if target then
        flags = self:_flags(target)
    end

    -- get it
    return self:_tool().compcmd(sourcefile, objectfile, flags or "")
end

-- make the symbol flag
function compiler:symbol(level)

    -- make it
    return self:_tool().symbol(level)
end

-- make the language flag
function compiler:language(stdname)

    -- make it
    return self:_tool().language(stdname)
end

-- make the vector extension flag
function compiler:vectorext(extension)

    -- make it
    return self:_tool().vectorext(extension)
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
