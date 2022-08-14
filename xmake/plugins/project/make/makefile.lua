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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        makefile.lua
--

-- imports
import("core.tool.compiler")
import("core.project.config")
import("core.project.project")
import("core.language.language")
import("core.platform.platform")
import("lib.detect.find_tool")

-- get log makefile
function _logfile()
    return vformat("$(buildir)/.build.log")
end

-- mkdir directory
function _mkdir(makefile, dir)
    if is_subhost("windows") then
        makefile:print("\t-@mkdir %s > NUL 2>&1", dir)
    else
        makefile:print("\t@mkdir -p %s", dir)
    end
end

-- copy file
function _cp(makefile, sourcefile, targetfile)
    if is_subhost("windows") then
        makefile:print("\t@copy /Y %s %s > NUL 2>&1", sourcefile, targetfile)
    else
        makefile:print("\t@cp %s %s", sourcefile, targetfile)
    end
end

-- try to remove the given file or directory
function _tryrm(makefile, filedir)
    if is_subhost("windows") then
        -- we attempt to delete it as file first, we remove it as directory if failed
        makefile:print("\t@del /F /Q %s > NUL 2>&1 || rmdir /S /Q %s > NUL 2>&1", filedir, filedir)
    else
        makefile:print("\t@rm -rf %s", filedir)
    end
end

-- remove the given files or directories
function _remove(makefile, filedirs)
    for _, filedir in ipairs(filedirs) do
        _tryrm(makefile, filedir)
    end
end

-- get program from target toolchains
function _get_program_from_target(target, toolkind)
    local program = target:get("toolchain." .. toolkind)
    if not program then
        local tools = target:get("tools") -- TODO: deprecated
        if tools then
            program = tools[toolkind]
        end
    end
    return program
end

-- make common flags
function _make_common_flags(target, sourcekind, sourcebatch)

    -- make source flags
    local sourceflags = {}
    local flags_stats = {}
    local files_count = 0
    local first_flags = nil
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do

        -- make compiler flags
        local flags = compiler.compflags(sourcefile, {target = target, sourcekind = sourcekind})
        for _, flag in ipairs(flags) do
            flags_stats[flag] = (flags_stats[flag] or 0) + 1
        end

        -- update files count
        files_count = files_count + 1

        -- save first flags
        if first_flags == nil then
            first_flags = flags
        end

        -- save source flags
        sourceflags[sourcefile] = flags
    end

    -- make common flags
    local commonflags = {}
    for _, flag in ipairs(first_flags) do
        if flags_stats[flag] >= files_count then
            table.insert(commonflags, flag)
        end
    end

    -- remove common flags from source flags
    local sourceflags_ = {}
    for sourcefile, flags in pairs(sourceflags) do
        local otherflags = {}
        for _, flag in ipairs(flags) do
            if flags_stats[flag] < files_count then
                table.insert(otherflags, flag)
            end
        end
        sourceflags_[sourcefile] = otherflags
    end

    -- ok?
    return commonflags, sourceflags_
end

-- make the object
function _make_object(makefile, target, sourcefile, objectfile, sourceflags)

    -- get the source file kind
    local sourcekind = language.sourcekind_of(sourcefile)

    -- get program
    local program_global = false
    local program = _get_program_from_target(target, sourcekind)
    if not program then
        program = platform.tool(sourcekind)
        program_global = true
    end

    -- get complier flags
    local compflags = sourceflags[sourcefile]

    -- make command
    local macro = "$\01" .. target:name() .. '_' .. sourcekind:upper() .. "FLAGS\02"
    local command = compiler.compcmd(sourcefile, objectfile, {target = target, compflags = table.join(macro, compflags)})
    command = command:gsub('\01', '(')
    command = command:gsub('\02', ')')

    -- replace program to $(XX)
    local p, e = command:find("\"" .. program .. "\"", 1, true)
    if not p then
        p, e = command:find(program, 1, true)
    end
    if p then
        if program_global then
            command = format("%s$(%s)%s", command:sub(1, p - 1), sourcekind:upper(), command:sub(e + 1))
        else
            command = format("%s$(%s_%s)%s", command:sub(1, p - 1), target:name(), sourcekind:upper(), command:sub(e + 1))
        end
    end

    -- replace ccache to $(CCACHE)
    local ccache = config.get("ccache") ~= false and find_tool("ccache")
    if ccache then
        p, e = command:find(ccache.program, 1, true)
        if p then
            command = format("%s$(%s)%s", command:sub(1, p - 1), "CCACHE", command:sub(e + 1))
        end
    end

    -- make head
    makefile:printf("%s:", objectfile)

    -- make dependence
    makefile:print(" %s", sourcefile)

    -- make body
    makefile:print("\t@echo %scompiling.$(mode) %s", ccache and "ccache " or "", sourcefile)
    _mkdir(makefile, path.directory(objectfile))
    makefile:writef("\t@%s > %s 2>&1\n", command, _logfile())

    -- make tail
    makefile:print("")
