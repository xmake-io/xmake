--!The Automatic Crmakefiles-platform Build Tool
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
local platform  = require("platform/platform")

-- make the object to the makefile
function makefile._make_object(file, target, srcfile, objfile)
    
    -- check
    assert(file and target and srcfile and objfile)

    -- get the compiler and filetype
    local c, filetype = platform.compiler(srcfile);
    if not c then
        -- error
        utils.error("unknown source file: %s", srcfile)
        return false
    end

    -- make head
    file:write(string.format("%s:", objfile))

    -- make dependence
    file:write(string.format(" %s\n", srcfile))

    -- make body
    file:write(string.format("\t@echo [%s]: compiling %s\n", config.get("mode"), srcfile))
    file:write(string.format("\t@xmake l mkdir %s\n", path.directory(objfile)))
    file:write(string.format("\t@%s > %s 2>&1\n", c:make(target, filetype, srcfile, objfile), makefile._LOGFILE))

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

    -- get target file
    local targetfile = rule.targetfile(name, target)
    assert(targetfile)

    -- the linker
    local l = platform.linker(target.kind)
    assert(l)

    -- make head
    file:write(string.format("%s:", name))

    -- make dependence for the dependent targets
    if target.deps then
        local deps = utils.wrap(target.deps)
        for _, dep in ipairs(deps) do
            file:write(" " .. dep)
        end
    end

    -- make dependence for objects
    for _, objfile in ipairs(objfiles) do
        file:write(" " .. objfile)
    end

    -- make dependence end
    file:write("\n")

    -- make body
    file:write(string.format("\t@echo [%s]: linking %s\n", config.get("mode"), path.filename(targetfile)))
    file:write(string.format("\t@xmake l mkdir %s\n", path.directory(targetfile)))
    file:write(string.format("\t@%s > %s 2>&1\n", l:make(target, objfiles, targetfile), makefile._LOGFILE))

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

    -- make the build directory
    if not os.isdir(buildir) then
        assert(os.mkdir(buildir))
    end

    -- init the log file
    local logfile = rule.logfile()
    if logfile and os.isfile(logfile) then
        os.rmfile(logfile)
    end

    -- save the log file
    makefile._LOGFILE = logfile
    assert(logfile)

    -- open the makefile 
    local path = buildir .. "/makefile"
    local file = io.open(path, "w")
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

    -- get the build directory
    local buildir = config.get("buildir")
    assert(buildir)

    -- done build
    return platform.build(buildir .. "/makefile", target)
end

-- return module: makefile
return makefile
