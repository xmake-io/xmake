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

-- get values from target
-- @see https://github.com/xmake-io/xmake/issues/3930 
local function _get_values_from_target(target, name)
    local values = {}
    for _, value in ipairs((target:get_from(name, "*"))) do
        table.join2(values, value)
    end
    return table.unique(values)
end

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

    -- add flags from target (includedirs, links, ...)
    local pathmaps = {
        {"includedirs",    "includedir"},
        {"sysincludedirs", "sysincludedir"},
        {"linkdirs",       "linkdir"}
    }
    for _, pathmap in ipairs(pathmaps) do
        local flags = compiler.map_flags("nim", pathmap[2], _get_values_from_target(target, pathmap[1]))
        if flags then
             table.join2(compflags, flags)
        end
    end

    local linkmaps = {
        {"links",    "link"},
        {"syslinks", "syslink"}
    }
    for _, linkmap in ipairs(linkmaps) do
        local flags = compiler.map_flags("nim", linkmap[2], _get_values_from_target(target, linkmap[1]))
        if flags then
             table.join2(compflags, flags)
        end
    end

    -- add flags from packages
    for _, pkg in ipairs(target:orderpkgs()) do
        for _, pathmap in ipairs(pathmaps) do
            local flags = compiler.map_flags("nim", pathmap[2], pkg:get(pathmap[1]))
            if flags then
                 table.join2(compflags, flags)
            end
        end
        for _, linkmap in ipairs(linkmaps) do
            local flags = compiler.map_flags("nim", linkmap[2], pkg:get(linkmap[1]))
            if flags then
                 table.join2(compflags, flags)
            end
        end
    end

    -- add rpathdirs to linker flags (for shared lib support)
    local rpathdirs_wrap = {}

    -- add rpathdirs from dependencies
    if target:is_binary() or target:is_shared() then
        for _, dep in ipairs(target:orderdeps()) do
            if dep:is_shared() then
                table.insert(rpathdirs_wrap, dep:targetdir())
            end
        end
    end

    if #rpathdirs_wrap > 0 then
        -- deduplicate
        rpathdirs_wrap = table.unique(rpathdirs_wrap)
        local rpathflags = compiler.map_flags("nim", "rpathdir", rpathdirs_wrap)
        if rpathflags then
             table.join2(compflags, rpathflags)
        end
    end

    -- add includedirs from dependencies (for static/shared lib with exportc)
    -- the dependencies will be compiled via imported symbol at the end
    -- we need pass includedirs of static/shared lib to the target
    local includedirs = {}
    for _, dep in ipairs(target:orderdeps()) do
        if dep:kind() == "static" or dep:kind() == "shared" or dep:kind() == "headeronly" then
            table.join2(includedirs, table.wrap(dep:get("includedirs")))
            table.join2(includedirs, table.wrap(dep:get("sysincludedirs")))
        end
    end
    if #includedirs > 0 then
        -- deduplicate
        includedirs = table.unique(includedirs)
        local includeflags = compiler.map_flags("nim", "includedir", includedirs)
        if includeflags then
             table.join2(compflags, includeflags)
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
