--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        binary.lua
--

-- imports
import("core.base.option")
import("core.tool.linker")
import("core.tool.compiler")
import("object")

-- is modified?
function _is_modified(target, depfile, buildinfo, program, linkflags)

    -- the target file not exists?
    if not os.isfile(target:targetfile()) then
        return true
    end

    -- this target and it's deps are not modified?
    local modified = buildinfo.rebuild or buildinfo.modified[target:name()]
    if modified then
        return true
    end

    -- deps modified?
    for _, depname in ipairs(target:get("deps")) do
        if buildinfo.modified[depname] then
            return true
        end
    end

    -- get dependent info 
    local depinfo = {}
    if os.isfile(depfile) then
        depinfo = io.load(depfile) or {}
    end

    -- the program has been modified?
    if program ~= depinfo.program then
        return true
    end

    -- the flags has been modified?
    if os.args(linkflags) ~= os.args(depinfo.flags) then
        return true
    end

    -- the object files list has been modified?
    local objectfiles = target:objectfiles()
    if #(objectfiles or {}) ~= #(depinfo.objectfiles or {}) then
        return true
    end
    for idx, objectfile in ipairs(depinfo.objectfiles) do
        if objectfile ~= objectfiles[idx] then
            return true
        end
    end
end

-- build target from sources
function _build_from_objects(target, buildinfo)

    -- build objects
    object.build(target, buildinfo)

    -- load linker instance
    local linker_instance = linker.load(target:targetkind(), target:sourcekinds(), {target = target})

    -- get program
    local program = linker_instance:program()

    -- get link flags
    local linkflags = linker_instance:linkflags({target = target})

    -- this target and it's deps are not modified?
    local depfile = target:depfile()
    local modified = _is_modified(target, depfile, buildinfo, program, linkflags)
    if not modified then
        return
    end

    -- clear the previous dependent info first
    io.save(depfile, {})

    -- expand object files with *.o/obj
    local objectfiles = {}
    for _, objectfile in ipairs(target:objectfiles()) do
        if objectfile:find("%*") then
            local matchfiles = os.match(objectfile)
            if matchfiles then
                table.join2(objectfiles, matchfiles)
            end
        else
            table.insert(objectfiles, objectfile)
        end
    end

    -- the target file
    local targetfile = target:targetfile()

    -- is verbose?
    local verbose = option.get("verbose")

    -- trace percent into
    cprintf("${green}[%02d%%]:${clear} ", (buildinfo.targetindex + 1) * 100 / buildinfo.targetcount)
    if verbose then
        cprint("${dim magenta}linking.$(mode) %s", path.filename(targetfile))
    else
        cprint("${magenta}linking.$(mode) %s", path.filename(targetfile))
    end

    -- trace verbose info
    if verbose then
        print(linker_instance:linkcmd(objectfiles, targetfile, {linkflags = linkflags}))
    end

    -- flush io buffer to update progress info
    io.flush()

    -- link it
    assert(linker_instance:link(objectfiles, targetfile, {linkflags = linkflags}))

    -- save program and flags to the dependent file
    io.save(depfile, {program = program, flags = linkflags, objectfiles = target:objectfiles()})
end

-- build target from sources
function _build_from_sources(target, buildinfo, sourcebatch, sourcekind)

    -- the target file
    local targetfile = target:targetfile()

    -- is verbose?
    local verbose = option.get("verbose")

    -- trace percent into
    cprintf("${green}[%02d%%]:${clear} ", (buildinfo.targetindex + 1) * 100 / buildinfo.targetcount)
    if verbose then
        cprint("${dim magenta}linking.$(mode) %s", path.filename(targetfile))
    else
        cprint("${magenta}linking.$(mode) %s", path.filename(targetfile))
    end

    -- trace verbose info
    if verbose then
        print(compiler.buildcmd(sourcebatch.sourcefiles, targetfile, {target = target, sourcekind = sourcekind}))
    end

    -- flush io buffer to update progress info
    io.flush()

    -- build it
    compiler.build(sourcebatch.sourcefiles, targetfile, {target = target, sourcekind = sourcekind})
end

-- build binary target
function build(target, buildinfo)

    -- only one source kind?
    local kindcount = 0
    local sourcekind = nil
    local sourcebatch = nil
    for kind, batch in pairs(target:sourcebatches()) do
        sourcekind  = kind
        sourcebatch = batch
        kindcount   = kindcount + 1
        if kindcount > 1 then
            break
        end
    end

    -- build target
    if kindcount == 1 and sourcekind and compiler.buildmode(sourcekind, "binary:sources", {target = target}) then
        _build_from_sources(target, buildinfo, sourcebatch, sourcekind)
    else
        _build_from_objects(target, buildinfo)
    end
end
