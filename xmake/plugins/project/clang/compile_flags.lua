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
-- @author      luzhlon
-- @file        compile_flags.lua
--

-- imports
import("core.tool.compiler")
import("core.project.project")
import("core.language.language")

-- make the object
function _make_object(target, sourcefile, objectfile)

    -- get the source file kind
    local sourcekind = language.sourcekind_of(sourcefile)

    -- make the object for the *.o/obj? ignore it directly
    if sourcekind == "obj" or sourcekind == "lib" then
        return
    end

    -- get compile arguments
    local arguments = compiler.compflags(sourcefile, {target = target})
    for i, flag in ipairs(arguments) do
        -- only export the -I*/-D* flags
        if not g_flags[flag] and string.find(flag, '^-[ID]') then
            g_flags[flag] = true
            table.insert(g_flags, flag)
        end
    end

    -- clear first line marks
    _g.firstline = false
end
 
-- make each objects
function _make_each_objects(target, sourcekind, sourcebatch)
    for index, objectfile in ipairs(sourcebatch.objectfiles) do
        _make_object(target, sourcebatch.sourcefiles[index], objectfile)
    end
end
 
-- make single object
function _make_single_object(target, sourcekind, sourcebatch)

    -- not supported now, ignore it directly
    for _, sourcefile in ipairs(table.wrap(sourcebatch.sourcefiles)) do
        cprint("${bright yellow}warning: ${default yellow}ignore[%s]: %s", target:name(), sourcefile)
    end
end

-- make target
function _make_target(target)

    -- TODO
    -- disable precompiled header first
    target:set("pcheader", nil)
    target:set("pcxxheader", nil)

    -- build source batches
    for sourcekind, sourcebatch in pairs(target:sourcebatches()) do
        if not sourcebatch.rulename then
            if type(sourcebatch.objectfiles) == "string" then
                _make_single_object(target, sourcekind, sourcebatch)
            else
                _make_each_objects(target, sourcekind, sourcebatch)
            end
        end
    end
end

-- make all
function _make_all()
    -- make flags
    _g.firstline = true
    for _, target in pairs(project.targets()) do
        local isdefault = target:get("default")
        if not target:isphony() and (isdefault == nil or isdefault == true) then
            _make_target(target)
        end
    end
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
    g_flags = {}
    _make_all()

    -- write to file
    local flagfile = io.open(path.join(outputdir, "compile_flags.txt"), "w")
    for i, flag in ipairs(g_flags) do
        flagfile:write(flag, '\n')
    end
    flagfile:close()
 
    -- leave project directory
    os.cd(oldir)
end
