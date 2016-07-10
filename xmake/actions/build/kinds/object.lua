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
-- @file        object.lua
--

-- imports
import("core.base.option")
import("core.tool.tool")
import("core.tool.compiler")
import("core.tool.extractor")
import("core.project.config")

-- build the object from the *.[o|obj] source file
function _build_from_object(target, sourcefile, objectfile, percent)

    -- trace
    print("[%02d%%]: inserting.$(mode) %s", percent, sourcefile)

    -- trace verbose info
    if option.get("verbose") then
        print("cp %s %s", sourcefile, objectfile)
    end

    -- insert this object file
    os.cp(sourcefile, objectfile)
end

-- build the object from the *.[a|lib] source file
function _build_from_static(target, sourcefile, objectfile, percent)

    -- trace
    print("[%02d%%]: inserting.$(mode) %s", percent, sourcefile)

    -- trace verbose info
    if option.get("verbose") then
        print("ex %s %s", sourcefile, objectfile)
    end

    -- extract the static library to object directory
    extractor.extract(sourcefile, path.directory(objectfile))
end

-- build object
function _build(target, g, index)

    -- the object and source files
    local objectfiles = target:objectfiles()
    local sourcefiles = target:sourcefiles()
    local incdepfiles = target:incdepfiles()

    -- get the object and source with the given index
    local sourcefile = sourcefiles[index]
    local objectfile = objectfiles[index]
    local incdepfile = incdepfiles[index]

    -- get dependent files
    local depfiles = {}
    if incdepfile and os.isfile(incdepfile) then
        depfiles = io.load(incdepfile)
    end
    table.insert(depfiles, sourcefile)

    -- check the dependent files are modified?
    local modified = false
    for _, depfile in ipairs(depfiles) do
        if os.mtime(depfile) > os.mtime(objectfile) then
            modified = true
            break
        end
    end

    -- we need not rebuild it if the files are not modified 
    if not modified then
        return 
    end

    -- get the source file type
    local filetype = path.extension(sourcefile):lower()

    -- calculate percent
    local percent = ((g.targetindex + (index - 1) / #objectfiles) * 100 / g.targetcount)

    -- build the object for the *.o/obj source makefile
    if filetype == ".o" or filetype == ".obj" then 
        return _build_from_object(target, sourcefile, objectfile, percent)
    -- build the object for the *.[a|lib] source file
    elseif filetype == ".a" or filetype == ".lib" then 
        return _build_from_static(target, sourcefile, objectfile, percent)
    end

    -- get ccache
    local ccache = nil
    if config.get("ccache") then
        ccache = tool.shellname("ccache") 
    end

    -- trace
    print("[%02d%%]: %scompiling.$(mode) %s", percent, ifelse(ccache, "ccache ", ""), sourcefile)

    -- trace verbose info
    if option.get("verbose") then
        print(compiler.compcmd(sourcefile, objectfile, target))
    end

    -- complie it and enable multitasking
    compiler.compile(sourcefile, objectfile, incdepfile, target, true)
end

-- build objects for the given target
function buildall(target, g)

    -- get the max job count
    local jobs = tonumber(option.get("jobs") or "4")

    -- make objects
    local index = 1
    local total = #target:objectfiles()
    local tasks = {}
    repeat

        -- consume tasks
        local pendings = {}
        for i, task in ipairs(tasks) do

            -- get job
            local job = task[1]

            -- get job index
            local job_index = task[2]

            -- pending?
            local status = coroutine.status(job)
            if status ~= "dead" then

                -- resume it
                coroutine.resume(job, job_index)

                -- append the pending task
                table.insert(pendings, task)
            end
        end

        -- update the pending tasks
        tasks = pendings

        -- produce tasks
        while #tasks < jobs and index <= total do
            table.insert(tasks, {coroutine.create(function (index)

                        -- build object
                        _build(target, g, index)

                    end), index})
            index = index + 1
        end

    until #tasks == 0
end

