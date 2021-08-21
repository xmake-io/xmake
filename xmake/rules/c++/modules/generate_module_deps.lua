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
-- @author      TheVeryDarkness, ruki
-- @file        generate_moduledeps.lua
--

-- imports
                import("core.tool.compiler")
local json    = import("core.base.json")
local builder = import("private.action.build.object")

-- build module files using msvc
function _generate_moduledeps_msvc(target, sourcebatch, opt)

    -- attempt to compile the module files as cxx
    opt = table.join(opt, {configs = {}})
    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = sourcebatch.objectfiles or {}
    sourcebatch.dependfiles = sourcebatch.dependfiles or {}

    function generate_declaration_json(sourcefile)
        local objectfile = target:objectfile(sourcefile)
        local dependfile = target:dependfile(objectfile)
        local modulefile = objectfile .. ".ifc"

        --[[
        local out_dir = modulefile:gsub("[^\\\\/]*$", "")
        print("OUT_DIR = "..out_dir)
        os.mkdir(out_dir)
        ]]

        --[[
        -- Compile module file to *.ifc.d.json
        local ixxfile = sourcefile
        if not sourcefile:endswith(".ixx") then
            ixxfile = sourcefile:gsub("mpp$","ixx")
            ixxfile = ixxfile:gsub("mxx$","ixx")
            ixxfile = ixxfile:gsub("cppm$","ixx")
            if os.exists(ixxfile) then
                local ixx_content = io.readfile(ixxfile)
                local source_content = io.readfile(sourcefile)
                if ixx_content ~= source_content then
                    os.raise("Sorry, \""..sourcefile.."\" should has an extension .ixx, or I won't be able to compile it as a module interface for you. Some info: \n" .. "\n" .. ixxfile .. "\n" .. sourcefile .. "\n" .. ixx_content .. "\n" .. source_content)
                end
            end
            os.cp(sourcefile, ixxfile) -- Make a temp file with .ixx, which is the only extension that cl.exe supports
        end
        local out, err = os.iorunv(target:tool("cxx"), {"/interface", "-nologo", "-c", "/TP", "/EHsc", "-Fo"..objectfile, "/sourceDependencies:directives", "-", ixxfile}, {envs=os.getenvs()})
        print(target:get("includedirs"))
        print(target:get("runenvs"))
        print(target:get_includedirs())
        --os.execv("echo", {out})
        local dependTable = json.decode(out)
        if ixxfile ~= sourcefile then
            os.rm(ixxfile)
        end
        ]]

        -- compile module file to *.ifc.d.json
        -- See https://docs.microsoft.com/en-us/cpp/build/reference/sourcedependencies-directives
        local singlebatch = {sourcekind = "cxx", sourcefiles = {sourcefile}, objectfiles = {objectfile}, dependfiles = {dependfile}}

        local descFile = modulefile .. ".d.json"
        opt.configs.cxxflags = {"/experimental:module", "/interface", "/sourceDependencies:directives " .. descFile, "/TP"}

        builder.build(target, singlebatch, opt)
        --[[]]
    end
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        generate_declaration_json(sourcefile)
    end
end

-- build module files
function main(target, sourcebatch, opt)    -- do compile
    local modulesflag = nil
    local _, toolname = target:tool("cxx")
    local compinst = compiler.load("cxx")
    if toolname:find("clang", 1, true) or toolname:find("gcc", 1, true) then
        if compinst:has_flags("-fmodules") then
            modulesflag = "-fmodules"
        elseif compinst:has_flags("-fmodules-ts") then
            modulesflag = "-fmodules-ts"
        end
    elseif toolname == "cl" then
        if compinst:has_flags("/experimental:module") then
            modulesflag = "/experimental:module"
        end
    end
    if modulesflag then
        opt.modulesflag = modulesflag
        if toolname:find("clang", 1, true) then
            _generate_moduledeps_clang(target, sourcebatch, opt)
        elseif toolname:find("gcc", 1, true) then
            _generate_moduledeps_gcc(target, sourcebatch, opt)
        elseif toolname == "cl" then
            _generate_moduledeps_msvc(target, sourcebatch, opt)
        else
            raise("compiler(%s): does not support c++ module!", toolname)
        end
    end
end