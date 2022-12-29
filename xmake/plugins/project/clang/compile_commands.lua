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
-- @file        compile_commands.lua
--

-- imports
import("core.base.option")
import("core.tool.compiler")
import("core.project.rule")
import("core.project.project")
import("core.language.language")
import("private.utils.batchcmds")

-- escape path
function _escape_path(p)
    return os.args(p, {escape = true, nowrap = true})
end

-- this sourcebatch is built?
function _sourcebatch_is_built(sourcebatch)
    -- we can only use rulename to filter them because sourcekind may be bound to multiple rules
    local rulename = sourcebatch.rulename
    if rulename == "c.build" or rulename == "c++.build"
        or rulename == "asm.build" or rulename == "cuda.build"
        or rulename == "objc.build" or rulename == "objc++.build" then
        return true
    end
end

-- translate external/system include flags, because some tools (vscode) do not support them yet.
-- https://github.com/xmake-io/xmake/issues/1050
function _translate_arguments(arguments)
    local args = {}
    local cc = path.basename(arguments[1]):lower()
    local is_include = false
    local lsp = option.get("lsp")
    for idx, arg in ipairs(arguments) do
        -- convert path to string, maybe we need convert path, but not supported now.
        arg = tostring(arg)

        -- see https://github.com/xmake-io/xmake/issues/1721
        if idx == 1 and is_host("windows") and path.extension(arg) == "" then
            arg = arg .. ".exe"
        end
        if arg:startswith("-isystem-after", 1, true) then
            arg = "-I" .. arg:sub(15)
        elseif arg:startswith("-isystem", 1, true) then
            -- clangd support `-isystem`, we need not translate it
            -- @see https://github.com/xmake-io/xmake/issues/3020
            if not lsp or lsp ~= "clangd" then
                arg = "-I" .. arg:sub(9)
            end
        elseif arg:find("[%-/]external:I") then
            arg = arg:gsub("[%-/]external:I", "-I")
        elseif arg:find("[%-/]external:W") or arg:find("[%-/]experimental:external") then
            arg = nil
        end
        -- @see use msvc-style flags for msvc to support language-server better
        -- https://github.com/xmake-io/xmake/issues/1284
        if cc == "cl" and arg and arg:startswith("-") then
            arg = arg:gsub("^%-", "/")
        elseif cc == "nvcc" and arg then
            -- support -I path with spaces for nvcc
            -- https://github.com/xmake-io/xmake/issues/1726
            if is_include then
                if arg and arg:find(' ', 1, true) then
                    arg = "\"" .. arg .. "\""
                end
                is_include = false
            elseif arg:startswith("-I") then
                local f = arg:sub(1, 2)
                local v = arg:sub(3)
                if v and v:find(' ', 1, true) then
                    arg = f .. "\"" .. v .. "\""
                end
            end
        end
        if arg == "-I" then
            is_include = true
        end
        if arg then
            -- split "/usr/bin/xcrun -sdk macosx clang"
            -- @see https://github.com/xmake-io/xmake/issues/3159
            if idx == 1 and not os.isfile(arg) and arg:find(" ", 1, true) then
                table.join2(args, os.argv(arg))
            else
                table.insert(args, arg)
            end
        end
    end
    return args
end

-- make command
function _make_arguments(jsonfile, arguments, sourcefile)

    -- attempt to get source file from arguments
    if not sourcefile then
        for _, arg in ipairs(arguments) do
            local sourcekind = try {function () return language.sourcekind_of(path.filename(arg)) end}
            if sourcekind and os.isfile(arg) then
                sourcefile = tostring(arg)
                break
            end
        end
        if not sourcefile then
            return
        end
    end

    -- translate some unsupported arguments
    arguments = _translate_arguments(arguments)

    -- escape '"', '\'
    local arguments_escape = {}
    for _, arg in ipairs(arguments) do
        table.insert(arguments_escape, _escape_path(arg))
    end

    -- remove repeat
    -- this is because some rules will repeatedly bind the same sourcekind, e.g. `rule("c++.build.modules.builder")`
    local key = hash.uuid(os.args(arguments_escape) .. sourcefile)
    local map = _g.map or {}
    _g.map = map
    if map[key] then
        return
    end

    -- make body
    jsonfile:printf(
[[%s{
  "directory": "%s",
  "arguments": ["%s"],
  "file": "%s"
}]], (_g.firstline and "" or ",\n"), _escape_path(os.projectdir()), table.concat(arguments_escape, "\", \""), _escape_path(sourcefile))

    -- clear first line marks
    _g.firstline = false
    map[key] = true
end

