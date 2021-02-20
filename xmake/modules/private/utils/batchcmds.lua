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
import("core.tool.compiler")
import("private.utils.progress", {alias = "progress_utils"})

-- define module
local batchcmds = batchcmds or object { _init = {"_TARGET", "_CMDS", "_DEPS", "_tip"}}

-- show the tip message
local function _showtip(tip, progress)
    if option.get("verbose") then
        cprint(tip)
    else
        local is_scroll = _g.is_scroll
        if is_scroll == nil then
            is_scroll = theme.get("text.build.progress_style") == "scroll"
            _g.is_scroll = is_scroll
        end
        if is_scroll then
            cprint(tip)
        else
            tty.erase_line_to_start().cr()
            local msg = tip
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
            if math.floor(progress) == 100 then
                print("")
                _g.showing_without_scroll = false
            else
                _g.showing_without_scroll = true
            end
            io.flush()
        end
    end
end

-- run the given commands
local function _runcmds(cmds, opt)
    for _, cmd in ipairs(cmds) do
        local tip = cmd.tip
        if tip then
            _showtip(tip, cmd.progress)
        end
        if cmd.program then
            if opt.dryrun then
                vprint(os.args(table.join(cmd.program, cmd.argv)))
            else
                os.vrunv(cmd.program, cmd.argv, cmd.runopt)
            end
        end
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

-- add command
function batchcmds:add_cmd(program, argv, opt)
    table.insert(self:cmds(), {program = program, argv = argv, runopt = opt})
    self:add_depvalues(program, argv)
end

-- add compilation command
function batchcmds:add_compcmd(sourcefiles, objectfile, opt)
    opt = opt or {}
    opt.target = self._TARGET -- bind target if exists
    local program, argv = compiler.compargv(sourcefiles, objectfile, opt)
    self:add_cmd(program, argv, {envs = opt.envs})
end

-- add command tip
function batchcmds:add_tip(format, ...)
    local tip = string.format(format, ...)
    table.insert(self:cmds(), {tip = tip})
end

-- add command tip with progress
function batchcmds:add_progress_tip(progress, format, ...)
    if progress then
        local tip = progress_utils.text(progress, format, ...)
        table.insert(self:cmds(), {tip = tip, progress = progress})
    end
end

-- get deps
function batchcmds:deps()
    return self._DEPS
end

-- add dependent files
function batchcmds:add_depfiles(...)
    local deps = self._DEPS or {}
    deps.files = deps.files or {}
    table.join2(deps.files, ...)
    self._DEPS = deps
end

-- add dependent values
function batchcmds:add_depvalues(...)
    local deps = self._DEPS or {}
    deps.values = deps.values or {}
    table.join2(deps.values, ...)
    self._DEPS = deps
end

-- set the last mtime of dependent files and values
function batchcmds:set_depmtime(lastmtime)
    local deps = self._DEPS or {}
    deps.lastmtime = lastmtime
    self._DEPS = deps
end

-- set cache file of depend info
function batchcmds:set_depcache(cachefile)
    local deps = self._DEPS or {}
    deps.dependfile = cachefile
    self._DEPS = deps
end

-- run cmds
function batchcmds:run(opt)
    opt = opt or {}
    if self:empty() then
        return
    end
    local deps = self:deps()
    if deps and deps.files then
        depend.on_changed(function ()
            _runcmds(self:cmds(), opt)
        end, self:deps())
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
