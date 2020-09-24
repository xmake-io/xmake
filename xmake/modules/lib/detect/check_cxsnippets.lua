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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check_cxsnippets.lua
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
    for _, snippet in pairs(snippets) do
        sourcecode = sourcecode .. "\n" .. snippet
    end
    sourcecode = sourcecode .. "\n"

    -- enter main function
    sourcecode = sourcecode .. "int main(int argc, char** argv)\n{\n"

    -- add funcs
    for _, funcinfo in ipairs(opt.funcs) do
        sourcecode = format("%s\n    %s;", sourcecode, _funccode(funcinfo))
    end

    -- leave main function
    sourcecode = sourcecode .. "\n    return 0;\n}\n"

    -- done
    return sourcecode
end

-- check the given c/c++ snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options
--                  e.g.
--                  { verbose = false, target = [target|option], sourcekind = "[cc|cxx]"
--                  , types = {"wchar_t", "char*"}, includes = "stdio.h", funcs = {"sigsetjmp", "sigsetjmp((void*)0, 0)"}
--                  , configs = {defines = "xx", cxflags = ""}}
--
-- funcs:
--      sigsetjmp
--      sigsetjmp((void*)0, 0)
--      sigsetjmp{sigsetjmp((void*)0, 0);}
--      sigsetjmp{int a = 0; sigsetjmp((void*)a, a);}
--
-- @return          true or false
--
-- @code
-- local ok = check_cxsnippets("void test() {}")
-- local ok = check_cxsnippets({"void test(){}", "#define TEST 1"}, {types = "wchar_t", includes = "stdio.h"})
-- local ok = check_cxsnippets({snippet_name = "void test(){}", "#define TEST 1"}, {types = "wchar_t", includes = "stdio.h"})
-- @endcode
--
function main(snippets, opt)

    -- init options
    opt = opt or {}

    -- init snippets
    snippets = snippets or {}

    -- get configs
    local configs = opt.configs or opt.config

    -- get links
    local links = {}
    if configs and configs.links then
        table.join2(links, configs.links)
    end
    if opt.target then
        table.join2(links, opt.target:get("links"))
    end
    if configs and configs.syslinks then
        table.join2(links, configs.syslinks)
    end
    if opt.target then
        table.join2(links, opt.target:get("syslinks"))
    end

    -- get types
    local types = table.wrap(opt.types)

    -- get includes
    local includes = table.wrap(opt.includes)

    -- get funcs
    local funcs = {}
    for _, funcinfo in ipairs(opt.funcs) do
        table.insert(funcs, _funcname(funcinfo))
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
    local binaryfile = os.tmpfile() .. ".b"
    io.writefile(sourcefile, sourcecode)

    -- @note cannot cache result, all conditions will be changed
    -- attempt to compile it
    local errors = nil
    local ok = try
    {
        function ()
            if option.get("diagnosis") then
                cprint("${dim}> %s", compiler.compcmd(sourcefile, objectfile, opt))
            end
            compiler.compile(sourcefile, objectfile, opt)
            if #links > 0 then
                if option.get("diagnosis") then
                    cprint("${dim}> %s", linker.linkcmd("binary", {"cc", "cxx"}, objectfile, binaryfile, opt))
                end
                linker.link("binary", {"cc", "cxx"}, objectfile, binaryfile, opt)
            end
            return true
        end,
        catch { function (errs) errors = errs end }
    }

    -- remove some files
    os.tryrm(sourcefile)
    os.tryrm(objectfile)
    os.tryrm(binaryfile)

    -- trace
    if opt.verbose or option.get("verbose") or option.get("diagnosis") then
        local kind = opt.sourcekind == "cc" and "c" or "c++"
        if #includes > 0 then
            cprint("${dim}> checking for %s includes(%s)", kind, table.concat(includes, ", "))
        end
        if #types > 0 then
            cprint("${dim}> checking for %s types(%s)", kind, table.concat(types, ", "))
        end
        if #funcs > 0 then
            cprint("${dim}> checking for %s funcs(%s)", kind, table.concat(funcs, ", "))
        end
        if #links > 0 then
            cprint("${dim}> checking for %s links(%s)", kind, table.concat(links, ", "))
        end
        for idx_or_name, snippet in pairs(snippets) do
            local name = idx_or_name
            if type(name) == "number" then
                name = snippet:sub(1, 16)
            end
            cprint("${dim}> checking for %s snippet(%s)", kind, name)
        end
    end
    if errors and option.get("diagnosis") and #tostring(errors) > 0 then
        cprint("${color.warning}checkinfo:${clear dim} %s", errors)
    end

    -- ok?
    return ok
end

