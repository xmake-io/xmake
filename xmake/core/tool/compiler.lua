--!The Automatic Cross-platform Build Tool
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

-- get the named flags
function compiler:_named_flags(names, flags)

    -- map it 
    local flags_mapped = {}
    for _, name in ipairs(table.wrap(names)) do
        table.join2(flags_mapped, self:_mapflags(flags[name]))
    end

    -- get it
    return flags_mapped
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

    -- add the symbols flags 
    table.join2(flags, self:_named_flags(target:get("symbols"), {   debug       = "-g"
                                                                ,   hidden      = "-fvisibility=hidden"
                                                                }))

    -- add the warning flags 
    table.join2(flags, self:_named_flags(target:get("warnings"),  {     none        = "-w"
                                                                    ,   less        = "-W1"
                                                                    ,   more        = "-W3"
                                                                    ,   all         = "-Wall"
                                                                    ,   error       = "-Werror"
                                                                    }))

    -- add the optimize flags 
    table.join2(flags, self:_named_flags(target:get("optimize"), {      none        = "-O0"
                                                                    ,   fast        = "-O1"
                                                                    ,   faster      = "-O2"
                                                                    ,   fastest     = "-O3"
                                                                    ,   smallest    = "-Os"
                                                                    ,   aggressive  = "-Ofast"
                                                                    }))

    -- add the vector extensions flags 
    table.join2(flags, self:_named_flags(target:get("vectorexts"), {    mmx         = "-mmmx"
                                                                    ,   sse         = "-msse"
                                                                    ,   sse2        = "-msse2"
                                                                    ,   sse3        = "-msse3"
                                                                    ,   ssse3       = "-mssse3"
                                                                    ,   avx         = "-mavx"
                                                                    ,   avx2        = "-mavx2"
                                                                    ,   neon        = "-mfpu=neon"
                                                                    }))

    -- add the language flags 
    local languages = {}
    for _, flagname in ipairs(self:_flagnames()) do
        if flagname == "cflags" or flagname == "mflags" then
            table.join2(languages, {    ansi        = "-ansi"
                                    ,   c89         = "-std=c89"
                                    ,   gnu89       = "-std=gnu89"
                                    ,   c99         = "-std=c99"
                                    ,   gnu99       = "-std=gnu99"
                                    ,   c11         = "-std=c11"
                                    ,   gnu11       = "-std=gnu11"
                                    })
        elseif flagname == "cxxflags" or flagname == "mxxflags" then
            table.join2(languages, {    cxx98       = "-std=c++98"
                                    ,   gnuxx98     = "-std=gnu++98"
                                    ,   cxx11       = "-std=c++11"
                                    ,   gnuxx11     = "-std=gnu++11"
                                    ,   cxx14       = "-std=c++14"
                                    ,   gnuxx14     = "-std=gnu++14"
                                    })
        end
    end
    table.join2(flags, self:_named_flags(target:get("languages"), languages))

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
function compiler.kind_of_file(srcfile)

    -- get the source file type
    local filetype = path.extension(srcfile)
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

-- get the command
function compiler:command(target, srcfile, objfile, logfile)

    -- get it
    return self:_tool().compcmd(srcfile, objfile, self:_flags(target), logfile)
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
    utils.printf("checking for the flags %s ... %s", flags, utils.ifelse(ok, "ok", "no"))
    if not ok then
        utils.verbose(errors)
    end

    -- save the checked result
    self._CHECKED[flags] = ok

    -- ok?
    return ok
end

-- run the command
function compiler:run(...)

    -- the compiler tool
    local ctool = self:_tool()

    -- no run interface?
    if not ctool.run then

        -- run it
        return os.run(...)
    end

    -- run it
    return sandbox.load(ctool.run, ...)
end

-- return module
return compiler
