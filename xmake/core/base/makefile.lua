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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        makefile.lua
--

-- define module: makefile
local makefile = makefile or {}

-- load modules
local io        = require("base/io")
local os        = require("base/os")
local rule      = require("base/rule")
local path      = require("base/path")
local utils     = require("base/utils")
local config    = require("base/config")
local project   = require("base/project")
local linker    = require("base/linker")
local compiler  = require("base/compiler")
local tools     = require("tools/tools")
local platform  = require("base/platform")

-- make object for the *.[o|obj] source file
function makefile._make_object_for_object(file, target, srcfile, objfile)

    -- get the source file type
    local filetype = path.extension(srcfile)
    if not filetype then return false end

    -- get the lower file type
    filetype = filetype:lower()

    -- not object file?
    if filetype ~= ".o" and filetype ~= ".obj" then return false end
    
    -- get mode
    local mode = config.get("mode")
    if mode then
        mode = "." .. mode 
    else 
        mode = ""
    end

    -- make command
    local cmd = string.format("xmake l cp %s %s", srcfile, objfile)

    -- make head
    file:write(string.format("%s:", objfile))

    -- make dependence
    file:write(string.format(" %s\n", srcfile))

    -- make body
    file:write(string.format("\t@echo inserting%s %s\n", mode, srcfile))
    file:write(string.format("\t@xmake l $(VERBOSE) verbose \"%s\"\n", cmd:encode()))
    file:write(string.format("\t@%s\n", cmd))

    -- make tail
    file:write("\n")

    -- ok
    return true
end

-- make object for the *.[a|lib] source file
function makefile._make_object_for_static(file, target, srcfile, objfile)

    -- get the source file type
    local filetype = path.extension(srcfile)
    if not filetype then return false end

    -- get the lower file type
    filetype = filetype:lower()

    -- not static file?
    if filetype ~= ".a" and filetype ~= ".lib" then return false end
    
    -- get mode
    local mode = config.get("mode")
    if mode then
        mode = "." .. mode 
    else 
        mode = ""
    end

    -- make command
    local cmd = string.format("xmake l -P %s -f %s dispatcher ex extract %s %s > %s 2>&1", xmake._PROJECT_DIR, xmake._PROJECT_FILE, srcfile:encode(), objfile:encode(), makefile._LOGFILE)

    -- make head
    file:write(string.format("%s:", objfile))

    -- make dependence
    file:write(string.format(" %s\n", srcfile))

    -- make body
    file:write(string.format("\t@echo inserting%s %s\n", mode, srcfile))
    file:write(string.format("\t@xmake l $(VERBOSE) verbose \"%s\"\n", cmd:encode()))
    file:write(string.format("\t@xmake l rmdir %s\n", path.directory(objfile)))
    file:write(string.format("\t@%s\n", cmd))

    -- make tail
    file:write("\n")

    -- ok
    return true
end

-- make the object to the makefile
function makefile._make_object(file, target, srcfile, objfile)
    
    -- check
    assert(file and target and srcfile and objfile)

    -- make object for the *.o/obj source file
    if makefile._make_object_for_object(file, target, srcfile, objfile) then
        return true
    elseif makefile._make_object_for_static(file, target, srcfile, objfile) then
        return true
    end

    -- get the compiler 
    local c, errors = compiler.get(srcfile)
    if not c then
        -- error
        utils.error(errors)
        return false
    end

    -- get mode
    local mode = config.get("mode")
    if mode then
        mode = "." .. mode 
    else 
        mode = ""
    end

    -- get ccache
    local ccache = platform.tool("ccache") 

    -- make command
    local cmd = compiler.make(c, target, srcfile, objfile, makefile._LOGFILE)
    if ccache then
        cmd = ccache:append(cmd, " ")
    end

    -- make head
    file:write(string.format("%s:", objfile))

    -- make dependence
    file:write(string.format(" %s\n", srcfile))

    -- make body
    file:write(string.format("\t@echo %scompiling%s %s\n", utils.ifelse(ccache, "ccache ", ""), mode, srcfile))
    file:write(string.format("\t@xmake l $(VERBOSE) verbose \"%s\"\n", cmd:encode()))
    file:write(string.format("\t@xmake l mkdir %s\n", path.directory(objfile)))
    file:write(string.format("\t@%s\n", cmd))

    -- make tail
    file:write("\n")

    -- ok
    return true
end

-- make all objects of the given target to the makefile
function makefile._make_objects(file, target, srcfiles, objfiles)

    -- check
    assert(file and target and srcfiles and objfiles)

    -- make all objects
    local i = 1
    for _, objfile in ipairs(objfiles) do

        -- make object
        if not makefile._make_object(file, target, srcfiles[i], objfile) then
            return false
        end

        -- next
        i = i + 1
    end

    -- ok
    return true
end

