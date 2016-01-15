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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        compiler.lua
--

-- define module: compiler
local compiler = compiler or {}

-- load modules
local io        = require("base/io")
local path      = require("base/path")
local rule      = require("base/rule")
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local config    = require("base/config")
local tools     = require("tools/tools")
local platform  = require("base/platform")

-- map gcc flag to the given compiler flag
function compiler._mapflag(module, flag)

    -- check
    assert(module.mapflags and flag)

    -- attempt to map it directly
    local flag_mapped = module.mapflags[flag]
    if flag_mapped and type(flag_mapped) == "string" then
        return flag_mapped
    end

    -- find and replace it using pattern
    for k, v in pairs(module.mapflags) do
        local flag_mapped, count = flag:gsub("^" .. k .. "$", function (w) 
                                                    if type(v) == "function" then
                                                        return v(module, w)
                                                    else
                                                        return v
                                                    end
                                                end)
        if flag_mapped and count ~= 0 then
            return utils.ifelse(#flag_mapped ~= 0, flag_mapped, nil) 
        end
    end

    -- return it directly
    return flag
end

-- map gcc flags to the given compiler flags
function compiler._mapflags(module, flags)

    -- check
    assert(module)

    -- wrap flags first
    flags = utils.wrap(flags)

    -- need not map flags? return it directly
    if not module.mapflags then
        return flags
    end

    -- map flags
    local flags_mapped = {}
    for _, flag in pairs(flags) do
        -- map it
        local flag_mapped = compiler._mapflag(module, flag)
        if flag_mapped then
            table.insert(flags_mapped, flag_mapped)
        end
    end

    -- ok?
    return flags_mapped
end

-- get the compiler flags from names
function compiler._getflags(module, names, flags)

    -- check
    assert(flags)

    -- the mapped flags
    local flags_mapped = {}

    -- wrap it first
    names = utils.wrap(names)
    for _, name in ipairs(names) do
        table.join2(flags_mapped, compiler._mapflags(module, flags[name]))
    end

    -- get it
    return flags_mapped
end

-- add flags from the compiler 
function compiler._addflags_from_compiler(module, flags, flagnames, kind)

    -- check
    assert(module and flags and flagnames)

    -- done
    for _, flagname in ipairs(flagnames) do

        -- add compiler.xxflags
        table.join2(flags, module, module[flagname])

        -- add compiler.kind.xxflags
        if kind ~= nil and module[kind] ~= nil then
            table.join2(flags, module, module[kind][flagname])
        end
    end
end

-- add flags from the configure 
function compiler._addflags_from_config(module, flags, flagnames)

    -- check
    assert(module and flags and flagnames)

    -- done
    for _, flagname in ipairs(flagnames) do
        table.join2(flags, config.get(flagname))
    end
end

-- add flags from the platform 
function compiler._addflags_from_platform(module, flags, flagnames)

    -- check
    assert(module and flags and flagnames)

    -- add flags 
    for _, flagname in ipairs(flagnames) do
        table.join2(flags, compiler._mapflags(module, platform.get(flagname)))
    end

    -- add the includedirs flags
    if module.flag_includedir then
        for _, includedir in ipairs(utils.wrap(platform.get("includedirs"))) do
            table.join2(flags, module:flag_includedir(includedir))
        end
    end

    -- add the defines flags 
    if module.flag_define then
        for _, define in ipairs(utils.wrap(platform.get("defines"))) do
            table.join2(flags, module:flag_define(define))
        end
    end

    -- append the undefines flags
    if module.flag_undefine then
        for _, undefine in ipairs(utils.wrap(platform.get("undefines"))) do
            table.join2(flags, module:flag_undefine(undefine))
        end
    end
end


-- add flags from the target 
function compiler._addflags_from_target(module, flags, flagnames, target)

    -- check
    assert(module and flags and flagnames and target)

    -- add the target flags from the current project
    for _, flagname in ipairs(flagnames) do
        table.join2(flags, compiler._mapflags(module, target[flagname]))
    end

    -- add the symbols flags from the current project
    table.join2(flags, compiler._getflags(module, target.symbols, {     debug       = "-g"
                                                                    ,   hidden      = "-fvisibility=hidden"
                                                                    }))

    -- add the warning flags from the current project
    table.join2(flags, compiler._getflags(module, target.warnings,  {   none        = "-w"
                                                                    ,   less        = "-W1"
                                                                    ,   more        = "-W3"
                                                                    ,   all         = "-Wall"
                                                                    ,   error       = "-Werror"
                                                                    }))
 
    -- add the optimize flags from the current project
    table.join2(flags, compiler._getflags(module, target.optimize, {    none        = "-O0"
                                                                    ,   fast        = "-O1"
                                                                    ,   faster      = "-O2"
                                                                    ,   fastest     = "-O3"
                                                                    ,   smallest    = "-Os"
                                                                    ,   aggressive  = "-Ofast"
                                                                    }))
 
    -- add the vector extensions flags from the current project
    table.join2(flags, compiler._getflags(module, target.vectorexts, {      mmx         = "-mmmx"
                                                                        ,   sse         = "-msse"
                                                                        ,   sse2        = "-msse2"
                                                                        ,   sse3        = "-msse3"
                                                                        ,   ssse3       = "-mssse3"
                                                                        ,   avx         = "-mavx"
                                                                        ,   avx2        = "-mavx2"
                                                                        ,   neon        = "-mfpu=neon"
                                                                        }))

    -- add the language flags from the current project
    local languages = {}
    for _, flagname in ipairs(flagnames) do
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
    table.join2(flags, compiler._getflags(module, target.languages, languages))

    -- add the includedirs flags from the current project
    if module.flag_includedir then
        for _, includedir in ipairs(utils.wrap(target.includedirs)) do
            table.join2(flags, module:flag_includedir(includedir))
        end
    end

    -- add the defines flags from the current project
    if module.flag_define then
        for _, define in ipairs(utils.wrap(target.defines)) do
            table.join2(flags, module:flag_define(define))
        end
    end

    -- append the undefines flags from the current project
    if module.flag_undefine then
        for _, undefine in ipairs(utils.wrap(target.undefines)) do
            table.join2(flags, module:flag_undefine(undefine))
        end
    end

    -- the options
    if target.options then
        for _, name in ipairs(utils.wrap(target.options)) do

            -- get option if be enabled
            local opt = nil
            if config.get(name) then opt = config.get("__" .. name) end
            if nil ~= opt then

                -- add the flags from the option
                compiler._addflags_from_target(module, flags, flagnames, opt)

                -- append the defines flags
                if opt.defines_if_ok and module.flag_define then
                    local defines = utils.wrap(opt.defines_if_ok)
                    for _, define in ipairs(defines) do
                        table.join2(flags, module:flag_define(define))
                    end
                end

                -- append the undefines flags 
                if opt.undefines_if_ok and module.flag_undefine then
                    local undefines = utils.wrap(opt.undefines_if_ok)
                    for _, undefine in ipairs(undefines) do
                        table.join2(flags, module:flag_undefine(undefine))
                    end
                end
            end
        end
    end
end

-- add flags from the option 
function compiler._addflags_from_option(module, flags, flagnames, opt)

    -- check
    assert(module and flags and flagnames and opt)

    -- add the flags from the option
    compiler._addflags_from_target(module, flags, flagnames, opt)

end

-- get the flag names from the given compiler name
function compiler._flagnames(name)

    -- check
    assert(name)

    -- the flag names
    local flagnames = nil
    if name == "cc"         then flagnames = { "cxflags", "cflags"      }
    elseif name == "cxx"    then flagnames = { "cxflags", "cxxflags"    }
    elseif name == "mm"     then flagnames = { "mxflags", "mflags"      } 
    elseif name == "mxx"    then flagnames = { "mxflags", "mxxflags"    }
    elseif name == "as"     then flagnames = { "asflags"                }
    elseif name == "sc"     then flagnames = { "scflags"                }
    else
        -- error
        utils.error("unknown compiler: %s", name)
        return 
    end

    -- ok
    return flagnames
end

-- get the compiler kind from the source file type
function compiler._kind(srcfile)

    -- get the source file type
    local filetype = path.extension(srcfile)
    if not filetype then
        return nil
    end

    -- get the lower file type
    filetype = filetype:lower()

    -- get the compiler kind
    local kind = nil
    if filetype == ".c" then kind = "cc"
    elseif filetype == ".cpp" or filetype == ".cc" then kind = "cxx"
    elseif filetype == ".m" then kind = "mm"
    elseif filetype == ".mm" then kind = "mxx"
    elseif filetype == ".s" or filetype == ".asm" then kind = "as"
    elseif filetype == ".swift" then kind = "sc"
    elseif filetype == ".a" or filetype == ".lib" then kind = "lib"
    elseif filetype == ".o" or filetype == ".obj" then kind = "obj"
    end
    
    -- ok
    return kind
end
    
-- make the compile command for option
function compiler._make_for_option(module, opt, srcfile, objfile, logfile)

    -- check
    assert(module and opt)

    -- the flag names
    local flagnames = compiler._flagnames(module._KIND)
    assert(flagnames)

    -- init flags
    local flags = {}

    -- add flags from the configure 
    compiler._addflags_from_config(module, flags, flagnames)

    -- add flags from the option 
    compiler._addflags_from_option(module, flags, flagnames, opt)

    -- add flags from the platform 
    compiler._addflags_from_platform(module, flags, flagnames)

    -- add flags from the compiler 
    compiler._addflags_from_compiler(module, flags, flagnames)

    -- remove repeat
    flags = utils.unique(flags)

    -- execute the compile command
    return module:command_compile(srcfile, objfile, table.concat(flags, " "):trim(), logfile)
end

-- get the compiler from the given source file
function compiler.get(srcfile)

    -- get the compiler kind
    local kind = compiler._kind(srcfile)
    if not kind then
        return nil, string.format("unknown source file: %s", srcfile)
    end

    -- ignore "*.a/lib" and "*.o/obj" kind
    if kind == "lib" or kind == "obj" then
        return {}
    end

    -- get compiler from the source file type
    local module = tools.get(kind)
    if module then 
        
        -- invalid compiler
        if not module.command_compile then
            return nil, string.format("invalid compiler for %s", kind)
        end

        -- save kind 
        module._KIND = kind 
    else
        return nil, string.format("unknown compiler for %s", kind)
    end

    -- ok?
    return module
end

-- make the compile command
function compiler.make(module, target, srcfile, objfile, logfile)

    -- check
    assert(module and target)

    -- the flag names
    local flagnames = compiler._flagnames(module._KIND)
    assert(flagnames)

    -- init flags 
    local flags = {}

    -- add flags from the configure 
    compiler._addflags_from_config(module, flags, flagnames)

    -- add flags from the target 
    compiler._addflags_from_target(module, flags, flagnames, target)

    -- add flags from the platform 
    compiler._addflags_from_platform(module, flags, flagnames)

    -- add flags from the compiler 
    compiler._addflags_from_compiler(module, flags, flagnames, target.kind)

    -- remove repeat
    flags = utils.unique(flags)

    -- make the compile command
    return module:command_compile(srcfile, objfile, table.concat(flags, " "):trim(), logfile)
end

-- check include for the project option
function compiler.check_include(opt, include, srcpath, objpath)

    -- check
    assert(opt and srcpath and objpath)

    -- open the checking source file
    local srcfile = io.openmk(srcpath)
    if not srcfile then return end

    -- make include
    if include then
        srcfile:write(string.format("#include <%s>\n\n", include))
    end

    -- make the main function header
    srcfile:write("int main(int argc, char** argv)\n")
    srcfile:write("{\n")
    srcfile:write("    return 0;\n")
    srcfile:write("}\n")

    -- exit this file
    srcfile:close()

    -- get the compiler
    local module = compiler.get(srcpath)
    if not module then return end

    -- execute the compile command
    return module:main(compiler._make_for_option(module, opt, srcpath, objpath, utils.ifelse(xmake._OPTIONS.verbose, nil, xmake._NULDEV)))
end

-- check function for the project option
function compiler.check_function(opt, interface, srcpath, objpath)

    -- check
    assert(opt and interface)

    -- open the checking source file
    local srcfile = io.openmk(srcpath)
    if not srcfile then return end

    -- get the compiler
    local module = compiler.get(srcpath)
    if not module then return end

    -- make includes 
    local includes = nil
    if module._KIND == "cc" then includes = opt.cincludes
    elseif module._KIND == "cxx" then includes = opt.cxxincludes 
    end
    if includes then
        for _, include in ipairs(utils.wrap(includes)) do
            srcfile:write(string.format("#include <%s>\n", include))
        end
        srcfile:write("\n")
    end

    -- make the main function header
    srcfile:write("int main(int argc, char** argv)\n")
    srcfile:write("{\n")

    -- make interfaces
    srcfile:write(string.format("    volatile void* p%s = (void*)&%s;\n\n", interface, interface))

    -- make the main function tailer
    srcfile:write("    return 0;\n")
    srcfile:write("}\n")

    -- exit this file
    srcfile:close()

    -- execute the compile command
    return module:main(compiler._make_for_option(module, opt, srcpath, objpath, utils.ifelse(xmake._OPTIONS.verbose, nil, xmake._NULDEV)))
end

-- check typedef for the project option
function compiler.check_typedef(opt, typedef, srcpath, objpath)

    -- check
    assert(opt and typedef)

    -- open the checking source file
    local srcfile = io.openmk(srcpath)
    if not srcfile then return end

    -- get the compiler
    local module = compiler.get(srcpath)
    if not module then return end

    -- make includes 
    local includes = nil
    if module._KIND == "cc" then includes = opt.cincludes
    elseif module._KIND == "cxx" then includes = opt.cxxincludes 
    end
    if includes then
        for _, include in ipairs(utils.wrap(includes)) do
            srcfile:write(string.format("#include <%s>\n", include))
        end
        srcfile:write("\n")
    end

    -- make the main function header
    srcfile:write("int main(int argc, char** argv)\n")
    srcfile:write("{\n")

    -- make interfaces
    srcfile:write(string.format("    typedef %s __type_xxx;\n\n", typedef))

    -- make the main function tailer
    srcfile:write("    return 0;\n")
    srcfile:write("}\n")

    -- exit this file
    srcfile:close()

    -- execute the compile command
    return module:main(compiler._make_for_option(module, opt, srcpath, objpath, utils.ifelse(xmake._OPTIONS.verbose, nil, xmake._NULDEV)))
end

-- return module: compiler
return compiler
