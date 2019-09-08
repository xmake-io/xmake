--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        static.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.tool.linker")
import("core.tool.compiler")
import("core.project.depend")
import("object")

-- do link target 
function _do_link_target(target, opt)

    -- load linker instance
    local linkinst = linker.load(target:targetkind(), target:sourcekinds(), {target = target})

    -- get link flags
    local linkflags = linkinst:linkflags({target = target})

    -- load dependent info 
    local dependfile = target:dependfile()
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

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

    -- need build this target?
    local depfiles = target:objectfiles()
    local depvalues = {linkinst:program(), linkflags}
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(target:targetfile()), values = depvalues, files = depfiles}) then
        return 
    end

    -- TODO make headers (deprecated)
    local srcheaders, dstheaders = target:headers()
    if srcheaders and dstheaders then
        local i = 1
        for _, srcheader in ipairs(srcheaders) do
            local dstheader = dstheaders[i]
            if dstheader then
                os.cp(srcheader, dstheader)
            end
            i = i + 1
        end
    end


    -- the target file
    local targetfile = target:targetfile()

    -- is verbose?
    local verbose = option.get("verbose")

    -- trace progress info
    cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", opt.progress.stop)
    if verbose then
        cprint("${dim color.build.target}archiving.$(mode) %s", path.filename(targetfile))
    else
        cprint("${color.build.target}archiving.$(mode) %s", path.filename(targetfile))
    end

    -- trace verbose info
    if verbose then
        -- show the full link command with raw arguments, it will expand @xxx.args for msvc/link on windows
        print(linkinst:linkcmd(objectfiles, targetfile, {linkflags = linkflags, rawargs = true}))
    end

    -- flush io buffer to update progress info
    io.flush()

    -- link it
    assert(linkinst:link(objectfiles, targetfile, {linkflags = linkflags}))

    -- update files and values to the dependent file
    dependinfo.files  = depfiles
    dependinfo.values = depvalues
    depend.save(dependinfo, dependfile)
end

-- on link the given target
function _on_link_target(target, opt)

    -- link target with rules
    local done = false
    for _, r in ipairs(target:orderules()) do
        local on_link = r:script("link")
        if on_link then
            on_link(target, opt)
            done = true
        end
    end
    if done then return end

    -- do link
    _do_link_target(target, opt)
end

-- link target
function _link_target(target, opt)

    -- get progress
    local progress = opt.progress
    local progress_before = {start = progress.start, stop = progress.start}
    local progress_after  = {start = progress.stop, stop = progress.stop}

    -- do before link for target
    opt.progress = progress_before
    local before_link = target:script("link_before")
    if before_link then
        before_link(target, opt)
    end

    -- do before link for rules
    for _, r in ipairs(target:orderules()) do
        local before_link = r:script("link_before")
        if before_link then
            before_link(target, opt)
        end
    end

    -- on link
    opt.progress = progress
    target:script("link", _on_link_target)(target, table.join(opt, {origin = _do_link_target}))

    -- do after link for target
    opt.progress = progress_after
    local after_link = target:script("link_after")
    if after_link then
        after_link(target, opt)
    end

    -- do after link for rules
    for _, r in ipairs(target:orderules()) do
        local after_link = r:script("link_after")
        if after_link then
            after_link(target, opt)
        end
    end
end

-- build static target
function build(target, opt)

    -- separate progress
    local progress = opt.progress
    local progress_mid = math.max(progress.start, progress.stop - 1)

    -- build objects
    opt = table.copy(opt)
    opt.progress = {start = progress.start, stop = progress_mid}
    object.build(target, opt)

    -- link target
    opt.progress = {start = progress_mid, stop = progress.stop}
    _link_target(target, opt)
end
