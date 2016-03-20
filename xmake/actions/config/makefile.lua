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
import("core.project.project")

-- make the object
function _make_object(makefile, target, srcfile, objfile)

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

--[[    -- get the linker from the given kind
    local l = linker.get(target.kind)
    if not l then 
        utils.error("cannot get linker with kind: %s", target.kind)
        return false
    end
]]

    -- make head
    local targetfile = target:targetfile()
    makefile:printf("%s: %s\n", name, targetfile)
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
    local srcfiles = target:sourcefiles()
    local cmd = ""--linker.make(l, target, srcfiles, objfiles, targetfile, makefile._LOGFILE)

    -- make the verbose info
    local verbose = cmd:encode()
    if verbose and #verbose > 256 then
        verbose = nil--linker.make(l, target, srcfiles, {rule.filename("*", "object")}, targetfile)
        verbose = verbose:encode()
    end

    -- TODO: $(mode)
    -- make body
    makefile:print("\t@echo linking.$(mode) %s", path.filename(targetfile))
    makefile:print("\t@xmake l $(VERBOSE) verbose \"%s\"", verbose)
    makefile:print("\t@xmake l mkdir %s", path.directory(targetfile))
    makefile:print("\t@%s", cmd)

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
    _make_objects(makefile, target, srcfiles, objfiles) 

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
function make()

    -- enter project directory
    os.cd("$(projectdir)")

    -- remove the log file first
    os.rm("$(buildir)/.build.log")

    -- open the makefile
    local makefile = io.open("$(buildir)/makefile", "w")

    -- make all
    _make_all(makefile)

    -- close the makefile
    makefile:close()
 
    -- leave project directory
    os.cd("-")

end
