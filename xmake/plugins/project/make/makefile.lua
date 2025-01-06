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
import("core.base.colors")
import("core.tool.compiler")
import("core.project.config")
import("core.project.project")
import("core.language.language")
import("core.platform.platform")
import("lib.detect.find_tool")
import("private.utils.batchcmds")
import("private.utils.rule_groups")
import("plugins.project.utils.target_cmds", {rootdir = os.programdir()})

-- tranlate path
function _translate_path(filepath, outputdir)
    filepath = path.translate(filepath)
    if filepath == "" then
        return ""
    end
    if path.is_absolute(filepath) then
        if filepath:startswith(project.directory()) then
            return path.relative(filepath, outputdir)
        end
        return filepath
    else
        return path.relative(path.absolute(filepath), outputdir)
    end
end

-- get relative unix path
function _get_relative_unix_path(filepath, outputdir)
    filepath = _translate_path(filepath, outputdir)
    filepath = path.translate(filepath)
    return os.args(filepath)
end

-- translate flag
function _translate_flag(flag, outputdir)
    if flag then
        if path.instance_of(flag) then
            flag = flag:clone():set(_get_relative_unix_path(flag:rawstr(), outputdir)):str()
        elseif path.is_absolute(flag) then
            flag = _get_relative_unix_path(flag, outputdir)
        elseif flag:startswith("-fmodule-file=") then
            flag = "-fmodule-file=" .. _get_relative_unix_path(flag:sub(15), outputdir)
        elseif flag:startswith("-fmodule-mapper=") then
            flag = "-fmodule-mapper=" .. _get_relative_unix_path(flag:sub(17), outputdir)
        elseif flag:startswith("-isystem") and #flag > 8 then
            flag = "-isystem" .. _get_relative_unix_path(flag:sub(9), outputdir)
        elseif flag:startswith("-I") and #flag > 2 then
            flag = "-I" .. _get_relative_unix_path(flag:sub(3), outputdir)
        elseif flag:startswith("-L") and #flag > 2 then
            flag = "-L" .. _get_relative_unix_path(flag:sub(3), outputdir)
        elseif flag:startswith("-F") and #flag > 2 then
            flag = "-F" .. _get_relative_unix_path(flag:sub(3), outputdir)
        elseif flag:match("(.+)=(.+)") then
            local k, v = flag:match("(.+)=(.+)")
            if v and v:endswith(".ifc") then -- e.g. hello=xxx/hello.ifc
                flag = k .. "=" .. _get_relative_unix_path(v, outputdir)
            end
        end
    end
    return flag
end

-- translate flags
function _translate_flags(flags, outputdir)
    local result = {}
    for _, flag in ipairs(flags) do
        if type(flag) == "table" and not path.instance_of(flag) then
            for _, v in ipairs(flag) do
                table.insert(result, _translate_flag(v, outputdir))
            end
        else
            table.insert(result, _translate_flag(flag, outputdir))
        end
    end
    return result
end

-- get program from target toolchains
function _get_program_from_target(target, toolkind)
    local program = target:get("toolchain." .. toolkind)
    if not program then
        program, _ = target:tool(toolkind)
    end
    return program
end

-- get common flags
function _get_common_flags(target, sourcekind, sourcebatch)

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
    return commonflags, sourceflags_
end

-- get command: mkdir
function _get_cmd_mkdir(dir)
    if is_subhost("windows") then
        return string.format("-@mkdir %s > NUL 2>&1", dir)
    else
        return string.format("@mkdir -p %s", dir)
    end
end

-- get command: cp
function _get_cmd_cp(sourcefile, targetfile)
    if is_subhost("windows") then
        return string.format("@copy /Y %s %s > NUL 2>&1", sourcefile, targetfile)
    else
        return string.format("@cp %s %s", sourcefile, targetfile)
    end
end

-- get command: mv
function _get_cmd_mv(sourcefile, targetfile)
    if is_subhost("windows") then
        return string.format("@ren %s %s > NUL 2>&1", sourcefile, targetfile)
    else
        return string.format("@mv %s %s", sourcefile, targetfile)
    end
end

-- get command: ln
function _get_cmd_ln(sourcefile, targetfile)
    if is_subhost("windows") then
        if os.isdir(sourcefile) then
            return string.format("@mklink /D %s %s > NUL 2>&1", sourcefile, targetfile)
        else
            return string.format("@mklink %s %s > NUL 2>&1", sourcefile, targetfile)
        end
    else
        return string.format("@ln -s %s %s", sourcefile, targetfile)
    end
end

-- get command: cpdir
function _get_cmd_cpdir(sourcedir, targetdir)
    if is_subhost("windows") then
        return string.format("@copy /Y %s %s > NUL 2>&1", sourcedir, targetdir)
    else
        return string.format("@cp -r %s %s", sourcedir, targetdir)
    end
