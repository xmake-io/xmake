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
-- @file        builder.lua
--

-- imports
import("core.base.option")
import("core.project.task")
import("core.project.config")
import("core.project.project")
import("core.project.cache")
import("core.tool.tool")

-- get target
function _target(targetname)

    -- get and check it
    return assert(project.target(targetname), "unknown target: %s", targetname)
end

-- make the object for the *.[o|obj] source file
function _make_object_for_object(target, srcfile, objfile)
end

-- make the object for the *.[a|lib] source file
function _make_object_for_static(target, srcfile, objfile)
end

-- make object
function _make_object(target, sourcefile, objectfile)

    -- get the source file type
    local filetype = path.extension(sourcefile):lower()

    -- make the object for the *.o/obj source makefile
    if filetype == ".o" or filetype == ".obj" then 
        return _make_object_for_object(target, sourcefile, objectfile)
    -- make the object for the *.[a|lib] source file
    elseif filetype == ".a" or filetype == ".lib" then 
        return _make_object_for_static(target, sourcefile, objectfile)
    end

    -- make command
    local ccache    = tool.shellname("ccache") 
    local compiler  = target:compiler(sourcefile)
    local cmd       = compiler:command(target, sourcefile, objectfile)
    if ccache then
        cmd = ccache:append(cmd, " ")
    end

    -- trace
    print("%scompiling.$(mode) %s", ifelse(ccache, "ccache ", ""), sourcefile)

    -- trace verbose info
    if option.get("verbose") then
        print(cmd)
    end

    -- create directory if not exists
    os.mkdir(path.directory(objectfile))

    -- run cmd
    os.run(cmd)
end

-- make objects for the given target
function _make_objects(target)

    -- make all objects
    local i = 1
    local objectfiles = target:objectfiles()
    local sourcefiles = target:sourcefiles()
    for _, objectfile in ipairs(objectfiles) do

        -- make object
        _make_object(target, sourcefiles[i], objectfile)

        -- next
        i = i + 1
    end
end

-- make the given target
function _make_target(target)

    -- trace
    print("building.$(mode) %s", target:name())

    -- make objects
    _make_objects(target)

    -- make target
    -- ...
end

-- make the given target and deps
function _make_target_and_deps(target)

    -- this target have been finished?
    if _g.finished[target:name()] then
        return 
    end

    -- make for all dependent targets
    for _, depname in ipairs(target:get("deps")) do
        _make_target_and_deps(_target(depname))
    end

    -- make target
    _make_target(target)

    -- finished
    _g.finished[target:name()] = true
end

-- make
function make(targetname)

    -- init finished states
    _g.finished = {}

    -- for all?
    if targetname == "all" then

        -- make all targets
        for _, target in pairs(project.targets()) do
            _make_target_and_deps(target)
        end
    else

        -- make target
        _make_target_and_deps(_target(targetname))
    end
end

-- make from makefile
function make_from_makefile(targetname)

    -- check target
    if targetname ~= "all" then
        _target(targetname)
    end

    -- make makefile
    task.run("makefile", {output = path.join(config.get("buildir"), "makefile")})

    -- run make
    tool.run("make", path.join(config.get("buildir"), "makefile"), targetname, option.get("jobs"))
end