end

-- make objects
function _make_objects(makefile, target, sourcekind, sourcebatch, sourceflags)
    local handled_objects = target:data("makefile.handled_objects")
    if not handled_objects then
        handled_objects = {}
        target:data_set("makefile.handled_objects", handled_objects)
    end
    for index, objectfile in ipairs(sourcebatch.objectfiles) do
        -- remove repeat
        -- this is because some rules will repeatedly bind the same sourcekind, e.g. `rule("c++.build.modules.builder")`
        if not handled_objects[objectfile] then
            _make_object(makefile, target, sourcebatch.sourcefiles[index], objectfile, sourceflags)
            handled_objects[objectfile] = true
        end
    end
end

-- make phony
function _make_phony(makefile, target)

    -- make dependence for the dependent targets
    makefile:printf("%s:", target:name())
    for _, dep in ipairs(target:get("deps")) do
        makefile:write(" " .. dep)
    end
    makefile:print("")
end

-- make target
function _make_target(makefile, target, targetflags)

    -- https://github.com/xmake-io/xmake/issues/2337
    target:data_set("plugin.project.kind", "makefile")

    -- is phony target?
    if target:is_phony() then
        return _make_phony(makefile, target)
    end

    -- make head
    local targetfile = target:targetfile()
    local targetname = target:name()

    -- rules like `./target` and `target` are equivalent and can causes issues
    -- for cases where targetdir is .
    -- in these cases, the targetfile rule is not created
    if targetfile == "./" .. targetname then
        makefile:printf("%s:", targetname)
    else
        makefile:print("%s: %s", targetname, targetfile)
        makefile:printf("%s:", targetfile)
    end

    -- make dependence for the dependent targets
    for _, depname in ipairs(target:get("deps")) do
        local dep = project.target(depname)
        makefile:write(" " .. (dep:is_phony() and depname or dep:targetfile()))
    end

    -- make dependence for objects
    local objectfiles = target:objectfiles()
    for _, objectfile in ipairs(objectfiles) do
        makefile:write(" " .. objectfile)
    end

    -- make dependence end
    makefile:print("")

    -- get linker kind
    local linkerkind = target:linker():kind()

    -- get program
    local program_global = false
    local program = _get_program_from_target(target, linkerkind)
    if not program then
        program = platform.tool(linkerkind)
        program_global = true
    end

    -- get command
    local command = target:linkcmd()

    -- replace linkflags to $(XX)
    local p, e = command:find(os.args(target:linkflags()), 1, true)
    if p then
        command = format("%s$(%s_%sFLAGS)%s", command:sub(1, p - 1), target:name(), (linkerkind:upper():gsub('%-', '_')), command:sub(e + 1))
    end

    -- replace program to $(XX)
    p, e = command:find("\"" .. program .. "\"", 1, true)
    if not p then
        p, e = command:find(program, 1, true)
    end
    if p then
        if program_global then
            command = format("%s$(%s)%s", command:sub(1, p - 1), (linkerkind:upper():gsub('%-', '_')), command:sub(e + 1))
        else
            command = format("%s$(%s_%s)%s", command:sub(1, p - 1), target:name(), (linkerkind:upper():gsub('%-', '_')), command:sub(e + 1))
        end
    end

    -- make body
    makefile:print("\t@echo linking.$(mode) %s", path.filename(targetfile))
    _mkdir(makefile, path.directory(targetfile))
    makefile:writef("\t@%s > %s 2>&1\n", command, _logfile())

    -- TODO make header directories (deprecated)
    local dstheaderdirs = {}
    local srcheaders, dstheaders = target:headers()
    for _, dstheader in ipairs(dstheaders) do
        dstheaderdirs[path.directory(dstheader)] = true
    end
    for dstheaderdir, _ in pairs(dstheaderdirs) do
        _mkdir(makefile, dstheaderdir)
    end

    -- copy headers
    if srcheaders and dstheaders then
        local i = 1
        for _, srcheader in ipairs(srcheaders) do
            local dstheader = dstheaders[i]
            if dstheader then
                _cp(makefile, srcheader, dstheader)
            end
            i = i + 1
        end
    end

    -- make tail
    makefile:print("")

    -- build source batches
    for _, sourcebatch in pairs(target:sourcebatches()) do
        local sourcekind = sourcebatch.sourcekind
        if sourcekind then
            -- compile source files to single object at once
            local sourceflags = targetflags[target:name() .. '_' .. sourcekind:upper()]
            _make_objects(makefile, target, sourcekind, sourcebatch, sourceflags)
        end
    end
