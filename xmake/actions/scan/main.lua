--!A cross-platform scan utility based on Lua
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
-- @author      ruki, Arthapz
-- @file        main.lua
--

import("core.base.option")
import("core.base.global")
import("core.base.task")
import("core.project.rule")
import("core.project.config")
import("core.project.project")
import("core.theme.theme")
import("utils.progress")
import("check", {alias = "check_targets"})
import("scan")

-- do global project rules
function _do_project_rules(scriptname, opt)
    for _, rulename in ipairs(project.get("target.rules")) do
        local r = project.rule(rulename) or rule.rule(rulename)
        if r and r:kind() == "project" then
            local scanscript = r:script(scriptname)
            if scanscript then
                scanscript(opt)
            end
        end
    end
end

function _do_scan(targetnames, group_pattern)
    local sourcefiles = option.get("files")
    if sourcefiles then

    else
        scan(targetnames, group_pattern)
    end
end

function scan_targets(targetnames, opt)
    opt = opt or {}

    local group_pattern = opt.group_pattern
    try
    {
        function ()

            -- do rules before scaning
            _do_project_rules("scan_before")

            -- do scan
            _do_scan(targetnames, group_pattern)

            -- do check
            check_targets(targetnames, {scan = true})

            -- dump cache stats
            -- if option.get("diagnosis") then
            --     scan_cache.dump_stats()
            -- end
        end,
        catch
        {
            function (errors)

                -- @see https://github.com/xmake-io/xmake/issues/3401
                check_targets(targetnames, {scan_failure = true})

                -- do rules after scaning
                _do_project_rules("scan_after", {errors = errors})

                -- raise
                if errors then
                    raise(errors)
                elseif group_pattern then
                    raise("scan targets with group(%s) failed!", group_pattern)
                elseif targetnames then
                    targetnames = table.wrap(targetnames)
                    raise("scan target: %s failed!", table.concat(targetnames, ", "))
                else
                    raise("scan target failed!")
                end
            end
        }
    }

    -- do rules after scanning
    _do_project_rules("scan_after")
end

function main()
  -- lock the whole project
  project.lock()

  -- config it first
  local targetname
  local group_pattern = option.get("group")
  if group_pattern then
      group_pattern = "^" .. path.pattern(group_pattern) .. "$"
  else
      targetname = option.get("target")
  end
  task.run("config", {}, {disable_dump = true})

  -- scan targets
  local scan_time = os.mclock()
  scan_targets(targetname, {group_pattern = group_pattern})
  scan_time = os.mclock() - scan_time

  -- unlock the whole project
  project.unlock()
  
  -- trace
  local str = ""
  if scan_time then
      str = string.format(", spent %ss", scan_time / 1000)
  end
  progress.show(100, "${color.success}scan ok%s", str)
end
