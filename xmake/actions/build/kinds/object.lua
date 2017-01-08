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

    -- is verbose?
    local verbose = option.get("verbose")

    -- trace percent info
    cprintf("${green}[%02d%%]:${clear} ", percent)
    if verbose then
        cprint("${dim magenta}inserting.$(mode) %s", sourcefile)
    else
        cprint("${magenta}inserting.$(mode) %s", sourcefile)
    end

    -- trace verbose info
    if verbose then
        print("cp %s %s", sourcefile, objectfile)
    end

    -- insert this object file
    os.cp(sourcefile, objectfile)
end

-- build the object from the *.[a|lib] source file
function _build_from_static(target, sourcefile, objectfile, percent)

    -- is verbose?
    local verbose = option.get("verbose")

    -- trace percent info
    cprintf("${green}[%02d%%]:${clear} ", percent)
    if verbose then
        cprint("${dim magenta}inserting.$(mode) %s", sourcefile)
    else
        cprint("${magenta}inserting.$(mode) %s", sourcefile)
    end

    -- trace verbose info
    if verbose then
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

    -- get dependent files
    local depfiles = {}
    if incdepfile and os.isfile(incdepfile) then
        depfiles = io.load(incdepfile)
    end
    table.insert(depfiles, sourcefile)

    -- check the dependent files are modified?
    local modified      = false
    local objectmtime   = nil
    _g.depfile_results  = _g.depfile_results or {}
    for _, depfile in ipairs(depfiles) do

        -- optimization: this depfile has been not checked?
        local status = _g.depfile_results[depfile]
        if status == nil then

            -- optimization: only uses the mtime of first object file
            objectmtime = objectmtime or os.mtime(objectfile)

            -- source and header files have been modified?
            if os.mtime(depfile) > objectmtime then

                -- modified
                modified = true

                -- mark this depfile as modified
                _g.depfile_results[depfile] = true
                break
            end

            -- mark this depfile as not modified
            _g.depfile_results[depfile] = false
        
        -- has been checked and modified?
        elseif status then
        
            -- modified
            modified = true
            break
        end
    end

    -- we need not rebuild it if the files are not modified 
    if not modified then
        return 
    end

    -- is verbose?
    local verbose = option.get("verbose")

    -- trace percent info
    cprintf("${green}[%02d%%]:${clear} ", percent)
    if verbose then
        cprint("${dim}%scompiling.$(mode) %s", ifelse(config.get("ccache"), "ccache ", ""), sourcefile)
    else
        print("%scompiling.$(mode) %s", ifelse(config.get("ccache"), "ccache ", ""), sourcefile)
    end

    -- trace verbose info
    if verbose then
        print(compiler.compcmd(sourcefile, objectfile, target))
    end

    -- complie it and enable multitasking
    compiler.compile(sourcefile, objectfile, incdepfile, target)
end

-- build objects for the given target
function buildall(target, g)

    -- get the max job count
    local jobs = tonumber(option.get("jobs") or "4")

    -- make objects
    local index = 1
    local total = #target:objectfiles()
    local tasks = {}
    local procs = {}
    repeat

        -- wait processes
        local tasks_finished = {}
        local procs_count = #procs
        if procs_count > 0 then

            -- wait them
            local procinfos = process.waitlist(procs, ifelse(procs_count < jobs, 0, -1))
            for _, procinfo in ipairs(procinfos) do
                
                -- the process info
                local proc      = procinfo[1]
                local procid    = procinfo[2]
                local status    = procinfo[3]

                -- check
                assert(procs[procid] == proc)

                -- resume this task
                local job_task = tasks[procid]
                local job_proc = coroutine.resume(job_task, 1, status)

                -- the other process is pending for this task?
                if coroutine.status(job_task) ~= "dead" then

                    -- check
                    assert(job_proc)

                    -- update the pending process
                    procs[procid] = job_proc

                -- this task has been finised?
                else

                    -- mark this task as finised
                    tasks_finished[procid] = true
                end
            end
        end

        -- update the pending tasks and procs
        local tasks_pending = {}
        local procs_pending = {}
        for taskid, job_task in ipairs(tasks) do
            if not tasks_finished[taskid] then
                table.insert(tasks_pending, job_task)
                table.insert(procs_pending, procs[taskid])
            end
        end
        tasks = tasks_pending
        procs = procs_pending

        -- produce tasks
        local curdir = os.curdir()
        while #tasks < jobs and index <= total do

            -- new task
            local job_task = coroutine.create(function (index)

                            -- force to set the current directory first because the other jobs maybe changed it
                            os.cd(curdir)

                            -- build object
                            _build(target, g, index)

                        end)

            -- resume it first
            local job_proc = coroutine.resume(job_task, index)
            if coroutine.status(job_task) ~= "dead" then

                -- check
                assert(job_proc)

                -- put task and proc to the pendings tasks
                table.insert(tasks, job_task)
                table.insert(procs, job_proc)
            end

            -- next index
            index = index + 1
        end

    until #tasks == 0
end

