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
-- @file        check_fcsnippets.lua
--

-- imports
import("core.base.option")
import("core.tool.linker")
import("core.tool.compiler")

-- make source code
function _sourcecode(snippets, opt)
    local sourcecode = ""
    for _, snippet in pairs(snippets) do
        sourcecode = sourcecode .. "\n" .. snippet
    end
    sourcecode = sourcecode .. "\n"
    return sourcecode
end

-- check the given fortran snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options
--                  e.g.
--                  { verbose = false, target = [target|option], linkerkind = "fc", "cxx"
--                  , configs = {defines = "xx", fcflags = ""}
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
-- local ok, output_or_errors = check_fcsnippets([[
-- program hello
--  print *, "Hello World!"
-- end program hello
--  ]], {tryrun = true})
-- @endcode
--
function main(snippets, opt)
    opt = opt or {}
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

    -- make source code
    local sourcecode = _sourcecode(snippets, opt)

    -- make the source file
    -- @note we use fixed temporary filenames in order to better cache the compilation results for build_cache.
    local tmpfile = os.tmpfile(sourcecode)
    local sourcefile = tmpfile .. ".f90"
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
            opt = table.clone(opt)
            opt.build_warnings = false
            compiler.compile(sourcefile, objectfile, opt)
            local linkerkind = opt.linkerkind or "fc"
            if #links > 0 or opt.tryrun or opt.binary_match then
                if option.get("diagnosis") then
                    cprint("${dim}> %s", linker.linkcmd("binary", linkerkind, objectfile, binaryfile, opt))
                end
                linker.link("binary", linkerkind, objectfile, binaryfile, opt)
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
            local binary_match = opt.binary_match
            if binary_match then
                local content = io.readfile(binaryfile, {encoding = "binary"})
                local match = type(binary_match) == "function" and binary_match(content) or content:match(binary_match)
                if match ~= nil then
                    return true, match
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
        if #links > 0 then
            cprint("${dim}> checking for fortran links(%s)", table.concat(links, ", "))
        end
        for idx_or_name, snippet in pairs(snippets) do
            local name = idx_or_name
            if type(name) == "number" then
                name = snippet:sub(1, 16)
            end
            cprint("${dim}> checking for fortran snippet(%s)", name)
        end
    end
    if errors and option.get("diagnosis") and #tostring(errors) > 0 then
        cprint("${color.warning}checkinfo:${clear dim} %s", errors)
    end
    return ok, ok and output or errors
end

