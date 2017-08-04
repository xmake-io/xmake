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
-- @file        compile_commands.lua
--

-- imports
import("core.tool.compiler")
import("core.project.project")
import("core.language.language")

-- make the object
function _make_object(jsonfile, target, sourcefile, objectfile)

    -- get the source file kind
    local sourcekind = language.sourcekind_of(sourcefile)

    -- make the object for the *.o/obj? ignore it directly
    if sourcekind == "obj" or sourcekind == "lib" then 
        return 
    end

    -- get compile arguments
    local arguments = table.join(compiler.compargv(sourcefile, objectfile, {target = target, sourcekind = sourcekind}))

    -- escape '"', '\'
    local arguments_escape = {}
    for _, arg in ipairs(arguments) do
        table.insert(arguments_escape, (arg:gsub("[\"\\]", "\\%1")))
    end

    -- make body
    jsonfile:printf(
[[%s{
  "directory": "%s",
  "arguments": ["%s"],
  "file": "%s"
}]], ifelse(_g.firstline, "", ",\n"), os.projectdir(), table.concat(arguments_escape, "\", \""), sourcefile)

    -- clear first line marks
    _g.firstline = false
end
 
-- make each objects
function _make_each_objects(jsonfile, target, sourcekind, sourcebatch)
    for index, objectfile in ipairs(sourcebatch.objectfiles) do
        _make_object(jsonfile, target, sourcebatch.sourcefiles[index], objectfile)
    end
end
 
-- make single object
function _make_single_object(jsonfile, target, sourcekind, sourcebatch)

    -- not supported now, ignore it directly
    for _, sourcefile in ipairs(table.wrap(sourcebatch.sourcefiles)) do
        cprint("${bright yellow}warning: ${default yellow}ignore[%s]: %s", target:name(), sourcefile)
    end
end

-- make target
function _make_target(jsonfile, target)

    -- TODO
    -- disable precompiled header first
    target:set("pcheader", nil)
    target:set("pcxxheader", nil)

    -- build source batches
    for sourcekind, sourcebatch in pairs(target:sourcebatches()) do
        if type(sourcebatch.objectfiles) == "string" then
            _make_single_object(jsonfile, target, sourcekind, sourcebatch)
        else
            _make_each_objects(jsonfile, target, sourcekind, sourcebatch)
        end
    end
end

-- make all
function _make_all(jsonfile)

    -- make header
    jsonfile:print("[")

    -- make commands
    _g.firstline = true
    for _, target in pairs(project.targets()) do
        local isdefault = target:get("default")
        if not target:isphony() and (isdefault == nil or isdefault == true) then
            _make_target(jsonfile, target)
        end
    end

    -- make tailer
    jsonfile:print("]")
end

-- generate compilation databases for clang-based tools(compile_commands.json)
--
-- references:
--  - https://clang.llvm.org/docs/JSONCompilationDatabase.html
--  - https://sarcasm.github.io/notes/dev/compilation-database.html
--  - http://eli.thegreenplace.net/2014/05/21/compilation-databases-for-clang-based-tools
--
function make(outputdir)

    -- enter project directory
    local oldir = os.cd(os.projectdir())

    -- open the jsonfile
    local jsonfile = io.open(path.join(outputdir, "compile_commands.json"), "w")

    -- make all
    _make_all(jsonfile)

    -- close the jsonfile
    jsonfile:close()
 
    -- leave project directory
    os.cd(oldir)
end
