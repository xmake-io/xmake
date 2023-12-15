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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("lib.detect.find_tool")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")
import(".batchcmds")

-- get the rpmbuild
function _get_rpmbuild()

    -- enter the environments of rpmbuild
    local oldenvs = packagenv.enter("rpm")

    -- find rpmbuild
    local packages = {}
    local rpmbuild = find_tool("rpmbuild")
    if not rpmbuild then
        table.join2(packages, install_packages("rpm"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need to force detect and flush detect cache after loading all environments
    if not rpmbuild then
        rpmbuild = find_tool("rpmbuild", {force = true})
    end
    assert(rpmbuild, "rpmbuild not found!")
    return rpmbuild, oldenvs
end

function main(package)

    if not is_host("linux") then
        return
    end

    cprint("packing %s", package:outputfile())

    -- get rpmbuild
    local rpmbuild, oldenvs = _get_rpmbuild()


    -- done
    os.setenvs(oldenvs)
end