-- make the given target to the makefile
function makefile._make_target(file, name, target)

    -- check
    assert(file and name and target and target.kind)

    -- get source and object files
    local srcfiles = rule.sourcefiles(target)
    local objfiles = rule.objectfiles(name, target, srcfiles)
    assert(srcfiles and objfiles)

    -- get source and destinate header files
    local srcheaders, dstheaders = rule.headerfiles(target)

    -- get target file
    local targetfile = rule.targetfile(name, target)
    assert(targetfile)

    -- get the targets
    local targets = project.targets()
    assert(targets)

    -- get the linker from the given kind
    local l = linker.get(target.kind)
    if not l then 
        utils.error("cannot get linker with kind: %s", target.kind)
        return false
    end

    -- make head
    file:write(string.format("%s: %s\n", name, targetfile))
    file:write(string.format("%s:", targetfile))

    -- make dependence for the dependent targets
    if target.deps then

        -- get all dependent target
        local deps = utils.wrap(target.deps)
        for _, dep in ipairs(deps) do
            
            -- the dependent target
            local deptarget = targets[dep]
            if not deptarget then
                utils.error("the dependent target: %s is invalid!", dep)
                return false
            end

            -- get the dependent target file
            local depfile = rule.targetfile(dep, deptarget)
            assert(depfile)

            -- add dependence
            file:write(" " .. depfile)
        end
    end

    -- make dependence for objects
    for _, objfile in ipairs(objfiles) do
        file:write(" " .. objfile)
    end

    -- make dependence end
    file:write("\n")

    -- get mode
    local mode = config.get("mode")
    if mode then
        mode = "." .. mode 
    else 
        mode = ""
    end
   
    -- make the command
    local cmd = linker.make(l, target, srcfiles, objfiles, targetfile, makefile._LOGFILE)

    -- the verbose
    local verbose = cmd:encode()
    -- too long?
    if verbose and #verbose > 256 then
        verbose = linker.make(l, target, srcfiles, {rule.filename("*", "object")}, targetfile)
        verbose = verbose:encode()
    end

    -- make body
    file:write(string.format("\t@echo linking%s %s\n", mode, path.filename(targetfile)))
    file:write(string.format("\t@xmake l $(VERBOSE) verbose \"%s\"\n", verbose))
    file:write(string.format("\t@xmake l mkdir %s\n", path.directory(targetfile)))
    file:write(string.format("\t@%s\n", cmd))
    if srcheaders and dstheaders then
        local i = 1
        for _, srcheader in ipairs(srcheaders) do
            local dstheader = dstheaders[i]
            if dstheader then
                file:write(string.format("\t@xmake l cp %s %s\n", srcheader, dstheader))
            end
            i = i + 1
        end
    end

    -- make tail
    file:write("\n")

    -- make objects for this target
    return makefile._make_objects(file, target, srcfiles, objfiles) 
end

-- make all targets to the makefile
function makefile._make_targets(file)

    -- check 
    assert(file)

    -- get all project targets
    local targets = project.targets()
    if not targets then
        -- error
        utils.error("not found target in this project!")
        return false
    end

    -- make all first
    local all = ""
    for name, _ in pairs(targets) do
        -- append the target name to all
        all = all .. " " .. name
    end
    file:write(string.format("all: %s\n\n", all))
    file:write(string.format(".PHONY: all %s\n\n", all))

    -- make it for all targets
    for name, target in pairs(targets) do
        -- make target
        if not makefile._make_target(file, name, target) then
            -- error
            utils.error("failed to make target %s to makefile!", name)
            return false
        end

        -- append the target name to all
        all = all .. " " .. name
    end
   
    -- ok
    return true
end

-- make makefile in the build directory
function makefile.make()

    -- get the build directory
    local buildir = config.get("buildir")
    assert(buildir)

    -- init the log file
    local logfile = rule.logfile()
    if logfile and os.isfile(logfile) then
        os.rmfile(logfile)
    end

    -- save the log file
    makefile._LOGFILE = logfile
    assert(logfile)

    -- open the makefile 
    local path = rule.makefile() 
    local file = io.openmk(path)
    if not file then
        -- error
        utils.error("open %s failed!", path)
        return false
    end

    -- make all targets to the makefile
    if not makefile._make_targets(file) then

        -- error 
        utils.error("save %s failed!", path)

        -- close the makefile
        file:close()

        -- remove the makefile
        os.rm(path)

        -- failed
        return false
    end

    -- close the makefile
    file:close()

    -- ok
    return true
end

-- build target
function makefile.build(target)

    -- check
    assert(target and type(target) == "string")

    -- load make
    local make = tools.get("make")
    if not make then
        utils.error("not found the make command!")
        return false
    end
 
    -- done make
    return make:main(rule.makefile(), target)
end

-- return module: makefile
return makefile
