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
-- @file        option.lua
--

-- define module
local option = option or {}

-- load modules
local io        = require("base/io")
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local option_   = require("base/option")
local cache     = require("project/cache")("local.option")
local linker    = require("tool/linker")
local compiler  = require("tool/compiler")

-- check link 
function option:_check_link(sourcefile, objectfile, targetfile)

    -- check
    assert(sourcefile and objectfile and targetfile)

    -- update source kinds
    self._SOURCEKINDS = compiler.kind_of_file(sourcefile)

    -- load the linker instance
    local instance = linker.load("binary")
    if not instance then 
        return false 
    end

    -- attempt to run this command
    local ok, errors = instance:run(instance:command(self, objectfile, targetfile))
    if not ok and option_.get("verbose") then
        print(errors)
    end

    -- ok?
    return ok
end

-- check include 
function option:_check_include(include, srcpath, objpath)

    -- check
    assert(srcpath and objpath)

    -- open the checking source file
    local srcfile = io.open(srcpath, "w")
    if not srcfile then 
        return false
    end

    -- make include
    if include then
        srcfile:print("#include <%s>\n", include)
    end

    -- make the main function header
    srcfile:print("int main(int argc, char** argv)")
    srcfile:print("{")
    srcfile:print("    return 0;")
    srcfile:print("}")

    -- exit this file
    srcfile:close()

    -- load the compiler instance
    local instance = compiler.load(compiler.kind_of_file(srcpath))
    if not instance then 
        return false 
    end

    -- attempt to run this command
    local ok, errors = instance:run(instance:command(self, srcpath, objpath))
    if not ok and option_.get("verbose") then
        print(errors)
    end

    -- ok?
    return ok
end

-- check function 
function option:_check_function(interface, srcpath, objpath)

    -- check
    assert(interface)

    -- open the checking source file
    local srcfile = io.open(srcpath, "w")
    if not srcfile then
        return false 
     end

    -- load the compiler instance
    local instance = compiler.load(compiler.kind_of_file(srcpath))
    if not instance then 
        return false 
    end

    -- make includes 
    local includes = nil
    if instance:kind() == "cc" then includes = self:get("cincludes")
    elseif instance:kind() == "cxx" then includes = self:get("cxxincludes") 
    end
    if includes then
        for _, include in ipairs(table.wrap(includes)) do
            srcfile:print("#include <%s>", include)
        end
        srcfile:print("")
    end

    -- make the main function header
    srcfile:print("int main(int argc, char** argv)")
    srcfile:print("{")

    -- make interfaces
    srcfile:print("    volatile void* p%s = (void*)&%s;\n", interface, interface)

    -- make the main function tailer
    srcfile:print("    return 0;")
    srcfile:print("}")

    -- exit this file
    srcfile:close()

    -- execute the compile command
    local ok, errors = instance:run(instance:command(self, srcpath, objpath))
    if not ok and option_.get("verbose") then
        print(errors)
    end

    -- ok?
    return ok
end

-- check typedef 
function option:_check_typedef(typedef, srcpath, objpath)

    -- check
    assert(typedef)

    -- open the checking source file
    local srcfile = io.open(srcpath, "w")
    if not srcfile then 
        return false 
    end

    -- load the compiler instance
    local instance = compiler.load(compiler.kind_of_file(srcpath))
    if not instance then 
        return false 
    end

    -- make includes 
    local includes = nil
    if instance:kind() == "cc" then includes = self:get("cincludes")
    elseif instance:kind() == "cxx" then includes = self:get("cxxincludes") 
    end
    if includes then
        for _, include in ipairs(table.wrap(includes)) do
            srcfile:print("#include <%s>", include)
        end
        srcfile:print("")
    end

    -- make the main function header
    srcfile:print("int main(int argc, char** argv)")
    srcfile:print("{")

    -- make interfaces
    srcfile:print("    typedef %s __type_xxx;\n", typedef)

    -- make the main function tailer
    srcfile:print("    return 0;")
    srcfile:print("}")

    -- exit this file
    srcfile:close()

    -- execute the compile command
    local ok, errors = instance:run(instance:command(self, srcpath, objpath))
    if not ok and option_.get("verbose") then
        print(errors)
    end

    -- ok?
    return ok
end

-- check option for checking links
function option:_check_links(cfile, objectfile, targetfile)

    -- get links
    local links = self:get("links")
    if not links then
        return true
    end

    -- the links string
    local links_str = table.concat(table.wrap(links), ", ")
    
    -- this links has been checked?
    option._CHECKED_LINKS = option._CHECKED_LINKS or {}
    if option._CHECKED_LINKS[links_str] then 
        return true 
    end
    
    -- only for compile a object file
    local ok = self:_check_include(nil, cfile, objectfile)

    -- check link
    if ok then ok = self:_check_link(cfile, objectfile, targetfile) end

    -- trace
    utils.printf("checking for the links %s ... %s", links_str, utils.ifelse(ok, "ok", "no"))

    -- cache the result
    option._CHECKED_LINKS[links_str] = ok

    -- ok?
    return ok
end

