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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: c++.build.modules
rule("c++.build.modules")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx") 
    before_load(function (target)
        --target:add("cxxflags", "-fprebuilt-module-path=")
    end)
    before_build_files(function (target, sourcebatch, opt)

        -- imports
        import("core.tool.compiler")

        -- attempt to compile the module files as cxx
        sourcebatch.sourcekind = "cxx"
        sourcebatch.objectfiles = sourcebatch.objectfiles or {}
        sourcebatch.dependfiles = sourcebatch.dependfiles or {}
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local objectfile = target:objectfile(sourcefile)
            table.insert(sourcebatch.objectfiles, objectfile)
            table.insert(sourcebatch.dependfiles, target:dependfile(objectfile))
        end

        -- do compile
        local compinst = compiler.load("cxx")
        if compinst:name() == "clang" then
            opt.configs = {cxxflags = {"-fmodules-ts", "--precompile"}}
        else
            raise("compiler(%s): does not support module!", compinst:name())
        end
        import("private.action.build.object")(target, sourcebatch, opt)
    end)

