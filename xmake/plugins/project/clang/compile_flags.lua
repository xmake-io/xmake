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
-- @author      luzhlon
-- @file        compile_flags.lua
--

-- imports
import("core.tool.compiler")
import("core.project.project")
import("core.language.language")

-- make the object
function _make_object(target, flags, sourcefile, objectfile)

    -- get the source file kind
    local sourcekind = language.sourcekind_of(sourcefile)

    -- get compile arguments
    local arguments = compiler.compflags(sourcefile, {target = target})
    for i, flag in ipairs(arguments) do
        -- only export the -I*/-D* flags
        if flag == "-I" or flag == "/I" or flag == "-isystem" then
            table.insert(flags, flag .. arguments[i + 1])
        elseif flag:find('^-[ID]') or flag:find("-isystem", 1, true) then
            table.insert(flags, flag)
        end
    end

    -- clear first line marks
    _g.firstline = false
end

-- make objects
function _make_objects(target, flags, sourcekind, sourcebatch)
    for index, objectfile in ipairs(sourcebatch.objectfiles) do
        _make_object(target, flags, sourcebatch.sourcefiles[index], objectfile)
    end
end

-- make target
function _make_target(target, flags)

    -- TODO
    -- disable precompiled header first
    target:set("pcheader", nil)
    target:set("pcxxheader", nil)

    -- build source batches
    for _, sourcebatch in pairs(target:sourcebatches()) do
        local sourcekind = sourcebatch.sourcekind
        if sourcekind then
            _make_objects(target, flags, sourcekind, sourcebatch)
        end
    end
end

-- make all
function _make_all(flags)
    _g.firstline = true
    for _, target in pairs(project.targets()) do
        if not target:is_phony() and target:is_default() then
            _make_target(target, flags)
        end
    end
    return table.unique(flags)
end

-- generate compilation databases for clang-based tools(compile_flags.txt)
--
-- references:
--  - https://clang.llvm.org/docs/JSONCompilationDatabase.html
--
function make(outputdir)

    -- enter project directory
    local oldir = os.cd(os.projectdir())

    -- make all
    local flags = {}
    flags = _make_all(flags)

    -- write to file
    local flagfile = io.open(path.join(outputdir, "compile_flags.txt"), "w")
    for i, flag in ipairs(flags) do
        flagfile:write(flag, '\n')
    end
    flagfile:close()

    -- leave project directory
    os.cd(oldir)
end
