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
import("core.tool.linker")
import("core.tool.compiler")
import("core.project.config")
import("core.project.project")

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
function _cp(makefile, srcfile, dstfile)

    -- ensure the destinate directory
    _mkdir(makefile, path.directory(dstfile))

    -- copy file
    if config.get("plat") == "windows" then
        makefile:print("\t@copy /Y %s %s > /null 2>&1", srcfile, dstfile)
    else
        makefile:print("\t@cp %s %s", srcfile, dstfile)
    end
end

-- make the object for the *.[o|obj] source file
function _make_object_for_object(makefile, target, srcfile, objfile)

    -- make command
    local cmd = format("xmake l cp %s %s", srcfile, objfile)

    -- make head
    makefile:printf("%s:", objfile)

    -- make dependence
    makefile:print(" %s", srcfile)

    -- make body
    makefile:print("\t@echo inserting.$(mode) %s", srcfile)
    makefile:print("\t@%s", cmd)

    -- make tail
    makefile:print("")

end

-- make the object for the *.[a|lib] source file
function _make_object_for_static(makefile, target, srcfile, objfile)

    -- not supported
    raise("source file: %s not supported!", srcfile)
end

-- make the object
function _make_object(makefile, target, srcfile, objfile)

    -- get the source file type
    local filetype = path.extension(srcfile):lower()

    -- make the object for the *.o/obj source makefile
    if filetype == ".o" or filetype == ".obj" then 
        return _make_object_for_object(makefile, target, srcfile, objfile)
    -- make the object for the *.[a|lib] source file
    elseif filetype == ".a" or filetype == ".lib" then 
        return _make_object_for_static(makefile, target, srcfile, objfile)
    end

    -- make command
    local command = compiler.compcmd(srcfile, objfile, target)

    -- make head
    makefile:printf("%s:", objfile)

    -- make dependence
    makefile:print(" %s", srcfile)

    -- make body
    makefile:print("\t@echo %scompiling.$(mode) %s", ifelse(config.get("ccache"), "ccache ", ""), srcfile)
    _mkdir(makefile, path.directory(objfile))
    makefile:print("\t@%s > %s 2>&1", command, _logfile())

    -- make tail
    makefile:print("")
end
 
-- make all objects of the given target 
function _make_objects(makefile, target, srcfiles, objfiles)

    -- make all objects
    local i = 1
    for _, objfile in ipairs(objfiles) do

        -- make object
        _make_object(makefile, target, srcfiles[i], objfile)

        -- next
        i = i + 1
    end

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
    local objfiles = target:objectfiles()
    for _, objfile in ipairs(objfiles) do
        makefile:write(" " .. objfile)
    end

    -- make dependence end
    makefile:print("")

    -- make the command
    local command = linker.linkcmd(target:objectfiles(), targetfile, target)

    -- make body
    makefile:print("\t@echo linking.$(mode) %s", path.filename(targetfile))
    _mkdir(makefile, path.directory(targetfile))
    makefile:print("\t@%s > %s 2>&1", command, _logfile())

    -- make headers
    local srcheaders, dstheaders = target:headerfiles()
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

    -- make objects for this target
    _make_objects(makefile, target, target:sourcefiles(), objfiles) 
end

-- make all
function _make_all(makefile)

    -- make all first
    local all = ""
    for targetname, _ in pairs(project.targets()) do
        -- append the target name to all
        all = all .. " " .. targetname
    end
    makefile:printf("all: %s\n\n", all)
    makefile:printf(".PHONY: all %s\n\n", all)

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