end

-- get command: rm
function _get_cmd_rm(filedir)
    if is_subhost("windows") then
        -- we attempt to delete it as file first, we remove it as directory if failed
        return string.format("@del /F /Q %s > NUL 2>&1 || rmdir /S /Q %s > NUL 2>&1", filedir, filedir)
    else
        return string.format("@rm -rf %s", filedir)
    end
end

-- get command: rmdir
function _get_cmd_rmdir(filedir)
    if is_subhost("windows") then
        return string.format("@rmdir /S /Q %s > NUL 2>&1", filedir)
    else
        return string.format("@rm -rf %s", filedir)
    end
end

-- get command: echo
function _get_cmd_echo(str)
    return string.format("@echo %s", colors.ignore(str))
end

-- get command: cd
function _get_cmd_cd(dir)
    return string.format("@cd %s", dir)
end

-- get command string
function _get_command_string(cmd, outputdir)
    local kind = cmd.kind
    local opt = cmd.opt
    if cmd.program then
        -- @see https://github.com/xmake-io/xmake/discussions/2156
        local argv = {}
        for _, v in ipairs(cmd.argv) do
            table.insert(argv, _translate_flag(v, outputdir))
        end
        local command = _get_relative_unix_path(cmd.program) .. " " .. os.args(argv)
        if opt and opt.curdir then
            wprint("curdir has been not supported in batchcmds:execv() for makefile generator!")
        end
        return "%$(VV)" .. command
    elseif kind == "cp" then
        if os.isdir(cmd.srcpath) then
            return _get_cmd_cpdir(get_relative_unix_path(cmd.srcpath, outputdir), _get_relative_unix_path(cmd.dstpath, outputdir))
        else
            return _get_cmd_cp(_get_relative_unix_path(cmd.srcpath, outputdir), _get_relative_unix_path(cmd.dstpath, outputdir))
        end
    elseif kind == "rm" then
        return _get_cmd_rm(_get_relative_unix_path(cmd.filepath, outputdir))
    elseif kind == "rmdir" then
        return _get_cmd_rmdir(_get_relative_unix_path(cmd.dir, outputdir))
    elseif kind == "mv" then
        return _get_cmd_mv(_get_relative_unix_path(cmd.srcpath, outputdir), _get_relative_unix_path(cmd.dstpath, outputdir))
    elseif kind == "ln" then
        return _get_cmd_ln(_get_relative_unix_path(cmd.srcpath, outputdir), _get_relative_unix_path(cmd.dstpath, outputdir))
    elseif kind == "cd" then
        return _get_cmd_cd(_get_relative_unix_path(cmd.dir, outputdir))
    elseif kind == "mkdir" then
        return _get_cmd_mkdir(_get_relative_unix_path(cmd.dir, outputdir))
    elseif kind == "show" then
        return _get_cmd_echo(cmd.showtext)
    end
end

-- remove the given files or directories
function _add_remove_files(makefile, filedirs, outputdir)
    for _, filedir in ipairs(filedirs) do
        filedir = _get_relative_unix_path(filedir, outputdir)
        makefile:print("\t%s", _get_cmd_rm(filedir))
    end
end

-- add header
function _add_header(makefile)
   makefile:print([[# this is the build file for project %s
# it is autogenerated by the xmake build system.
# do not edit by hand.
]], project.name() or "")
end

-- add switches
function _add_switches(makefile)
    if is_subhost("windows") then
        makefile:print("!if \"%$(VERBOSE)\" != \"1\"")
        makefile:print("VV=@")
        makefile:print("!endif")
    else
        makefile:print("ifneq (%$(VERBOSE),1)")
        makefile:print("VV=@")
        makefile:print("endif")
    end
    makefile:print("")
end

-- add toolchains
function _add_toolchains(makefile, outputdir)

    -- add ccache
    local ccache = find_tool("ccache")
    if ccache then
        makefile:print("CCACHE=" .. ccache.program)
    end

    -- add compilers
    for sourcekind, _ in pairs(language.sourcekinds()) do
        local program = platform.tool(sourcekind)
        if program and program ~= "" then
            makefile:print("%s=%s", sourcekind:upper(), program)
        end
    end
    makefile:print("")

    -- add linkers
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

    -- add toolchains from targets
    for targetname, target in pairs(project.targets()) do
        if not target:is_phony() then
            local program = _get_program_from_target(target, target:linker():kind())
            if program then
                makefile:print("%s_%s=%s", targetname, target:linker():kind():upper(), program)
            end
            for _, sourcebatch in pairs(target:sourcebatches()) do
                local sourcekind = sourcebatch.sourcekind
                if sourcekind then
                    local program = _get_program_from_target(target, sourcekind)
                    if program then
                        makefile:print("%s_%s=%s", targetname, sourcekind:upper(), program)
                    end
                end
            end
        end
    end
    makefile:print("")
