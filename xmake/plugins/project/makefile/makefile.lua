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
-- @file        makefile.lua
--

-- imports
import("core.tool.tool")
import("core.tool.compiler")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- get log makefile
function _logfile()

    -- get it
    return vformat("$(buildir)/.build.log")
end

-- mkdir directory
function _mkdir(makefile, dir)

    if config.get("plat") == "windows" then
        makefile:print("\t-@mkdir %s > /null 2>&1", dir)
    else
        makefile:print("\t@mkdir -p %s", dir)
    end
end

-- copy file
function _cp(makefile, sourcefile, targetfile)

    -- copy file
    if config.get("plat") == "windows" then
        makefile:print("\t@copy /Y %s %s > /null 2>&1", sourcefile, targetfile)
    else
        makefile:print("\t@cp %s %s", sourcefile, targetfile)
    end
end

-- make the object for the *.[o|obj] source file
function _make_object_for_object(makefile, target, sourcefile, objectfile)

    -- make command
    local cmd = format("xmake l cp %s %s", sourcefile, objectfile)

    -- make head
    makefile:printf("%s:", objectfile)

    -- make dependence
    makefile:print(" %s", sourcefile)

    -- make body
    makefile:print("\t@echo inserting.$(mode) %s", sourcefile)
    makefile:print("\t@%s", cmd)

    -- make tail
    makefile:print("")

end

-- make the object for the *.[a|lib] source file
function _make_object_for_static(makefile, target, sourcefile, objectfile)

    -- not supported
    raise("source file: %s not supported!", sourcefile)
end

-- make the object
function _make_object(makefile, target, sourcefile, objectfile)

    -- get the source file kind
    local sourcekind = language.sourcekind_of(sourcefile)

    -- make the object for the *.o/obj source makefile
    if sourcekind == "obj" then 
        return _make_object_for_object(makefile, target, sourcefile, objectfile)
    -- make the object for the *.[a|lib] source file
    elseif sourcekind == "lib" then 
        return _make_object_for_static(makefile, target, sourcefile, objectfile)
    end

    -- get shellname name
    local shellname = tool.shellname(sourcekind)

    -- get complier flags
    local compflags = compiler.compflags(sourcefile, target, sourcekind)

    -- make command
    local command = compiler.compcmd(sourcefile, objectfile, target)

    -- replace compflags to $(XX)
    local p, e = command:find(compflags, 1, true)
    if p then
        command = format("%s$(%s_%s)%s", command:sub(1, p - 1), target:name(), sourcekind:upper(), command:sub(e + 1)) 
    end

    -- replace shellname to $(XX)
    p, e = command:find(shellname, 1, true)
    if p then
        command = format("%s$(%s)%s", command:sub(1, p - 1), sourcekind:upper(), command:sub(e + 1)) 
    end

    -- make head
    makefile:printf("%s:", objectfile)

    -- make dependence
    makefile:print(" %s", sourcefile)

    -- make body
    makefile:print("\t@echo %scompiling.$(mode) %s", ifelse(config.get("ccache"), "ccache ", ""), sourcefile)
    _mkdir(makefile, path.directory(objectfile))
    makefile:writef("\t@%s > %s 2>&1\n", command, _logfile())

    -- make tail
    makefile:print("")
end
 
-- make each objects
function _make_each_objects(makefile, target, sourcekind, sourcebatch)

    -- make them
    for index, objectfile in ipairs(sourcebatch.objectfiles) do
        _make_object(makefile, target, sourcebatch.sourcefiles[index], objectfile)
    end
end
 
-- make single object
function _make_single_object(makefile, target, sourcekind, sourcebatch)

    -- get source and object files
    local sourcefiles = sourcebatch.sourcefiles
    local objectfiles = sourcebatch.objectfiles
    local incdepfiles = sourcebatch.incdepfiles

    -- get shellname name
    local shellname = tool.shellname(sourcekind)

    -- get complier flags
    local compflags = compiler.compflags(sourcefiles, target, sourcekind)

    -- make command
    local command = compiler.compcmd(sourcefiles, objectfiles, target, sourcekind)

    -- replace compflags to $(XX)
    local p, e = command:find(compflags, 1, true)
    if p then
        command = format("%s$(%s_%s)%s", command:sub(1, p - 1), target:name(), sourcekind:upper(), command:sub(e + 1)) 
    end

    -- replace shellname to $(XX)
    p, e = command:find(shellname, 1, true)
    if p then
        command = format("%s$(%s)%s", command:sub(1, p - 1), sourcekind:upper(), command:sub(e + 1)) 
    end

    -- make head
    makefile:printf("%s:", objectfiles)

    -- make dependence
    for _, sourcefile in ipairs(sourcefiles) do
        makefile:printf(" %s", sourcefile)
    end
    makefile:print("")

    -- make body
    for _, sourcefile in ipairs(sourcefiles) do
        makefile:print("\t@echo %scompiling.$(mode) %s", ifelse(config.get("ccache"), "ccache ", ""), sourcefile)
    end
    _mkdir(makefile, path.directory(objectfiles))
    makefile:writef("\t@%s > %s 2>&1\n", command, _logfile())

    -- make tail
    makefile:print("")
