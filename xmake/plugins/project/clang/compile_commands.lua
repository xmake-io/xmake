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
import("core.base.hashset")
import("core.tool.compiler")
import("core.project.rule")
import("core.project.project")
import("core.language.language")
import("private.utils.batchcmds")
import("private.utils.executable_path")
import("plugins.project.utils.target_cmds", {rootdir = os.programdir()})
import("actions.test.main", {rootdir = os.programdir(), alias = "test_action"})

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

-- Is there other supported source file, which come from custom rules?
function _is_other_sourcefile(sourcefile)
    local extensions = _g._other_supported_exts
    if extensions == nil then
        extensions = hashset.from({".v", ".sv"})
        _g._other_supported_exts = extensions
    end
    return extensions:has(path.extension(sourcefile))
end

-- get LSP, clangd, ccls, ...
function _get_lsp()
    local lsp = option.get("lsp")
    if lsp == nil then
        lsp = os.getenv("XMAKE_GENERATOR_COMPDB_LSP")
    end
    return lsp
end

-- specify windows sdk verison
function _get_windows_sdk_arguments(target)
    local args = {}
    local msvc = target:toolchain("msvc")
    if msvc then
        local envs = msvc:runenvs()
        if envs then
            for _, dir in ipairs(path.splitenv(envs.INCLUDE)) do
                table.insert(args, "-imsvc")
                table.insert(args, dir)
            end
        end
    end
    return args
end

-- translate external/system include flags, because some tools (vscode) do not support them yet.
-- https://github.com/xmake-io/xmake/issues/1050
function _translate_arguments(arguments)
    local args = {}
    local cc = path.basename(arguments[1]):lower()
    local is_include = false
    local lsp = _get_lsp()
    for idx, arg in ipairs(arguments) do
        -- convert path to string, maybe we need to convert path, but not supported now.
        arg = tostring(arg)

        -- see https://github.com/xmake-io/xmake/issues/1721
        if idx == 1 and is_host("windows") and path.extension(arg) == "" then
            arg = arg .. ".exe"
        end
        if arg:startswith("-isystem-after", 1, true) then
            arg = "-I" .. arg:sub(15)
        elseif arg:startswith("-isystem", 1, true) then
            -- clangd support `-isystem`, we don't need to translate it
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
            elseif arg:startswith("-ccbin=") then
                -- @see https://github.com/xmake-io/xmake/issues/4716
                local f = arg:sub(1, 7)
                local v = arg:sub(8)
                if v then
                    arg = f .. v:gsub("\\\\", "\\")
                end
            end
        end
        if arg == "-I" then
            is_include = true
        end
        if arg then
            -- improve to support for "/usr/bin/xcrun -sdk macosx clang"
            -- @see
            -- https://github.com/xmake-io/xmake/issues/3159
            -- https://github.com/xmake-io/xmake/issues/3286
            if idx == 1 then
                arg = executable_path(arg)
            end
            table.insert(args, arg)
        end
    end
    return args
end

-- make command
function _make_arguments(jsonfile, arguments, opt)

    -- attempt to get source file from arguments
    opt = opt or {}
    local sourcefile = opt.sourcefile
    if not sourcefile then
        for _, arg in ipairs(arguments) do
            local sourcekind = try {function () return language.sourcekind_of(path.filename(arg)) end}
            if sourcekind and os.isfile(arg) then
                sourcefile = tostring(arg)
            elseif _is_other_sourcefile(arg) and os.isfile(arg) then
                sourcefile = tostring(arg)
            end
            if sourcefile then
                break
            end
        end
        if not sourcefile then
            return
        end
    end

    -- translate some unsupported arguments
    arguments = _translate_arguments(arguments)

    -- https://github.com/xmake-io/xmake/issues/6058
    local lsp = _get_lsp()
    local target = opt.target
    local cc = path.basename(arguments[1]):lower()
    if lsp and lsp == "clangd" and target and target:is_plat("windows") and cc ~= "nvcc" then
        table.join2(arguments, _get_windows_sdk_arguments(target))
    end

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

-- add target custom commands
function _add_target_custom_commands(jsonfile, target, suffix, cmds)
    for _, cmd in ipairs(cmds) do
        if cmd.program then
            _make_arguments(jsonfile, table.join(cmd.program, cmd.argv), {target = target})
        end
    end
end

-- add target source commands
function _add_target_source_commands(jsonfile, target)
    for _, sourcebatch in pairs(target:sourcebatches()) do
        local sourcekind = sourcebatch.sourcekind
        if sourcekind and _sourcebatch_is_built(sourcebatch) then
            for index, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local objectfile = sourcebatch.objectfiles[index]
                local arguments = table.join(compiler.compargv(sourcefile, objectfile, {target = target, sourcekind = sourcekind, rawargs=true}))
                _make_arguments(jsonfile, arguments, {sourcefile = sourcefile, target = target})
            end
        end
    end
end

-- add target commands
function _add_target_commands(jsonfile, target)

    -- add before commands
    -- we use irpairs(groups), because the last group that should be given the highest priority.
    local cmds_before = target_cmds.get_target_buildcmds(target, {stages = {"before", "on"}})
    _add_target_custom_commands(jsonfile, target, "before", cmds_before)

    -- add target source commands
    _add_target_source_commands(jsonfile, target)

    -- add after commands
    local cmds_after = target_cmds.get_target_buildcmds(target, {stages = {"after"}})
    _add_target_custom_commands(jsonfile, target, "after", cmds_after)
end

-- add target
function _add_target(jsonfile, target)

    -- https://github.com/xmake-io/xmake/issues/2337
    target:data_set("plugin.project.kind", "compile_commands")

    -- enter package environments
    local oldenvs = os.addenvs(target:pkgenvs())

    -- we enable it for clangd, @see https://github.com/xmake-io/xmake/issues/2818
    local lsp = _get_lsp()
    if not lsp or lsp ~= "clangd" then
        target:set("pcheader", nil)
        target:set("pcxxheader", nil)
    end

    -- add target commands
    _add_target_commands(jsonfile, target)

    -- restore package environments
    os.setenvs(oldenvs)
end

-- add targets
function _add_targets(jsonfile)
    jsonfile:print("[")
    _g.firstline = true

    for _, target in pairs(project.targets()) do
        if not target:is_phony() then
            _add_target(jsonfile, target)
        end
    end
    -- https://github.com/xmake-io/xmake/issues/4750
    for _, test in pairs(test_action.get_tests()) do
        local target = test.target
        if not target:is_phony() then
            _add_target(jsonfile, target)
        end
    end
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
    local oldir = os.cd(os.projectdir())
    local jsonfile = io.open(path.join(outputdir, "compile_commands.json"), "w")
    os.setenv("XMAKE_IN_COMPILE_COMMANDS_PROJECT_GENERATOR", "true")
    target_cmds.prepare_targets()
    _add_targets(jsonfile)
    jsonfile:close()
    os.setenv("XMAKE_IN_COMPILE_COMMANDS_PROJECT_GENERATOR", nil)
    os.cd(oldir)
end