end

-- add flags
function _add_flags(makefile, targetflags, outputdir)
    for targetname, target in pairs(project.targets()) do
        if not target:is_phony() then
            for _, sourcebatch in pairs(target:sourcebatches()) do
                local sourcekind = sourcebatch.sourcekind
                if sourcekind then
                    local commonflags, sourceflags = _get_common_flags(target, sourcekind, sourcebatch)
                    makefile:print("%s_%sFLAGS=%s", targetname, sourcekind:upper(), os.args(_translate_flags(commonflags, outputdir)))
                    targetflags[targetname .. '_' .. sourcekind:upper()] = sourceflags
                end
            end
            makefile:print("%s_%sFLAGS=%s", targetname, target:linker():kind():upper(), os.args(_translate_flags(target:linkflags(), outputdir)))
        end
    end
    makefile:print("")
end

-- add build object
function _add_build_object(makefile, target, sourcefile, objectfile, sourceflags, outputdir, precmds_label)

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
    local compflags = _translate_flags(sourceflags[sourcefile], outputdir)

    -- translate file paths
    sourcefile = _get_relative_unix_path(sourcefile, outputdir)
    objectfile = _get_relative_unix_path(objectfile, outputdir)

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
    if precmds_label then
        makefile:printf(" %s", precmds_label)
    end

    -- make dependence
    makefile:print(" %s", sourcefile)

    -- make body
    makefile:print("\t%s", _get_cmd_echo(string.format("%scompiling.$(mode) %s", ccache and "ccache " or "", sourcefile)))
    makefile:print("\t%s", _get_cmd_mkdir(path.directory(objectfile)))
    makefile:writef("\t$(VV)%s\n", command)

    -- make tail
    makefile:print("")
end

-- add build objects
function _add_build_objects(makefile, target, sourcekind, sourcebatch, sourceflags, outputdir, precmds_label)
    local handled_objects = target:data("makefile.handled_objects")
    if not handled_objects then
        handled_objects = {}
        target:data_set("makefile.handled_objects", handled_objects)
    end
    for index, objectfile in ipairs(sourcebatch.objectfiles) do
        -- remove repeat
        -- this is because some rules will repeatedly bind the same sourcekind, e.g. `rule("c++.build.modules.builder")`
        if not handled_objects[objectfile] then
            _add_build_object(makefile, target,
                sourcebatch.sourcefiles[index], objectfile, sourceflags, outputdir, precmds_label)
            handled_objects[objectfile] = true
        end
    end
end

-- add build phony
function _add_build_phony(makefile, target)

    -- make dependence for the dependent targets
    makefile:printf("%s:", target:name())
    for _, dep in ipairs(target:get("deps")) do
        makefile:write(" " .. dep)
    end
    makefile:print("")
end

-- add custom commands before building target
function _add_build_custom_commands_before(makefile, target, sourcegroups, outputdir)

    -- add before commands
    -- we use irpairs(groups), because the last group that should be given the highest priority.
    local cmds_before = {}
    target_cmds.get_target_buildcmd(target, cmds_before, {suffix = "before"})
    target_cmds.get_target_buildcmd_sourcegroups(target, cmds_before, sourcegroups, {suffix = "before"})
    target_cmds.get_target_buildcmd_sourcegroups(target, cmds_before, sourcegroups)

    local targetname = target:name()
    local label = "precmds_" .. targetname
    if #cmds_before > 0 then
        makefile:print("%s:", label)
        for _, cmd in ipairs(cmds_before) do
            local command = _get_command_string(cmd, outputdir)
            if command then
                makefile:print("\t%s", command)
            end
        end
        makefile:print("")
        return label
    end
end

-- add custom commands after building target
function _add_build_custom_commands_after(makefile, target, sourcegroups, outputdir)
    local cmds_after = {}
    target_cmds.get_target_buildcmd_sourcegroups(target, cmds_after, sourcegroups, {suffix = "after"})
    target_cmds.get_target_buildcmd(target, cmds_after, {suffix = "after"})
    if #cmds_after > 0 then
        for _, cmd in ipairs(cmds_after) do
            local command = _get_command_string(cmd, outputdir)
            if command then
                makefile:print("\t%s", command)
            end
        end
    end
end