-- make commands for target
function _make_commands_for_targetrules(jsonfile, target, suffix)
    for _, ruleinst in ipairs(target:orderules()) do
        local scriptname = "buildcmd" .. (suffix and ("_" .. suffix) or "")
        local script = ruleinst:script(scriptname)
        if script then
            local batchcmds_ = batchcmds.new({target = target})
            script(target, batchcmds_, {})
            if not batchcmds_:empty() then
                for _, cmd in ipairs(batchcmds_:cmds()) do
                    if cmd.program then
                        _make_arguments(jsonfile, table.join(cmd.program, cmd.argv))
                    end
                end
            end
        end
    end
end

-- make commands for object rules
function _make_commands_for_objectrules(jsonfile, target, sourcebatch, suffix)

    -- we ignore all built sourcebatches
    if _sourcebatch_is_built(sourcebatch) then
        return
    end

    -- get rule
    local rulename = assert(sourcebatch.rulename, "unknown rule for sourcebatch!")
    local ruleinst = assert(target:rule(rulename) or project.rule(rulename) or rule.rule(rulename), "unknown rule: %s", rulename)

    -- generate commands for xx_buildcmd_files
    local scriptname = "buildcmd_files" .. (suffix and ("_" .. suffix) or "")
    local script = ruleinst:script(scriptname)
    if script then
        local batchcmds_ = batchcmds.new({target = target})
        script(target, batchcmds_, sourcebatch, {})
        if not batchcmds_:empty() then
            for _, cmd in ipairs(batchcmds_:cmds()) do
                if cmd.program then
                    _make_arguments(jsonfile, table.join(cmd.program, cmd.argv))
                end
            end
        end
    end

    -- generate commands for xx_buildcmd_file
    if not script then
        scriptname = "buildcmd_file" .. (suffix and ("_" .. suffix) or "")
        script = ruleinst:script(scriptname)
        if script then
            local sourcekind = sourcebatch.sourcekind
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local batchcmds_ = batchcmds.new({target = target})
                script(target, batchcmds_, sourcefile, {})
                if not batchcmds_:empty() then
                    for _, cmd in ipairs(batchcmds_:cmds()) do
                        if cmd.program then
                            _make_arguments(jsonfile, table.join(cmd.program, cmd.argv))
                        end
                    end
                end
            end
        end
    end
end



-- make commands for objects
function _make_commands_for_objects(jsonfile, target, sourcebatch)
    local sourcekind = sourcebatch.sourcekind
    if sourcekind and _sourcebatch_is_built(sourcebatch) then
        for index, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local objectfile = sourcebatch.objectfiles[index]
            local arguments = table.join(compiler.compargv(sourcefile, objectfile, {target = target, sourcekind = sourcekind}))
            _make_arguments(jsonfile, arguments, sourcefile)
        end
        return true
    end
end

-- make objects
function _make_objects(jsonfile, target, sourcebatch)
    _make_commands_for_targetrules(jsonfile, target, "before")
    _make_commands_for_objectrules(jsonfile, target, sourcebatch, "before")
    if not _make_commands_for_objects(jsonfile, target, sourcebatch) then
        _make_commands_for_objectrules(jsonfile, target, sourcebatch)
    end
    _make_commands_for_objectrules(jsonfile, target, sourcebatch, "after")
    _make_commands_for_targetrules(jsonfile, target, "after")
end

-- make target
function _make_target(jsonfile, target)

    -- https://github.com/xmake-io/xmake/issues/2337
    target:data_set("plugin.project.kind", "compile_commands")

    -- enter package environments
    local oldenvs = os.addenvs(target:pkgenvs())

    -- we enable it for clangd, @see https://github.com/xmake-io/xmake/issues/2818
    if not lsp or lsp ~= "clangd" then
        target:set("pcheader", nil)
        target:set("pcxxheader", nil)
    end

    -- build source batches
    for _, sourcebatch in pairs(target:sourcebatches()) do
        _make_objects(jsonfile, target, sourcebatch)
    end

    -- restore package environments
    os.setenvs(oldenvs)
end

-- make all
function _make_all(jsonfile)

    -- make header
    jsonfile:print("[")

    -- make commands
    _g.firstline = true
    for _, target in pairs(project.targets()) do
        if not target:is_phony() then
            _make_target(jsonfile, target)
        end
    end

    -- make tailer
    jsonfile:print("]")
end

-- generate compilation databases for clang-based tools(compile_commands.json)
--
-- references:
--  - https://clang.llvm.org/docs/JSONCompilationDatabase.html
--  - https://sarcasm.github.io/notes/dev/compilation-database.html
--  - http://eli.thegreenplace.net/2014/05/21/compilation-databases-for-clang-based-tools
--
function make(outputdir)

    -- enter project directory
    local oldir = os.cd(os.projectdir())

    -- open the jsonfile
    local jsonfile = io.open(path.join(outputdir, "compile_commands.json"), "w")

    -- make all
    _make_all(jsonfile)

    -- close the jsonfile
    jsonfile:close()

    -- leave project directory
    os.cd(oldir)
end
