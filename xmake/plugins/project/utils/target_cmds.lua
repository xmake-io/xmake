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
-- @file        target_cmds.lua
--

-- imports
import("core.project.project")
import("core.project.config")
import("core.base.hashset")
import("core.project.rule")
import("private.utils.batchcmds")
import("private.utils.rule_groups")

-- this sourcebatch is built?
function _sourcebatch_is_built(sourcebatch)
    -- we can only use rulename to filter them because sourcekind may be bound to multiple rules
    local rulename = sourcebatch.rulename
    if rulename == "c.build" or rulename == "c++.build"
        or rulename == "asm.build" or rulename == "cuda.build"
        or rulename == "objc.build" or rulename == "objc++.build"
        or rulename == "win.sdk.resource" then
        return true
    end
end

-- get target buildcmd commands
function get_target_buildcmd(target, cmds, opt)
    opt = opt or {}
    local suffix = opt.suffix
    local ignored_rules = hashset.from(opt.ignored_rules or {})
    for _, ruleinst in ipairs(target:orderules()) do
        if not ignored_rules:has(ruleinst:name()) then
            local scriptname = "buildcmd" .. (suffix and ("_" .. suffix) or "")
            local script = ruleinst:script(scriptname)
            if script then
                local batchcmds_ = batchcmds.new({target = target})
                script(target, batchcmds_, {})
                if not batchcmds_:empty() then
                    table.join2(cmds, batchcmds_:cmds())
                end
            end
        end
    end
end

-- get target buildcmd_files commands
function get_target_buildcmd_files(target, cmds, sourcebatch, opt)
    opt = opt or {}

    -- get rule
    local rulename = assert(sourcebatch.rulename, "unknown rule for sourcebatch!")
    local ruleinst = assert(target:rule(rulename) or project.rule(rulename, {namespace = target:namespace()}) or
                        rule.rule(rulename), "unknown rule: %s", rulename)
    local ignored_rules = hashset.from(opt.ignored_rules or {})
    if ignored_rules:has(ruleinst:name()) then
        return
    end

    -- generate commands for xx_buildcmd_files
    local suffix = opt.suffix
    local scriptname = "buildcmd_files" .. (suffix and ("_" .. suffix) or "")
    local script = ruleinst:script(scriptname)
    if script then
        local batchcmds_ = batchcmds.new({target = target})
        script(target, batchcmds_, sourcebatch, {})
        if not batchcmds_:empty() then
            table.join2(cmds, batchcmds_:cmds())
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
                    table.join2(cmds, batchcmds_:cmds())
                end
            end
        end
    end
end

-- get target buildcmd commands of source group
function get_target_buildcmd_sourcegroups(target, cmds, sourcegroups, opt)
    for idx, group in irpairs(sourcegroups) do
        for _, item in pairs(group) do
            -- buildcmd scripts are always in rule, so we need to ignore target item (item.target).
            local sourcebatch = item.sourcebatch
            if item.rule then
                if not _sourcebatch_is_built(sourcebatch) then
                    get_target_buildcmd_files(target, cmds, sourcebatch, opt)
                end
            end
        end
    end
end

