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
local path      = require("base/path")
local utils     = require("base/utils")
local config    = require("base/config")
local project   = require("base/project")
local platform  = require("platform/platform")

-- get the source files from the given target
function makefile._srcfiles(target)

    -- check
    assert(target)

    -- no files?
    if not target.files then
        return {}
    end

    -- wrap files first
    local target_files = utils.wrap(target.files)

    -- match files
    local i = 1
    local srcfiles = {}
    for _, target_file in ipairs(target_files) do

        -- match source files
        local files = os.match(target_file)

        -- process source files
        for _, file in ipairs(files) do

            -- convert to the relative path
            if path.is_absolute(file) then
                file = path.relative(file, xmake._PROJECT_DIR)
            end

            -- save it
            srcfiles[i] = file
            i = i + 1

        end
    end

    -- remove repeat files
    srcfiles = utils.unique(srcfiles)

    -- ok?
    return srcfiles
end

-- get object files for the given source files
function makefile._objfiles(name, srcfiles)

    -- check
    assert(name and srcfiles)

    -- the build directory
    local buildir = config.get("buildir")
    assert(buildir)
   
    -- the object file format
    local format = platform._CONFIGS.format.object
    assert(format)
 
    -- make object files
    local i = 1
    local objfiles = {}
    for _, srcfile in ipairs(srcfiles) do

        -- make object file
        local objfile = string.format("%s/%s/%s/%s/%s/%s", buildir, name, path.directory(srcfile), format[1], path.basename(srcfile), format[2])

        -- save it
        objfiles[i] = path.translate(objfile)
        i = i + 1

    end

    -- ok?
    return objfiles
end

-- make the object of the given target to the makefile
function makefile._make_object(file, target, srcfile, objfile)
    
    -- check
    assert(file and target and srcfile and objfile)

    -- make head
    file:write(string.format("%s:", objfile))

    -- make dependence
    file:write(string.format(" %s\n", srcfile))

    -- make body
    file:write(string.format("\techo \"%s\"\n", srcfile))

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
    assert(file and name and target)

    -- get source and object files
    local srcfiles = makefile._srcfiles(target)
    local objfiles = makefile._objfiles(name, srcfiles)
    assert(srcfiles and objfiles)

    -- make head
    file:write(string.format("%s:", name))

    -- make dependence for target
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
    file:write(string.format("\techo \"%s\"\n", name))

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
    local ok = os.execute(string.format("make -f %s %s", buildir .. "/makefile", target))
    if ok ~= 0 then
        -- error
        utils.error("build target: %s failed!", target)
        return false
    end

    -- ok
    return true
end

-- return module: makefile
return makefile
