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
-- @file        search.lua
--

-- imports
import("core.base.task")
import("core.base.option")
import("private.action.require.impl.utils.filter")
import("private.action.require.impl.repository")
import("private.action.require.impl.environment")
import("private.action.require.impl.search_packages")

-- search the given packages
function main(names)

    -- no names?
    if not names then
        return
    end

    -- enter environment
    environment.enter()

    -- pull all repositories first if not exists
    if not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- get the extra search options, e.g. --extra="{kind='plugin'}"
    local opt = {}
    local extra = option.get("extra")
    if extra then
        local extrainfo, errors = string.deserialize(extra)
        if errors then
            raise(errors)
        end
        if type(extrainfo) == "table" then
            opt.kind = extrainfo.kind
        end
    end

    -- show title
    print("The package names:")

    -- search packages
    for name, packages in pairs(search_packages(names, opt)) do
        if #packages > 0 then

            -- show name
            print("    %s: ", name)

            -- show packages
            for _, result in ipairs(packages) do
                local name = result.name
                local version = result.version
                local reponame = result.reponame
                local description = result.description
                local kind = result.kind
                cprint("      -> ${color.dump.string}%s%s${clear}%s: %s %s", name,
                    version and ("-" .. version) or "",
                    kind == "plugin" and " ${magenta}(plugin)${clear}" or "",
                    description or "",
                    reponame and ("(in " .. reponame .. ")") or "")
            end
        end
    end

    -- leave environment
    environment.leave()
end

