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
-- @file        batchcmds.lua
--

-- imports
import("core.base.option")
import("core.base.object")
import("core.base.tty")
import("core.base.colors")
import("core.project.depend")
import("core.theme.theme")
import("core.tool.linker")
import("core.tool.compiler")
import("core.language.language")
import("utils.progress", {alias = "progress_utils"})
import("utils.binary.rpath", {alias = "rpath_utils"})

-- define module
local batchcmds = batchcmds or object { _init = {"_TARGET", "_CMDS", "_DEPINFO", "_tip"}}

-- show text
function _show(showtext, progress)
    if option.get("verbose") then
        cprint(showtext)
    else
        local is_scroll = _g.is_scroll
        if is_scroll == nil then
            is_scroll = theme.get("text.build.progress_style") == "scroll"
            _g.is_scroll = is_scroll
        end
        if is_scroll then
            cprint(showtext)
        else
            tty.erase_line_to_start().cr()
            local msg = showtext
            local msg_plain = colors.translate(msg, {plain = true})
            local maxwidth = os.getwinsize().width
            if #msg_plain <= maxwidth then
                cprintf(msg)
            else
                -- windows width is too small? strip the partial message in middle
                local partlen = math.floor(maxwidth / 2) - 3
                local sep = msg_plain:sub(partlen + 1, #msg_plain - partlen - 1)
                local split = msg:split(sep, {plain = true, strict = true})
                cprintf(table.concat(split, "..."))
            end
            if math.floor(progress:percent()) == 100 then
                print("")
                _g.showing_without_scroll = false
            else
                _g.showing_without_scroll = true
            end
            io.flush()
        end
    end
end

-- run command: show
function _runcmd_show(cmd, opt)
    local showtext = cmd.showtext
    if showtext then
        _show(showtext, cmd.progress)
    end
end

-- run command: os.runv
function _runcmd_runv(cmd, opt)
    if cmd.program then
        if not opt.dryrun then
            os.runv(cmd.program, cmd.argv, cmd.opt)
        end
    end
end

-- run command: os.vrunv
function _runcmd_vrunv(cmd, opt)
    if cmd.program then
        if opt.dryrun then
            vprint(os.args(table.join(cmd.program, cmd.argv)))
        else
            os.vrunv(cmd.program, cmd.argv, cmd.opt)
        end
    end
end

-- run command: os.execv
function _runcmd_execv(cmd, opt)
    if cmd.program then
        if opt.dryrun then
            print(os.args(table.join(cmd.program, cmd.argv)))
        else
            os.execv(cmd.program, cmd.argv, cmd.opt)
        end
    end
end

-- run command: os.vexecv
function _runcmd_vexecv(cmd, opt)
    if cmd.program then
        if opt.dryrun then
            print(os.args(table.join(cmd.program, cmd.argv)))
        else
            os.vexecv(cmd.program, cmd.argv, cmd.opt)
        end
    end
end

-- run command: os.mkdir
function _runcmd_mkdir(cmd, opt)
    local dir = cmd.dir
    if not opt.dryrun and not os.isdir(dir) then
        os.mkdir(dir)
    end
end

-- run command: os.cd
function _runcmd_cd(cmd, opt)
    local dir = cmd.dir
    if not opt.dryrun then
        os.cd(dir)
    end
end

-- run command: os.rm
function _runcmd_rm(cmd, opt)
    local filepath = cmd.filepath
    if not opt.dryrun then
        os.tryrm(filepath, opt)
    end
end

-- run command: os.rmdir
function _runcmd_rmdir(cmd, opt)
    local dir = cmd.dir
    if not opt.dryrun and os.isdir(dir) then
        os.tryrm(dir, opt)
    end
end

-- run command: os.cp
function _runcmd_cp(cmd, opt)
    if not opt.dryrun then
        os.cp(cmd.srcpath, cmd.dstpath, cmd.opt)
    end
end

-- run command: os.mv
function _runcmd_mv(cmd, opt)
    if not opt.dryrun then
        os.mv(cmd.srcpath, cmd.dstpath, cmd.opt)
    end
end

-- run command: os.ln
function _runcmd_ln(cmd, opt)
    if not opt.dryrun then
        os.ln(cmd.srcpath, cmd.dstpath, cmd.opt)
    end
end

-- run command: clean rpath
function _runcmd_clean_rpath(cmd, opt)
    if not opt.dryrun then
        rpath_utils.clean(cmd.filepath, cmd.opt)
    end
end

-- run command: insert rpath
function _runcmd_insert_rpath(cmd, opt)
    if not opt.dryrun then
        rpath_utils.insert(cmd.filepath, cmd.rpath, cmd.opt)
    end
end

-- run command: remove rpath
function _runcmd_remove_rpath(cmd, opt)
    if not opt.dryrun then
        rpath_utils.remove(cmd.filepath, cmd.rpath, cmd.opt)
    end
end

-- run command: change rpath
function _runcmd_change_rpath(cmd, opt)
    if not opt.dryrun then
        rpath_utils.change(cmd.filepath, cmd.rpath_old, cmd.rpath_new, cmd.opt)
    end
end

-- run command
function _runcmd(cmd, opt)
    local kind = cmd.kind
    local maps = _g.maps
    if not maps then
        maps =
        {
            show         = _runcmd_show,
            runv         = _runcmd_runv,
            vrunv        = _runcmd_vrunv,
            execv        = _runcmd_execv,
            vexecv       = _runcmd_vexecv,
            mkdir        = _runcmd_mkdir,
            rmdir        = _runcmd_rmdir,
            cd           = _runcmd_cd,
            rm           = _runcmd_rm,
            cp           = _runcmd_cp,
            mv           = _runcmd_mv,
            ln           = _runcmd_ln,
            clean_rpath  = _runcmd_clean_rpath,
            insert_rpath = _runcmd_insert_rpath,
            remove_rpath = _runcmd_remove_rpath,
            change_rpath = _runcmd_change_rpath
        }
        _g.maps = maps
    end
    local script = maps[kind]
    if script then
        script(cmd, opt)
    end
end

-- run commands
function _runcmds(cmds, opt)
    for _, cmd in ipairs(cmds) do
        _runcmd(cmd, opt)
    end
end

-- is empty? no commands
function batchcmds:empty()
    return #self:cmds() == 0
end

-- get commands
function batchcmds:cmds()
    return self._CMDS
end

-- add command: os.runv
function batchcmds:runv(program, argv, opt)
    table.insert(self:cmds(), {kind = "runv", program = program, argv = argv, opt = opt})
end

-- add command: os.vrunv
function batchcmds:vrunv(program, argv, opt)
    table.insert(self:cmds(), {kind = "vrunv", program = program, argv = argv, opt = opt})
end

-- add command: os.execv
function batchcmds:execv(program, argv, opt)
    table.insert(self:cmds(), {kind = "execv", program = program, argv = argv, opt = opt})
end

-- add command: os.vexecv
function batchcmds:vexecv(program, argv, opt)
    table.insert(self:cmds(), {kind = "vexecv", program = program, argv = argv, opt = opt})
end

-- add command: compiler.compile
function batchcmds:compile(sourcefiles, objectfile, opt)

    -- bind target if exists
    opt = opt or {}
    opt.target = self._TARGET

    -- wrap path for sourcefiles, because we need to translate path for project generator
    if type(sourcefiles) == "table" then
        local sourcefiles_wrap = {}
        for _, sourcefile in ipairs(sourcefiles) do
            table.insert(sourcefiles_wrap, path(sourcefile))
        end
        sourcefiles = sourcefiles_wrap
    else
        sourcefiles = path(sourcefiles)
    end

    -- load compiler and get compilation command
    local sourcekind = opt.sourcekind
    if not sourcekind and (type(sourcefiles) == "string" or path.instance_of(sourcefiles)) then
        sourcekind = language.sourcekind_of(tostring(sourcefiles))
    end
    local compiler_inst = compiler.load(sourcekind, opt)
    local _, argv = compiler_inst:compargv(sourcefiles, path(objectfile), opt)

    -- add compilation command and bind run environments of compiler
    self:mkdir(path.directory(objectfile))
    self:compilev(argv, table.join({sourcekind = sourcekind, compiler = compiler_inst}, opt))
end

-- add command: compiler.compilev
function batchcmds:compilev(argv, opt)

    -- bind target if exists
    opt = opt or {}
    opt.target = self._TARGET

    -- load compiler and get compilation command
    local compiler_inst = opt.compiler
    if not compiler_inst then
        local sourcekind = opt.sourcekind
        compiler_inst = compiler.load(sourcekind, opt)
    end

    -- we need to translate path for the project generator
    local patterns = {"^([%-/]external:I)(.*)",
                      "^([%-/]I)(.*)",
                      "^([%-/]Fp)(.*)",
                      "^([%-/]Fd)(.*)",
                      "^([%-/]Yu)(.*)",
                      "^([%-/]FI)(.*)"}
    for idx, item in ipairs(argv) do
        if type(item) == "string" then
            for _, pattern in ipairs(patterns) do
                local _, count = item:gsub(pattern, function (prefix, value)
                    argv[idx] = path(value, function (p) return prefix .. p end)
                end)
                if count > 0 then
                    break
                end
            end
        end
    end

    -- add compilation command and bind run environments of compiler
    self:vrunv(compiler_inst:program(), argv, {envs = table.join(compiler_inst:runenvs(), opt.envs)})
end

-- add command: linker.link
function batchcmds:link(objectfiles, targetfile, opt)

    -- bind target if exists
    local target = self._TARGET
    opt = opt or {}
    opt.target = target

    -- wrap path for objectfiles, because we need to translate path for project generator
    local objectfiles_wrap = {}
    for _, objectfile in ipairs(objectfiles) do
        table.insert(objectfiles_wrap, path(objectfile))
    end
    objectfiles = objectfiles_wrap

    -- load linker and get link command
    local linker_inst = target and target:linker() or linker.load(opt.targetkind, opt.sourcekinds, opt)
    local program, argv = linker_inst:linkargv(objectfiles, path(targetfile), opt)

    -- we need to translate path for the project generator
    local patterns = {"^([%-/]L)(.*)",
                      "^([%-/]F)(.*)",
                      "^([%-/]libpath:)(.*)"}
    for idx, item in ipairs(argv) do
        if type(item) == "string" then
            for _, pattern in ipairs(patterns) do
                local _, count = item:gsub(pattern, function (prefix, value)
                    argv[idx] = path(value, function (p) return prefix .. p end)
                end)
                if count > 0 then
                    break
                end
            end
        end
    end

    -- add link command and bind run environments of linker
    self:mkdir(path.directory(targetfile))
    self:vrunv(program, argv, {envs = table.join(linker_inst:runenvs(), opt.envs)})
end

-- add command: os.mkdir
function batchcmds:mkdir(dir)
    table.insert(self:cmds(), {kind = "mkdir", dir = dir})
end

-- add command: os.rmdir
function batchcmds:rmdir(dir, opt)
    table.insert(self:cmds(), {kind = "rmdir", dir = dir, opt = opt})
end

-- add command: os.rm
function batchcmds:rm(filepath, opt)
    table.insert(self:cmds(), {kind = "rm", filepath = filepath, opt = opt})
end

-- add command: os.cp
function batchcmds:cp(srcpath, dstpath, opt)
    table.insert(self:cmds(), {kind = "cp", srcpath = srcpath, dstpath = dstpath, opt = opt})
end

-- add command: os.mv
function batchcmds:mv(srcpath, dstpath, opt)
    table.insert(self:cmds(), {kind = "mv", srcpath = srcpath, dstpath = dstpath, opt = opt})
end

-- add command: os.ln
function batchcmds:ln(srcpath, dstpath, opt)
    table.insert(self:cmds(), {kind = "ln", srcpath = srcpath, dstpath = dstpath, opt = opt})
end

-- add command: os.cd
function batchcmds:cd(dir, opt)
    table.insert(self:cmds(), {kind = "cd", dir = dir, opt = opt})
end

-- add command: show
function batchcmds:show(format, ...)
    local showtext = string.format(format, ...)
    table.insert(self:cmds(), {kind = "show", showtext = showtext})
end

-- add command: clean rpath
function batchcmds:clean_rpath(filepath, opt)
    table.insert(self:cmds(), {kind = "clean_rpath", filepath = filepath, opt = opt})
end

-- add command: insert rpath
function batchcmds:insert_rpath(filepath, rpath, opt)
    table.insert(self:cmds(), {kind = "insert_rpath", filepath = filepath, rpath = rpath, opt = opt})
end

-- add command: remove rpath
function batchcmds:remove_rpath(filepath, rpath, opt)
    table.insert(self:cmds(), {kind = "remove_rpath", filepath = filepath, rpath = rpath, opt = opt})
end

-- add command: change rpath
function batchcmds:change_rpath(filepath, rpath_old, rpath_new, opt)
    table.insert(self:cmds(), {kind = "change_rpath", filepath = filepath, rpath_old = rpath_old, rpath_new = rpath_new, opt = opt})
end

-- add raw command for the specific generator or xpack format
function batchcmds:rawcmd(kind, rawstr)
    table.insert(self:cmds(), {kind = kind, rawstr = rawstr})
end

-- add command: show progress
function batchcmds:show_progress(progress, format, ...)
    if progress then
        local showtext = progress_utils.text(progress, format, ...)
        table.insert(self:cmds(), {kind = "show", showtext = showtext, progress = progress})
    end
end

-- get depinfo
function batchcmds:depinfo()
    return self._DEPINFO
end

-- add dependent files
function batchcmds:add_depfiles(...)
    local depinfo = self._DEPINFO or {}
    depinfo.files = depinfo.files or {}
    table.join2(depinfo.files, ...)
    self._DEPINFO = depinfo
end

-- add dependent values
function batchcmds:add_depvalues(...)
    local depinfo = self._DEPINFO or {}
    depinfo.values = depinfo.values or {}
    table.join2(depinfo.values, ...)
    self._DEPINFO = depinfo
end

-- set the last mtime of dependent files and values
function batchcmds:set_depmtime(lastmtime)
    local depinfo = self._DEPINFO or {}
    depinfo.lastmtime = lastmtime
    self._DEPINFO = depinfo
end

-- set cache file of depend info
function batchcmds:set_depcache(cachefile)
    local depinfo = self._DEPINFO or {}
    depinfo.dependfile = cachefile
    self._DEPINFO = depinfo
end

-- run cmds
function batchcmds:runcmds(opt)
    opt = opt or {}
    if self:empty() then
        return
    end
    local depinfo = self:depinfo()
    if depinfo and depinfo.files then
        depend.on_changed(function ()
            _runcmds(self:cmds(), opt)
        end, table.join(depinfo, {dryrun = opt.dryrun, changed = opt.changed}))
    else
        _runcmds(self:cmds(), opt)
    end
end

-- new a batch commands for rule/xx_xxcmd_xxx()
--
-- @params opt      options, e.g. {target = ..}
--
function new(opt)
    opt = opt or {}
    return batchcmds {_TARGET = opt.target, _CMDS = {}}
end