end

-- make target
function _make_target(makefile, target)

    -- make head
    local targetfile = target:targetfile()
    makefile:print("%s: %s", target:name(), targetfile)
    makefile:printf("%s:", targetfile)

    -- make dependence for the dependent targets
    for _, dep in ipairs(target:get("deps")) do
        
        -- add dependence
        makefile:write(" " .. project.target(dep):targetfile())
    end

    -- make dependence for objects
    local objectfiles = target:objectfiles()
    for _, objectfile in ipairs(objectfiles) do
        makefile:write(" " .. objectfile)
    end

    -- make dependence end
    makefile:print("")

    -- get linker kind
    local linkerkind = target:linker():get("kind")

    -- get shellname
    local shellname = tool.shellname(linkerkind)

    -- get command
    local command = target:linkcmd()

    -- replace linkflags to $(XX)
    local p, e = command:find(target:linkflags(), 1, true)
    if p then
        command = format("%s$(%s_%s)%s", command:sub(1, p - 1), target:name(), (linkerkind:upper():gsub('%-', '_')), command:sub(e + 1)) 
    end

    -- replace shellname to $(XX)
    p, e = command:find(shellname, 1, true)
    if p then
        command = format("%s$(%s)%s", command:sub(1, p - 1), (linkerkind:upper():gsub('%-', '_')), command:sub(e + 1)) 
    end

    -- make body
    makefile:print("\t@echo linking.$(mode) %s", path.filename(targetfile))
    _mkdir(makefile, path.directory(targetfile))
    makefile:writef("\t@%s > %s 2>&1\n", command, _logfile())

    -- make header directories
    local dstheaderdirs = {}
    local srcheaders, dstheaders = target:headerfiles()
    for _, dstheader in ipairs(dstheaders) do
        dstheaderdirs[path.directory(dstheader)] = true
    end
    for dstheaderdir, _ in pairs(dstheaderdirs) do
        _mkdir(makefile, dstheaderdir)
    end

    -- copy headers
    if srcheaders and dstheaders then
        local i = 1
        for _, srcheader in ipairs(srcheaders) do
            local dstheader = dstheaders[i]
            if dstheader then
                _cp(makefile, srcheader, dstheader)
            end
            i = i + 1
        end
    end

    -- make tail
    makefile:print("")

    -- build source batches
    for sourcekind, sourcebatch in pairs(target:sourcebatches()) do

        -- compile source files to single object at the same time?
        if type(sourcebatch.objectfiles) == "string" then
        
            -- make single object
            _make_single_object(makefile, target, sourcekind, sourcebatch)
        else

            -- make each objects
            _make_each_objects(makefile, target, sourcekind, sourcebatch)
        end
    end
end

-- make all
function _make_all(makefile)

    -- make variables for source kinds
    for sourcekind, _ in pairs(language.sourcekinds()) do
        local shellname = tool.shellname(sourcekind)
        if shellname and shellname ~= "" then
            makefile:print("%s=%s", sourcekind:upper(), shellname)
        end
    end
    makefile:print("")

    -- make variables for linker kinds
    local linkerkinds = {}
    for _, _linkerkinds in pairs(language.targetkinds()) do
        table.join2(linkerkinds, _linkerkinds)
    end
    for _, linkerkind in ipairs(table.unique(linkerkinds)) do
        local shellname = tool.shellname(linkerkind)
        if shellname and shellname ~= "" then
            makefile:print("%s=%s", (linkerkind:upper():gsub('%-', '_')), shellname)
        end
    end
    makefile:print("")

    -- make variables for target flags
    for targetname, target in pairs(project.targets()) do
        for sourcekind, sourcebatch in pairs(target:sourcebatches()) do
            makefile:print("%s_%s=%s", targetname, sourcekind:upper(), compiler.compflags(sourcebatch.sourcefiles, target, sourcekind))
        end
        makefile:print("%s_%s=%s", targetname, target:linker():get("kind"):upper(), target:linkflags())
    end
    makefile:print("")

    -- make all
    local all = ""
    for targetname, _ in pairs(project.targets()) do
        -- append the target name to all
        all = all .. " " .. targetname
    end
    makefile:print("all: %s\n", all)
    makefile:print(".PHONY: all %s\n", all)

    -- make it for all targets
    for _, target in pairs(project.targets()) do

        -- make target
        _make_target(makefile, target)

        -- append the target name to all
        all = all .. " " .. target:name()
    end
   
end

-- make
function make(outputdir)

    -- enter project directory
    local olddir = os.cd(project.directory())

    -- remove the log makefile first
    os.rm(_logfile())

    -- open the makefile
    local makefile = io.open(path.join(outputdir, "makefile"), "w")

    -- make all
    _make_all(makefile)

    -- close the makefile
    makefile:close()
 
    -- leave project directory
    os.cd(olddir)
end
