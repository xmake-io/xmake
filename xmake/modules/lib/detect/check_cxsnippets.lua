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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
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
    local includes = table.wrap(opt.includes)
    if opt.tryrun and opt.output then
        table.insert(includes, "stdio.h")
    end
    for _, include in ipairs(includes) do
        sourcecode = format("%s\n#include <%s>", sourcecode, include)
    end
    sourcecode = sourcecode .. "\n"

    -- add types
    for _, typename in ipairs(opt.types) do
        sourcecode = format("%s\ntypedef %s __type_%s;", sourcecode, typename, typename:gsub("[^%a]", "_"))
    end
    sourcecode = sourcecode .. "\n"

    -- add snippets (build only)
    if not opt.tryrun then
        for _, snippet in pairs(snippets) do
            sourcecode = sourcecode .. "\n" .. snippet
        end
        sourcecode = sourcecode .. "\n"
    end

    -- enter main function
    sourcecode = sourcecode .. "int main(int argc, char** argv)\n{\n"

    -- add funcs
    for _, funcinfo in ipairs(opt.funcs) do
        sourcecode = format("%s\n    %s;", sourcecode, _funccode(funcinfo))
    end

    -- add snippets (tryrun)
    if opt.tryrun then
        for _, snippet in pairs(snippets) do
            sourcecode = sourcecode .. "\n" .. snippet
        end
        if opt.output then
            sourcecode = sourcecode .. "\nfflush(stdout);\n"
        end
        sourcecode = sourcecode .. "\n}\n" -- we need return exit code in snippet
    else
        -- leave main function
        sourcecode = sourcecode .. "\n    return 0;\n}\n"
    end
    return sourcecode
end

-- check the given c/c++ snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options
--                  e.g.
--                  { verbose = false, target = [target|option], sourcekind = "[cc|cxx]"
--                  , types = {"wchar_t", "char*"}, includes = "stdio.h", funcs = {"sigsetjmp", "sigsetjmp((void*)0, 0)"}
--                  , configs = {defines = "xx", cxflags = ""}
--                  , tryrun = true, output = true}
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
-- local ok, output_or_errors = check_cxsnippets("void test() {}")
-- local ok, output_or_errors = check_cxsnippets({"void test(){}", "#define TEST 1"}, {types = "wchar_t", includes = "stdio.h"})
-- local ok, output_or_errors = check_cxsnippets({snippet_name = "void test(){}", "#define TEST 1"}, {types = "wchar_t", includes = "stdio.h"})
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
    local target = opt.target
    if configs and configs.links then
        table.join2(links, configs.links)
    end
    if target and target:type() ~= "package" then
        table.join2(links, target:get("links"))
    end
    if configs and configs.syslinks then
        table.join2(links, configs.syslinks)
    end
    if target and target:type() ~= "package" then
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
    -- @note we use fixed temporary filenames in order to better cache the compilation results for build_cache.
    local tmpfile = os.tmpfile(sourcecode)
    local sourcefile = tmpfile .. extension
    local objectfile = os.tmpfile() .. ".o"
    local binaryfile = objectfile:gsub("%.o$", ".b")
    if not os.isfile(sourcefile) then
        io.writefile(sourcefile, sourcecode)
    end

    -- @note cannot cache result, all conditions will be changed
    -- attempt to compile it
    local errors = nil
    local ok, output = try
    {
        function ()
            if option.get("diagnosis") then
                cprint("${dim}> %s", compiler.compcmd(sourcefile, objectfile, opt))
            end
            compiler.compile(sourcefile, objectfile, opt)
            if #links > 0 or opt.tryrun then
                if option.get("diagnosis") then
                    cprint("${dim}> %s", linker.linkcmd("binary", {"cc", "cxx"}, objectfile, binaryfile, opt))
                end
                linker.link("binary", {"cc", "cxx"}, objectfile, binaryfile, opt)
            end
            if opt.tryrun then
                if opt.output then
                    local output = os.iorun(binaryfile)
                    if output then
                        output = output:trim()
                    end
                    return true, output
                else
                    os.vrun(binaryfile)
                end
            end
            return true
        end,
        catch { function (errs) errors = errs end }
    }

    -- remove some files
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
    return ok, ok and output or errors
end