-- add build target
function _add_build_target(makefile, target, targetflags, outputdir)

    -- https://github.com/xmake-io/xmake/issues/2337
    target:data_set("plugin.project.kind", "makefile")

    -- build sourcebatch groups first
    local sourcegroups = rule_groups.build_sourcebatch_groups(target, target:sourcebatches())

    -- add custom commands before building target
    local precmds_label = _add_build_custom_commands_before(makefile, target, sourcegroups, outputdir)

    -- is phony target?
    if target:is_phony() then
        return _add_build_phony(makefile, target)
    end

    -- make head
    local targetfile = _get_relative_unix_path(target:targetfile(), outputdir)
    local targetname = target:name()

    -- rules like `./target` and `target` are equivalent and can causes issues
    -- for cases where targetdir is .
    -- in these cases, the targetfile rule is not created
    if target:targetfile() == "./" .. targetname then
        makefile:printf("%s:", targetname)
        if precmds_label then
            makefile:printf(" %s", precmds_label)
        end
    else
        makefile:print("%s: %s", targetname, targetfile)
        makefile:printf("%s:", targetfile)
    end
    if precmds_label then
        makefile:printf(" %s", precmds_label)
    end

    -- make dependence for the dependent targets
    for _, depname in ipairs(target:get("deps")) do
        local dep = project.target(depname, {namespace = target:namespace()})
        makefile:write(" " .. (dep:is_phony() and depname or _get_relative_unix_path(dep:targetfile(), outputdir)))
    end

    -- make dependence for objects
    local objectfiles = target:objectfiles()
    local objectfiles_translated = {}
    for _, objectfile in ipairs(objectfiles) do
        objectfile = _get_relative_unix_path(objectfile, outputdir)
        table.insert(objectfiles_translated, objectfile)
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
    local command = target:linker():linkcmd(objectfiles_translated, targetfile, {target = target})

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
    makefile:print("\t%s", _get_cmd_echo(string.format("linking.$(mode) %s", path.filename(targetfile))))
    makefile:print("\t%s", _get_cmd_mkdir(path.directory(targetfile)))
    makefile:writef("\t$(VV)%s\n", command)

    -- add custom commands after building target
    _add_build_custom_commands_after(makefile, target, sourcegroups, outputdir)

    -- end
    makefile:print("")

    -- build source batches
    for _, sourcebatch in pairs(target:sourcebatches()) do
        local sourcekind = sourcebatch.sourcekind
        if sourcekind then
            -- compile source files to single object at once
            local sourceflags = targetflags[target:name() .. '_' .. sourcekind:upper()]
            _add_build_objects(makefile, target, sourcekind, sourcebatch, sourceflags, outputdir, precmds_label)
        end
    end
end

-- add build targets
function _add_build_targets(makefile, targetflags, outputdir)
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
    for _, target in pairs(project.targets()) do
        _add_build_target(makefile, target, targetflags, outputdir)
    end
end

-- add build
function _add_build(makefile, targetflags, outputdir)

    -- TODO
    -- disable precompiled header first
    for _, target in pairs(project.targets()) do
        target:set("pcheader", nil)
        target:set("pcxxheader", nil)
    end

    -- add build targets
    _add_build_targets(makefile, targetflags, outputdir)
end

-- add clean target
function _add_clean_target(makefile, target, outputdir)
    makefile:printf("clean_%s: ", target:name())
    for _, dep in ipairs(target:get("deps")) do
        makefile:write(" clean_" .. dep)
    end
    makefile:print("")
    if not target:is_phony() then
        _add_remove_files(makefile, target:targetfile(), outputdir)
        _add_remove_files(makefile, target:symbolfile(), outputdir)
        _add_remove_files(makefile, target:objectfiles(), outputdir)
    end
    makefile:print("")
end

-- add clean targets
function _add_clean_targets(makefile, outputdir)
    local all = ""
    for targetname, _ in pairs(project.targets()) do
        all = all .. " clean_" .. targetname
    end
    makefile:print("clean: %s\n", all)

    -- add clean targets
    for _, target in pairs(project.targets()) do
        _add_clean_target(makefile, target, outputdir)
    end
end

-- add clean
function _add_clean(makefile, outputdir)
    _add_clean_targets(makefile, outputdir)
end

function make(outputdir)

    -- enter project directory
    local oldir = os.cd(os.projectdir())

    -- open the makefile
    local makefile = io.open(path.join(outputdir, "makefile"), "w")

    -- add header
    _add_header(makefile)

    -- add switches
    _add_switches(makefile)

    -- add toolchains
    _add_toolchains(makefile, outputdir)

    -- add flags
    local targetflags = {}
    _add_flags(makefile, targetflags, outputdir)

    -- add build
    _add_build(makefile, targetflags, outputdir)

    -- add clean
    _add_clean(makefile, outputdir)

    -- close the makefile
    makefile:close()

    -- leave project directory
    os.cd(oldir)
end
