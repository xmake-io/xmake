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
-- @file        uninstall.lua
--

-- imports
import("core.base.task")
import("core.base.option")
import("private.action.require.impl.repository")
import("private.action.require.impl.environment")
import("private.action.require.impl.uninstall_packages")
import("private.action.require.impl.utils.get_requires")

-- uninstall the given packages
function main(requires_raw)

    -- enter environment
    environment.enter()

    -- pull all repositories first if not exists
    if not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- get requires and extra config
    local requires_extra = nil
    local requires, requires_extra = get_requires(requires_raw)
    if not requires or #requires == 0 then
        return
    end

    -- uninstall packages
    local packages = uninstall_packages(requires, {requires_extra = requires_extra})
    for _, instance in ipairs(packages) do
        print("uninstall: %s%s ok!", instance:name(), instance:version_str() and ("-" .. instance:version_str()) or "")
    end
    if not packages or #packages == 0 then
        cprint("${bright}packages(%s) not found, maybe they don’t exactly match the configuration"
            , requires_raw and table.concat(requires_raw, ", ") or "")
        if os.getenv("XREPO_WORKING") then
            print("please attempt to remove them with `-f/--configs=` option, e.g.")
            print("    - xrepo remove -f \"name=value, ...\" package")
            print("    - xrepo remove -m debug -k shared -f \"name=value, ...\" package")
        else
            print("please attempt to uninstall them with `--extra=` option, e.g.")
            print("    - xmake require --uninstall --extra=\"{configs={...}}\" package")
            print("    - xmake require --uninstall --extra=\"{debug=true,configs={shared=true}}\" package")
        end
    end

    -- leave environment
    environment.leave()
end

