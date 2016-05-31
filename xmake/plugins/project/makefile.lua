--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        makefile.lua
--

-- imports
import("core.tool.tool")
import("core.tool.linker")
import("core.tool.compiler")
import("core.project.project")

-- get log makefile
function _logfile()

    -- get it
    return vformat("$(buildir)/.build.log")
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
    makefile:print("\t@xmake l %$(VERBOSE) verbose \"%s\"", cmd:encode())
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
    local ccache    = tool.shellname("ccache") 
    local command   = compiler.command(target, srcfile, objfile)
    if ccache then
        command = ccache:append(command, " ")
    end

    -- make head
    makefile:printf("%s:", objfile)

    -- make dependence
    makefile:print(" %s", srcfile)

    -- make body
    makefile:print("\t@echo %scompiling.$(mode) %s", ifelse(ccache, "ccache ", ""), srcfile)
    makefile:print("\t@xmake l %$(VERBOSE) verbose \"%s\"", command:encode())
    makefile:print("\t@xmake l mkdir %s", path.directory(objfile))
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
    local command = linker.command(target)

    -- make body
    makefile:print("\t@echo linking.$(mode) %s", path.filename(targetfile))
    makefile:print("\t@xmake l %$(VERBOSE) verbose \"%s\"", command:encode())
    makefile:print("\t@xmake l mkdir %s", path.directory(targetfile))
    makefile:print("\t@%s > %s 2>&1", command, _logfile())

    -- make headers
    local srcheaders, dstheaders = target:headerfiles()
    if srcheaders and dstheaders then
        local i = 1
        for _, srcheader in ipairs(srcheaders) do
            local dstheader = dstheaders[i]
            if dstheader then
                makefile:print("\t@xmake l cp %s %s", srcheader, dstheader)
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
function make(outputfile)

    -- enter project directory
    os.cd(project.directory())

    -- remove the log makefile first
    os.rm(_logfile())

    -- open the makefile
    local makefile = io.open(outputfile, "w")

    -- make all
    _make_all(makefile)

    -- close the makefile
    makefile:close()
 
    -- leave project directory
    os.cd("-")

end
