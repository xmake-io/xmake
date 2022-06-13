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
-- @file        install.lua
--

-- imports
import("core.base.task")
import("core.project.rule")
import("core.project.project")
import("target.action.install", {alias = "_do_install_target"})

-- on install target
function _on_install_target(target)

    -- trace
    print("installing %s ..", target:name())

    -- build target with rules
    local done = false
    for _, r in ipairs(target:orderules()) do
        local on_install = r:script("install")
        if on_install then
            on_install(target)
            done = true
        end
    end
    if done then return end

    -- do install
    _do_install_target(target)
end

-- install the given target
function _install_target(target)

    -- has been disabled?
    if not target:is_enabled() then
        return
    end

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- enter the environments of the target packages
    local oldenvs = os.addenvs(target:pkgenvs())

    -- the target scripts
    local scripts =
    {
        target:script("install_before")
    ,   function (target)
            for _, r in ipairs(target:orderules()) do
                local before_install = r:script("install_before")
                if before_install then
                    before_install(target)
                end
            end
        end
    ,   target:script("install", _on_install_target)
    ,   function (target)
            for _, r in ipairs(target:orderules()) do
                local after_install = r:script("install_after")
                if after_install then
                    after_install(target)
                end
            end
        end
    ,   target:script("install_after")
    }

    -- install the target scripts
    for i = 1, 5 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end

    -- leave the environments of the target packages
    os.setenvs(oldenvs)

    -- leave project directory
    os.cd(oldir)
end

-- install the given targets
function _install_targets(targets)
    for _, target in ipairs(targets) do
        _install_target(target)
    end
end

-- install targets
function main(targetname, group_pattern)

    -- install the given target?
    if targetname and not targetname:startswith("__") then
        local target = project.target(targetname)
        _install_targets(target:orderdeps())
        _install_target(target)
    else
        -- install default or all targets
        for _, target in ipairs(project.ordertargets()) do
            local group = target:get("group")
            if (target:is_default() and not group_pattern) or targetname == "__all" or (group_pattern and group and group:match(group_pattern)) then
                _install_target(target)
            end
        end
    end
end
