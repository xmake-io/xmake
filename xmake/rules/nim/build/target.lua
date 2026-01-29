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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        target.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.tool.compiler")
import("core.project.depend")
import("utils.progress")

-- generate dependency info
function _generate_dependinfo(compinst, compflags, sourcefiles, dependinfo)

    -- generate dependency file (.deps)
    local flags = {}
    local nimcache
    for _, flag in ipairs(compflags) do
        table.insert(flags, flag)
        if flag:startswith("--nimcache:") then
            nimcache = flag:sub(12)
        end
    end
    table.insert(flags, "--genScript")

    -- run nim --genScript to generate .deps file
    local program = compinst:program()
    local argv = table.join("c", flags, sourcefiles)
    os.runv(program, argv, {envs = compinst:runenvs()})

    -- parse .deps file
    if nimcache then
        for _, sourcefile in ipairs(sourcefiles) do
            local filename = path.basename(sourcefile)
            local depsfile = path.join(nimcache, filename .. ".deps")
            if os.isfile(depsfile) then
                local depsdata = io.readfile(depsfile)
                if depsdata then
                    for _, line in ipairs(depsdata:split("\n")) do
                        line = line:trim()
                        if #line > 0 then
                            table.insert(dependinfo.files, line)
                        end
                    end
                end
            end
        end
    end
end

-- add dependency flags
function _add_dependency_flags(target, compinst, compflags)

    -- add includedirs from packages
    for _, pkg in ipairs(target:orderpkgs()) do
        local pkg_includedirs = pkg:get("includedirs")
        if pkg_includedirs then
            for _, dir in ipairs(pkg_includedirs) do
                local includeflags = compinst:_tool():nf_includedir(dir)
                if includeflags then
                     table.join2(compflags, includeflags)
                end
            end
        end
        local pkg_sysincludedirs = pkg:get("sysincludedirs")
        if pkg_sysincludedirs then
            for _, dir in ipairs(pkg_sysincludedirs) do
                local tool = compinst:_tool()
                local includeflags = tool.nf_sysincludedir and tool:nf_sysincludedir(dir) or tool:nf_includedir(dir)
                if includeflags then
                     table.join2(compflags, includeflags)
                end
            end
        end
    end

    -- add rpathdirs to linker flags (for shared lib support)
    local rpathdirs_wrap = {}

    -- add rpathdirs from dependencies
    if target:kind() == "binary" or target:kind() == "shared" then
        for _, dep in ipairs(target:orderdeps()) do
            if dep:kind() == "shared" then
                table.insert(rpathdirs_wrap, dep:targetdir())
            end
        end
    end

    if #rpathdirs_wrap > 0 then
        -- deduplicate
        rpathdirs_wrap = table.unique(rpathdirs_wrap)
        for _, rpathdir in ipairs(rpathdirs_wrap) do
             local rpathflags = compinst:_tool():nf_rpathdir(rpathdir)
             if rpathflags then
                 table.join2(compflags, rpathflags)
             end
        end
    end

    -- add includedirs from dependencies (for static/shared lib with exportc)
    -- the dependencies will be compiled via imported symbol at the end
    -- we need pass includedirs of static/shared lib to the target
    local includedirs = {}
    for _, dep in ipairs(target:orderdeps()) do
        if dep:kind() == "static" or dep:kind() == "shared" or dep:kind() == "headeronly" then
            table.join2(includedirs, dep:get("includedirs"))
            table.join2(includedirs, dep:get("sysincludedirs"))
        end
    end
    if #includedirs > 0 then
        -- deduplicate
        includedirs = table.unique(includedirs)
        for _, includedir in ipairs(includedirs) do
             local includeflags = compinst:_tool():nf_includedir(includedir)
             if includeflags then
                 table.join2(compflags, includeflags)
             end
        end
    end
end

-- build the source files
function build_sourcefiles(target, sourcebatch, opt)

    -- get the target file
    local targetfile = target:targetfile()

    -- get source files and kind
    local sourcefiles = sourcebatch.sourcefiles
    local sourcekind  = sourcebatch.sourcekind

    -- get depend file
    local dependfile = target:dependfile(targetfile)

    -- load compiler
    local compinst = compiler.load(sourcekind, {target = target})

    -- get compile flags
    local compflags = compinst:compflags({target = target})

    -- add dependency flags
    _add_dependency_flags(target, compinst, compflags)

    -- load dependent info
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

    -- need build this object?
    local depvalues = {compinst:program(), compflags}
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(targetfile), values = depvalues}) then
        return
    end

    -- trace progress into
    progress.show(opt.progress, "${color.build.target}linking.$(mode) %s", path.filename(targetfile))

    -- trace verbose info
    vprint(compinst:buildcmd(sourcefiles, targetfile, {target = target, compflags = compflags}))

    -- flush io buffer to update progress info
    io.flush()

    -- compile it
    dependinfo.files = {}
    assert(compinst:build(sourcefiles, targetfile, {target = target, dependinfo = dependinfo, compflags = compflags}))

    -- generate dependency file (.deps)
    _generate_dependinfo(compinst, compflags, sourcefiles, dependinfo)

    -- update files and values to the dependent file
    dependinfo.values = depvalues
    table.join2(dependinfo.files, sourcefiles)
    depend.save(dependinfo, dependfile)
end

-- build target
function main(target, opt)

    -- @note only support one source kind!
    local sourcebatches = target:sourcebatches()
    if sourcebatches then
        local sourcebatch = sourcebatches["nim.build"]
        if sourcebatch then
            build_sourcefiles(target, sourcebatch, opt)
        end
    end
end
