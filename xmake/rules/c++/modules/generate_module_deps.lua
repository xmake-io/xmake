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
local flag    = import("get_module_flags")
local json    = import("core.base.json")
local builder = import("private.action.build.object")
                import("core.tool.compiler")

function _generate_moduledeps_clang(target, sourcebatch, opt)
end

function _generate_moduledeps_gcc(target, sourcebatch, opt)
end

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

        -- compile module file to *.ifc.d.json
        -- See https://docs.microsoft.com/en-us/cpp/build/reference/sourcedependencies-directives
        local singlebatch = {sourcekind = "cxx", sourcefiles = {sourcefile}, objectfiles = {objectfile}, dependfiles = {dependfile}}

        local descFile = modulefile .. ".d.json"
        opt.configs.cxxflags = {opt.interfaceflag, "/sourceDependencies:directives " .. descFile, "/TP"}

        if sourcefile:endswith(".mxx") or sourcefile:endswith(".mpp") or sourcefile:endswith(".ixx") or sourcefile:endswith(".cppm") then
            builder.build(target, singlebatch, opt)
        end
        --builder.build(target, singlebatch, opt)
        --[[]]
    end
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        generate_declaration_json(sourcefile)
    end
end

-- build module interface files
function main(target, sourcebatch, opt)    -- do compile
    local _, toolname = target:tool("cxx")
    local compinst = compiler.load("cxx")
    flag.get_module_flags(compinst, toolname, opt)

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