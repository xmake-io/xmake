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
-- @file        makefile.lua
--

-- imports
import("core.tool.compiler")
import("core.project.project")
import("core.language.language")
import("core.platform.platform")

-- get log makefile
function _logfile()
    return vformat("$(buildir)/.build.log")
end

-- mkdir directory
function _mkdir(makefile, dir)
    if is_plat("windows") then
        makefile:print("\t-@mkdir %s > NUL 2>&1", dir)
    else
        makefile:print("\t@mkdir -p %s", dir)
    end
end

-- copy file
function _cp(makefile, sourcefile, targetfile)
    if is_plat("windows") then
        makefile:print("\t@copy /Y %s %s > NUL 2>&1", sourcefile, targetfile)
    else
        makefile:print("\t@cp %s %s", sourcefile, targetfile)
    end
end

-- try to remove the given file or directory
function _tryrm(makefile, filedir)

    -- remove it
    if is_plat("windows") then
        if os.isdir(filedir) then
            makefile:print("\t@rmdir /S /Q %s > NUL 2>&1", filedir)
        elseif os.isfile(filedir) then
            makefile:print("\t@del /F /Q %s > NUL 2>&1", filedir)
        end
    else
        if os.isdir(filedir) then
            makefile:print("\t@rm -rf %s", filedir)
        elseif os.isfile(filedir) then
            makefile:print("\t@rm -f %s", filedir)
        end
    end
end

-- remove the given files or directories
function _remove(makefile, filedirs)
    for _, filedir in ipairs(filedirs) do
        _tryrm(makefile, filedir)
    end
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
        if flags_stats[flag] == files_count then
            table.insert(commonflags, flag)
        end
    end

    -- remove common flags from source flags
    local sourceflags_ = {}
    for sourcefile, flags in pairs(sourceflags) do
        local otherflags = {}
        for _, flag in ipairs(flags) do
            if flags_stats[flag] ~= files_count then
                table.insert(otherflags, flag)
            end
        end
        sourceflags_[sourcefile] = otherflags
    end

    -- ok?
    return commonflags, sourceflags_
end

-- make the object for the *.[o|obj] source file
function _make_object_for_object(makefile, target, sourcefile, objectfile)

    -- make command
    local cmd = format("xmake l cp %s %s", sourcefile, objectfile)

    -- make head
    makefile:printf("%s:", objectfile)

    -- make dependence
    makefile:print(" %s", sourcefile)

    -- make body
    makefile:print("\t@echo inserting.$(mode) %s", sourcefile)
    makefile:print("\t@%s", cmd)

    -- make tail
    makefile:print("")

end

-- make the object for the *.[a|lib] source file
function _make_object_for_static(makefile, target, sourcefile, objectfile)

    -- not supported
    raise("source file: %s not supported!", sourcefile)
end

-- make the object
function _make_object(makefile, target, sourcefile, objectfile, sourceflags)

    -- get the source file kind
    local sourcekind = language.sourcekind_of(sourcefile)

    -- make the object for the *.o/obj source makefile
    if sourcekind == "obj" then 
        return _make_object_for_object(makefile, target, sourcefile, objectfile)
    -- make the object for the *.[a|lib] source file
    elseif sourcekind == "lib" then 
        return _make_object_for_static(makefile, target, sourcefile, objectfile)
    end

    -- get program
    local program = platform.tool(sourcekind)

    -- get complier flags
    local compflags = sourceflags[sourcefile]

    -- make command
    local macro = "$(" .. target:name() .. '_' .. sourcekind:upper() .. ")"
    local command = compiler.compcmd(sourcefile, objectfile, {compflags = table.join(macro, compflags)})

    -- replace program to $(XX)
    local p, e = command:find("\"" .. program .. "\"", 1, true)
    if not p then
        p, e = command:find(program, 1, true)
    end
    if p then
        command = format("%s$(%s)%s", command:sub(1, p - 1), sourcekind:upper(), command:sub(e + 1)) 
    end

    -- replace ccache to $(CCACHE)
    local ccache = false
    p, e = command:find("ccache", 1, true)
    if p then
        command = format("%s$(%s)%s", command:sub(1, p - 1), "CCACHE", command:sub(e + 1))
        ccache = true
    end

    -- make head
    makefile:printf("%s:", objectfile)

    -- make dependence
    makefile:print(" %s", sourcefile)

    -- make body
    makefile:print("\t@echo %scompiling.$(mode) %s", ifelse(ccache, "ccache ", ""), sourcefile)
    _mkdir(makefile, path.directory(objectfile))
    makefile:writef("\t@%s > %s 2>&1\n", command, _logfile())

    -- make tail
    makefile:print("")
end
 
-- make objects
function _make_objects(makefile, target, sourcekind, sourcebatch, sourceflags)

    -- make them
    for index, objectfile in ipairs(sourcebatch.objectfiles) do
        _make_object(makefile, target, sourcebatch.sourcefiles[index], objectfile, sourceflags)
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

    -- is phony target?
    if target:isphony() then
        return _make_phony(makefile, target)
    end

    -- make head
    local targetfile = target:targetfile()
    makefile:print("%s: %s", target:name(), targetfile)
    makefile:printf("%s:", targetfile)

    -- make dependence for the dependent targets
    for _, dep in ipairs(target:get("deps")) do
        makefile:write(" " .. project.target(dep):targetfile())
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
    local program = platform.tool(linkerkind)

    -- get command
    local command = target:linkcmd()

    -- replace linkflags to $(XX)
    local p, e = command:find(os.args(target:linkflags()), 1, true)
    if p then
        command = format("%s$(%s_%s)%s", command:sub(1, p - 1), target:name(), (linkerkind:upper():gsub('%-', '_')), command:sub(e + 1)) 
    end

    -- replace program to $(XX)
    p, e = command:find("\"" .. program .. "\"", 1, true)
    if not p then
        p, e = command:find(program, 1, true)
    end
    if p then
        command = format("%s$(%s)%s", command:sub(1, p - 1), (linkerkind:upper():gsub('%-', '_')), command:sub(e + 1)) 
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

    -- make variables for ccache
    makefile:print("CCACHE=ccache")

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

    -- make variables for target flags
    local targetflags = {}
    for targetname, target in pairs(project.targets()) do
        if not target:isphony() then
            for _, sourcebatch in pairs(target:sourcebatches()) do
                local sourcekind = sourcebatch.sourcekind
                if sourcekind then
                    local commonflags, sourceflags = _make_common_flags(target, sourcekind, sourcebatch)
                    makefile:print("%s_%s=%s", targetname, sourcekind:upper(), os.args(commonflags))
                    targetflags[targetname .. '_' .. sourcekind:upper()] = sourceflags
                end
            end
            makefile:print("%s_%s=%s", targetname, target:linker():kind():upper(), os.args(target:linkflags()))
        end
    end
    makefile:print("")

    -- make all
    local default = ""
    for targetname, target in pairs(project.targets()) do
        local isdefault = target:get("default")
        if isdefault == nil or isdefault == true then
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
    if not target:isphony() then

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
