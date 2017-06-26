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
local config    = require("project/config")
local cache     = require("project/cache")
local linker    = require("tool/linker")
local compiler  = require("tool/compiler")
local sandbox   = require("sandbox/sandbox")
local language  = require("language/language")

-- get cache
function option._cache()

    -- get it from cache first if exists
    if option._CACHE then
        return option._CACHE
    end

    -- init cache
    option._CACHE = cache("local.option")

    -- ok
    return option._CACHE
end

-- check link 
function option:_check_link(sourcefile, objectfile, targetfile)

    -- check
    assert(sourcefile and objectfile and targetfile)

    -- update source kinds
    self._SOURCEKINDS = language.sourcekind_of(sourcefile)

    -- load the linker instance
    local instance = linker.load("binary", self._SOURCEKINDS)
    if not instance then 
        return false 
    end

    -- attempt to link it
    return instance:link(objectfile, targetfile, {target = self})
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
    local instance = compiler.load(language.sourcekind_of(srcpath))
    if not instance then 
        return false 
    end

    -- attempt to compile it
    return instance:compile(srcpath, objpath, {target = self})
end

-- check function 
function option:_check_function(checkcode, srcpath, objpath)

    -- check
    assert(checkcode)

    -- open the checking source file
    local srcfile = io.open(srcpath, "w")
    if not srcfile then
        return false 
    end

    -- get source kind
    local sourcekind = language.sourcekind_of(srcpath)

    -- load the compiler instance
    local instance = compiler.load(sourcekind)
    if not instance then 
        return false 
    end

    -- make includes 
    local includes = nil
    if sourcekind == "cc" then includes = self:get("cincludes")
    elseif sourcekind == "cxx" then includes = self:get("cxxincludes") 
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

    -- make check code
    srcfile:print("    %s;", checkcode)

    -- make the main function tailer
    srcfile:print("    return 0;")
    srcfile:print("}")

    -- exit this file
    srcfile:close()

    -- attempt to compile it
    return instance:compile(srcpath, objpath, {target = self})
end

-- check type 
function option:_check_type(typename, srcpath, objpath)

    -- check
    assert(typename)

    -- open the checking source file
    local srcfile = io.open(srcpath, "w")
    if not srcfile then 
        return false 
    end

    -- get source kind
    local sourcekind = language.sourcekind_of(srcpath)

    -- load the compiler instance
    local instance = compiler.load(sourcekind)
    if not instance then 
        return false 
    end

    -- make includes 
    local includes = nil
    if sourcekind == "cc" then includes = self:get("cincludes")
    elseif sourcekind == "cxx" then includes = self:get("cxxincludes") 
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
    srcfile:print("    typedef %s __type_xxx;", typename)

    -- make the main function tailer
    srcfile:print("    return 0;")
    srcfile:print("}")

    -- exit this file
    srcfile:close()

    -- attempt to compile it
    return instance:compile(srcpath, objpath, {target = self})
end

-- check snippet 
function option:_check_snippet(snippet, srcpath, objpath)

    -- check
    assert(snippet)

    -- get source kind
    local sourcekind = language.sourcekind_of(srcpath)

    -- load the compiler instance
    local instance = compiler.load(sourcekind)
    if not instance then 
        return false 
    end

    -- write snippet to source file
    if not io.writefile(srcpath, snippet) then
        return false
    end

    -- attempt to compile it
    return instance:compile(srcpath, objpath, {target = self})
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
    local ok, errors = self:_check_include(nil, cfile, objectfile)

    -- check link
    if ok then ok, errors = self:_check_link(cfile, objectfile, targetfile) end

    -- trace
    utils.cprint("checking for the links %s ... %s", links_str, utils.ifelse(ok, "${green}ok", "${red}no"))
    if not ok and option_.get("verbose") then
        utils.cprint("${red}" .. (errors or ""))
    end

    -- cache the result
    option._CHECKED_LINKS[links_str] = ok

    -- ok?
    return ok
end

