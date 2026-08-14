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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        xrepo.lua
--

-- imports
import("core.base.option")
import("core.package.addon")

-- run the given xrepo action for the addons
--
-- @note xrepo installs the packages in its own working project, so it works anywhere,
-- and we need not implement the download/dependencies/confirm logic again
--
-- @param action    the action name, e.g. "install", "search"
-- @param names     the addon names, urls or require strings, e.g. {"esp32-devel 1.0.x"}
-- @param opt       the options, e.g. {force = true, includes = "/tmp/xxx.lua"}
--
-- @note we always run it in a working directory which has no project, @see addon.workdir()
--
function main(action, names, opt)
    opt = opt or {}
    local argv = {"lua", "private.xrepo", action, "--addon"}

    -- we need to pass the common options to the sub-process, e.g. -y, -v, -D
    for _, name in ipairs({"yes", "verbose", "diagnosis"}) do
        if option.get(name) then
            table.insert(argv, "--" .. name)
        end
    end
    if opt.force then
        table.insert(argv, "--force")
    end

    -- the extra lua configuration files, e.g. the repositories which a project declares
    if opt.includes then
        table.insert(argv, "--includes=" .. opt.includes)
    end

    table.join2(argv, names)
    os.execv(os.programfile(), argv, {curdir = opt.curdir or addon.workdir()})
end
