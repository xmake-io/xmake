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
-- @file        has_csnippets.lua
--

-- imports
import("core.base.option")
import("core.tool.linker")
import("core.tool.compiler")
import("core.language.language")

-- get function name 
--
-- sigsetjmp
-- sigsetjmp((void*)0, 0)
-- sigsetjmp{sigsetjmp((void*)0, 0);}
-- sigsetjmp{int a = 0; sigsetjmp((void*)a, a);}
--
function _funcname(funcinfo)

    -- parse function name 
    local name = string.match(funcinfo, "(.+){.+}")
    if name == nil then
        local pos = funcinfo:find("%(")
        if pos then
            name = funcinfo:sub(1, pos - 1)
        else
            name = funcinfo
        end
    end

    -- ok
    return name:trim()
end

-- get function code
--
-- sigsetjmp
-- sigsetjmp((void*)0, 0)
-- sigsetjmp{sigsetjmp((void*)0, 0);}
-- sigsetjmp{int a = 0; sigsetjmp((void*)a, a);}
--
function _funccode(funcinfo)

    -- parse function code
    local code = string.match(funcinfo, ".+{(.+)}")
    if code == nil then
        local pos = funcinfo:find("%(")
        if pos then
            code = funcinfo
        else
            code = string.format("volatile void* p%s = (void*)&%s;", funcinfo, funcinfo)
        end
    end

    -- ok
    return code
end

-- make source code
function _sourcecode(snippets, opt)

    -- add includes
    local sourcecode = ""
    for _, include in ipairs(opt.includes) do
        sourcecode = format("%s\n#include <%s>", sourcecode, include)
    end
    sourcecode = sourcecode .. "\n"

    -- add types
    for _, typename in ipairs(opt.types) do
        sourcecode = format("%s\ntypedef %s __type_%s;", sourcecode, typename, typename:gsub("[^%a]", "_"))
    end
    sourcecode = sourcecode .. "\n"

    -- add snippets
    for _, snippet in ipairs(snippets) do
        sourcecode = sourcecode .. "\n" .. snippet
    end
    sourcecode = sourcecode .. "\n"

    -- enter main function
    sourcecode = sourcecode .. "int main(int argc, char** argv)\n{\n"

    -- add functions
    for _, funcinfo in ipairs(opt.functions) do
        sourcecode = format("%s\n    %s;", _funccode(funcinfo))
    end

    -- leave main function
    sourcecode = sourcecode .. "\n    return 0;\n}\n"

    -- done
    return sourcecode
end

-- has the given c snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options
--                  .e.g 
--                  { name = "", verbose = false, target = [target|option], sourcekind = "[cc|cxx]"
--                  , types = {"wchar_t", "char*"}, includes = "stdio.h", functions = {"sigsetjmp", "sigsetjmp((void*)0, 0)"}
--                  , links = {"pthread", "z"}}
--
-- functions:
--      sigsetjmp
--      sigsetjmp((void*)0, 0)
--      sigsetjmp{sigsetjmp((void*)0, 0);}
--      sigsetjmp{int a = 0; sigsetjmp((void*)a, a);}
--
-- @return          true or false
--
-- @code
-- local ok = has_csnippets("void test() {}")
-- local ok = has_csnippets({"void test(){}", "#define TEST 1"}, {types = "wchar_t", includes = "stdio.h"})
-- @endcode
--
function main(csnippets, opt)

    -- init options
    opt = opt or {}

    -- init cache and key
    local key     = opt.name
    local results = _g._RESULTS or {}
    
    -- get result from the cache first
    if key ~= nil then
        local ok = results[key]
        if ok ~= nil then
            return ok
        end
    end

    -- make source code
    local sourcecode = _sourcecode(snippets, opt)

    -- get c/c++ extension
    local extension = ".c"
    if opt.sourcekind then
        extension = table.wrap(language.sourcekinds()[opt.sourcekind])[1] or ".c"
    end

    -- make the source file
    local sourcefile = os.tmpfile() .. extension
    local objectfile = os.tmpfile() .. ".o"
    io.writefile(sourcefile, sourcecode)

    -- attempt to compile it
    local ok = try
    {
        function () 
            compiler.compile(sourcefile, objectfile, opt)
--            linker.link(objectfile, os.nuldev(), opt.target)
            return true
        end,
        catch 
        {
            function (errors)
                if option.get("verbose") then
                    cprint("${red}%s", errors)
                end
            end
        }
    }

    -- remove some files
    os.tryrm(sourcefile)
    os.tryrm(objectfile)

    -- trace
    if opt.verbose or option.get("verbose") then
        if opt.name then
            cprint("checking for the %s ... %s", opt.name, ifelse(ok, "${green}ok", "${red}no"))
        else
            local kind = ifelse(sourcekind == "cc", "c", "c++")
            for _, include in ipairs(opt.includes) do
                cprint("checking for the %s include %s ... %s", kind, include, ifelse(ok, "${green}ok", "${red}no"))
            end
            for _, typename in ipairs(opt.types) do
                cprint("checking for the %s type %s ... %s", kind, typename, ifelse(ok, "${green}ok", "${red}no"))
            end
            for _, funcinfo in ipairs(opt.functions) do
                cprint("checking for the %s function %s ... %s", kind, _funcname(funcinfo), ifelse(ok, "${green}ok", "${red}no"))
            end
            for _, snippet in ipairs(opt.snippets) do
                cprint("checking for the %s snippet %s ... %s", kind, snippet:sub(1, 16), ifelse(ok, "${green}ok", "${red}no"))
            end
        end
    end

    -- save result to cache
    if key ~= nil then
        results[key] = ifelse(ok, ok, false)
        _g._RESULTS = results
    end

    -- ok?
    return ok
end