-- check option for checking cincludes
function option:_check_cincludes(cfile, objectfile)

    -- done
    for _, cinclude in ipairs(table.wrap(self:get("cincludes"))) do
        
        -- this cinclude has been checked?
        option._CHECKED_CINCLUDES = option._CHECKED_CINCLUDES or {}
        if option._CHECKED_CINCLUDES[cinclude] then return true end
        
        -- check cinclude
        local ok = self:_check_include(cinclude, cfile, objectfile)

        -- trace
        utils.printf("checking for the c include %s ... %s", cinclude, utils.ifelse(ok, "ok", "no"))

        -- cache the result
        option._CHECKED_CINCLUDES[cinclude] = ok

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- check option for checking cxxincludes
function option:_check_cxxincludes(cxxfile, objectfile)

    -- done
    for _, cxxinclude in ipairs(table.wrap(self:get("cxxincludes"))) do
         
        -- this cxxinclude has been checked?
        option._CHECKED_CXXINCLUDES = option._CHECKED_CXXINCLUDES or {}
        if option._CHECKED_CXXINCLUDES[cinclude] then return true end
        
        -- check cinclude
        local ok = self:_check_include(cxxinclude, cxxfile, objectfile)

        -- trace
        utils.printf("checking for the c++ include %s ... %s", cxxinclude, utils.ifelse(ok, "ok", "no"))

        -- cache the result
        option._CHECKED_CXXINCLUDES[cxxinclude] = ok

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- check option for checking cfunctions
function option:_check_cfuncs(cfile, objectfile, targetfile)

    -- done
    for _, cfunc in ipairs(table.wrap(self:get("cfuncs"))) do
        
        -- check function
        local ok = self:_check_function(cfunc, cfile, objectfile)

        -- check link
        if ok and self:get("links") then ok = self:_check_link(cfile, objectfile, targetfile) end

        -- trace
        utils.printf("checking for the c function %s ... %s", cfunc, utils.ifelse(ok, "ok", "no"))

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- check option for checking cxxfunctions
function option:_check_cxxfuncs(cxxfile, objectfile, targetfile)

    -- done
    for _, cxxfunc in ipairs(table.wrap(self:get("cxxfuncs"))) do
        
        -- check function
        local ok = self:_check_function(cxxfunc, cxxfile, objectfile)

        -- check link
        if ok and self:get("links") then ok = self:_check_link(cxxfile, objectfile, targetfile) end

        -- trace
        utils.printf("checking for the c++ function %s ... %s", cxxfunc, utils.ifelse(ok, "ok", "no"))

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- check option for checking ctypes
function option:_check_ctypes(cfile, objectfile, targetfile)

    -- done
    for _, ctype in ipairs(table.wrap(self:get("ctypes"))) do
        
        -- check type
        local ok = self:_check_typedef(ctype, cfile, objectfile)

        -- trace
        utils.printf("checking for the c type %s ... %s", ctype, utils.ifelse(ok, "ok", "no"))

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- check option for checking cxxtypes
function option:_check_cxxtypes(cxxfile, objectfile, targetfile)

    -- done
    for _, cxxtype in ipairs(table.wrap(self:get("cxxtypes"))) do
        
        -- check type
        local ok = self:_check_typedef(cxxtype, cxxfile, objectfile)

        -- trace
        utils.printf("checking for the c++ type %s ... %s", cxxtype, utils.ifelse(ok, "ok", "no"))

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- check option 
function option:check(cfile, cxxfile, objectfile, targetfile)

    -- check links
    if not self:_check_links(cfile, objectfile, targetfile) then return false end

    -- check ctypes
    if not self:_check_ctypes(cfile, objectfile, targetfile) then return false end

    -- check cxxtypes
    if not self:_check_cxxtypes(cxxfile, objectfile, targetfile) then return false end

    -- check includes and functions
    if self:get("cincludes") or self:get("cxxincludes") then

        -- check cincludes
        if not self:_check_cincludes(cfile, objectfile) then return false end

        -- check cxxincludes
        if not self:_check_cxxincludes(cxxfile, objectfile) then return false end

        -- check cfuncs
        if not self:_check_cfuncs(cfile, objectfile, targetfile) then return false end

        -- check cxxfuncs
        if not self:_check_cxxfuncs(cxxfile, objectfile, targetfile) then return false end

    end

    -- ok
    return true
end

-- get the option info
function option:get(infoname)

    -- get it
    return self._INFO[infoname]
end

-- save the option info to the cache
function option:save(is_clear)

    -- save it
    cache:set(self:name(), self._INFO)
    cache:flush()
end

-- clear the option info for cache
function option:clear()

    -- clear it
    cache:set(self:name(), nil)
end

-- get the option name
function option:name()

    -- get it
    return self._NAME
end

-- load the option info from the cache
function option.load(name)

    -- check
    assert(name)

    -- get info
    local info = cache:get(name)
    if info == nil then
        return 
    end

    -- init option instance
    local instance = table.inherit(option)
    instance._INFO = info
    instance._NAME = name

    -- ok
    return instance
end

-- get the kinds of sourcefiles
function option:sourcekinds()

    -- cached? return it directly
    if self._SOURCEKINDS then
        return self._SOURCEKINDS
    end

    -- ok?
    return {"cc", "cxx"} 
end

-- return module
return option