end

-- make all
function _make_all(makefile)

    -- make head
   makefile:print([[# this is the build file for project %s
# it is autogenerated by the xmake build system.
# do not edit by hand.
]], project.name() or "")

    -- make variables for ccache
    local ccache = find_tool("ccache")
    if ccache then
        makefile:print("CCACHE=" .. ccache.program)
    end

    -- make variables for source kinds
    for sourcekind, _ in pairs(language.sourcekinds()) do
        local program = platform.tool(sourcekind)
        if program and program ~= "" then
            makefile:print("%s=%s", sourcekind:upper(), program)
        end
    end
    makefile:print("")

    -- make variables for linker kinds
    local linkerkinds = {}
    for _, _linkerkinds in pairs(language.targetkinds()) do
        table.join2(linkerkinds, _linkerkinds)
    end
    for _, linkerkind in ipairs(table.unique(linkerkinds)) do
        local program = platform.tool(linkerkind)
        if program and program ~= "" then
            makefile:print("%s=%s", (linkerkind:upper():gsub('%-', '_')), program)
        end
    end
    makefile:print("")

    -- TODO
    -- disable precompiled header first
    for _, target in pairs(project.targets()) do
        target:set("pcheader", nil)
        target:set("pcxxheader", nil)
    end

    -- make variables for target
    local targetflags = {}
    for targetname, target in pairs(project.targets()) do
        if not target:is_phony() then

            -- make target linker
            local program = _get_program_from_target(target, target:linker():kind())
            if program then
                makefile:print("%s_%s=%s", targetname, target:linker():kind():upper(), program)
            end

            -- make target flags
            for _, sourcebatch in pairs(target:sourcebatches()) do
                local sourcekind = sourcebatch.sourcekind
                if sourcekind then

                    -- make source compiler
                    local program = _get_program_from_target(target, sourcekind)
                    if program then
                        makefile:print("%s_%s=%s", targetname, sourcekind:upper(), program)
                    end

                    -- make source flags
                    local commonflags, sourceflags = _make_common_flags(target, sourcekind, sourcebatch)
                    makefile:print("%s_%sFLAGS=%s", targetname, sourcekind:upper(), os.args(commonflags))
                    targetflags[targetname .. '_' .. sourcekind:upper()] = sourceflags
                end
            end
            makefile:print("%s_%sFLAGS=%s", targetname, target:linker():kind():upper(), os.args(target:linkflags()))
        end
    end
    makefile:print("")

    -- make all
    local default = ""
    for targetname, target in pairs(project.targets()) do
        if target:is_default() then
            default = default .. " " .. targetname
        end
    end
    makefile:print("default: %s\n", default)
    local all = ""
    for targetname, _ in pairs(project.targets()) do
        all = all .. " " .. targetname
    end
    makefile:print("all: %s\n", all)
    makefile:print(".PHONY: default all %s\n", all)

    -- make it for all targets
    for _, target in pairs(project.targets()) do
        _make_target(makefile, target, targetflags)
    end
end

-- clean target
function _clean_target(makefile, target)

    -- make head
    makefile:printf("clean_%s: ", target:name())

    -- make dependence for the dependent targets
    for _, dep in ipairs(target:get("deps")) do
        makefile:write(" clean_" .. dep)
    end

    -- make dependence end
    makefile:print("")

    -- make body
    if not target:is_phony() then

        -- remove the target file
        _remove(makefile, target:targetfile())

        -- remove the symbol file
        _remove(makefile, target:symbolfile())

        -- remove the object files
        _remove(makefile, target:objectfiles())

        -- TODO remove the header files (deprecated)
        local _, dstheaders = target:headers()
        _remove(makefile, dstheaders)
    end

    -- make tail
    makefile:print("")
end

-- clean all
function _clean_all(makefile)

    -- clean all
    local all = ""
    for targetname, _ in pairs(project.targets()) do
        all = all .. " clean_" .. targetname
    end
    makefile:print("clean: %s\n", all)

    -- clean targets
    for _, target in pairs(project.targets()) do
        _clean_target(makefile, target)
    end
end

-- make
function make(outputdir)

    -- enter project directory
    local oldir = os.cd(os.projectdir())

    -- remove the log makefile first
    os.rm(_logfile())

    -- open the makefile
    local makefile = io.open(path.join(outputdir, "makefile"), "w")

    -- make all
    _make_all(makefile)

    -- clean all
    _clean_all(makefile)

    -- close the makefile
    makefile:close()

    -- leave project directory
    os.cd(oldir)
end