-- check option for checking includes
function option:_check_includes(kind, file, objectfile)

    -- done
    for _, include in ipairs(table.wrap(self:get(kind .. "includes"))) do
        
        -- this include has been checked?
        option._CHECKED_INCLUDES = option._CHECKED_INCLUDES or {}
        if option._CHECKED_INCLUDES[include] then return true end
        
        -- check include
        local ok, errors = self:_check_include(include, file, objectfile)

        -- trace
        utils.cprint("checking for the %s include %s ... %s", kind, include, utils.ifelse(ok, "${green}ok", "${red}no"))
        if not ok and option_.get("verbose") then
            utils.cprint("${red}" .. (errors or ""))
        end

        -- cache the result
        option._CHECKED_INCLUDES[include] = ok

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- check option for checking functions
function option:_check_functions(kind, file, objectfile, targetfile)

    -- done
    for _, checkinfo in ipairs(table.wrap(self:get(kind .. "funcs"))) do
        
        -- parse the check code
        local checkname, checkcode = option.checkinfo(checkinfo)
        assert(checkname and checkcode)

        -- check function
        local ok, errors = self:_check_function(checkcode, file, objectfile)

        -- check link
        if ok and self:get("links") then ok, errors = self:_check_link(file, objectfile, targetfile) end

        -- trace
        utils.cprint("checking for the %s function %s ... %s", kind, checkname, utils.ifelse(ok, "${green}ok", "${red}no"))
        if not ok and option_.get("verbose") then
            utils.cprint("${red}" .. (errors or ""))
        end

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- check option for checking types
function option:_check_types(kind, file, objectfile, targetfile)

    -- done
    for _, t in ipairs(table.wrap(self:get(kind .. "types"))) do
        
        -- check type
        local ok, errors = self:_check_type(t, file, objectfile)

        -- trace
        utils.cprint("checking for the %s type %s ... %s", kind, t, utils.ifelse(ok, "${green}ok", "${red}no"))
        if not ok and option_.get("verbose") then
            utils.cprint("${red}" .. (errors or ""))
        end

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- check option for checking snippets
function option:_check_snippets(kind, file, objectfile, targetfile)

    -- done
    for name, snippet in pairs(table.wrap(self:get(kind .. "snippet"))) do
        
        -- check snippet
        local ok, errors = self:_check_snippet(snippet, file, objectfile)

        -- trace
        utils.cprint("checking for the %s snippet %s ... %s", kind, name, utils.ifelse(ok, "${green}ok", "${red}no"))
        if not ok and option_.get("verbose") then
            utils.cprint("${red}" .. (errors or ""))
        end

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- check option 
function option:_check_condition()
 
    -- the files
    local cfile         = os.tmpfile() .. ".c"
    local cxxfile       = os.tmpfile() .. ".cpp"
    local objectfile    = os.tmpfile() .. ".obj"
    local targetfile    = os.tmpfile() .. ".bin"

    -- check links
    if not self:_check_links(cfile, objectfile, targetfile) then return false end

    -- check types
    if not self:_check_types("c", cfile, objectfile, targetfile) then return false end
    if not self:_check_types("cxx", cxxfile, objectfile, targetfile) then return false end

    -- check csnippets
    if not self:_check_snippets("c", cfile, objectfile, targetfile) then return false end
    if not self:_check_snippets("cxx", cxxfile, objectfile, targetfile) then return false end

    -- check includes and functions
    if self:get("cincludes") or self:get("cxxincludes") then

        -- check includes
        if not self:_check_includes("c", cfile, objectfile) then return false end
        if not self:_check_includes("cxx", cxxfile, objectfile) then return false end

        -- check functions
        if not self:_check_functions("c", cfile, objectfile, targetfile) then return false end
        if not self:_check_functions("cxx", cxxfile, objectfile, targetfile) then return false end
    end

    -- remove files
    os.rm(cfile)
    os.rm(cxxfile)
    os.rm(objectfile)
    os.rm(targetfile)

    -- ok
    return true
end

-- attempt to check option 
function option:check(force)

    -- have been checked?
    if self._CHECKED and not force then
        return 
    end

    -- the option name
    local name = self:name()

    -- get default value, TODO: enable will be deprecated
    local default = self:get("default")
    if default == nil then
        default = self:get("enable")
    end

    -- need check? (only force to check the automatical option without the default value)
    if config.get(name) == nil or (default == nil and force) then

        -- use it directly if the default value exists
        if default ~= nil then

            -- save the default value
            config.set(name, default)

            -- save this option to configure 
            self:save()

        -- check option as boolean switch automatically if the default value not exists
        elseif default == nil and self:_check_condition() then

            -- enable this option
            config.set(name, true)

            -- save this option to configure 
            self:save()
        else

            -- disable this option
            config.set(name, false)

            -- clear this option to configure 
            self:clear()
        end

    -- no check
    elseif config.get(name) then

        -- save this option to configure directly
        self:save()
    end    

    -- checked
    self._CHECKED = true
end

-- get the option info
function option:get(infoname)

    -- get it
    return self._INFO[infoname]
end

-- get option deps
function option:deps()
    -- TODO in the future
    return {}
end

-- save the option info to the cache
function option:save()

    -- save it
    option._cache():set(self:name(), self._INFO)
    option._cache():flush()
end

-- clear the option info for cache
function option:clear()

    -- clear it
    option._cache():set(self:name(), nil)
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
    local info = option._cache():get(name)
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

-- get function name and check code
--
-- sigsetjmp
-- sigsetjmp((void*)0, 0)
-- sigsetjmp{sigsetjmp((void*)0, 0);}
-- sigsetjmp{int a = 0; sigsetjmp((void*)a, a);}
--
function option.checkinfo(checkinfo)

    -- parse name and code
    local name, code = string.match(checkinfo, "(.+){(.+)}")
    if code == nil then
        local pos = checkinfo:find("%(")
        if pos then
            name = checkinfo:sub(1, pos - 1)
            code = checkinfo
        else
            name = checkinfo
            code = string.format("volatile void* p%s = (void*)&%s;", name, name)
        end
    end

    -- ok
    return name:trim(), code
end

-- return module
return option
