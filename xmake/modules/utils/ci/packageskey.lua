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
-- @file        packageskey.lua
--

-- imports
import("core.base.option")
import("private.action.require.impl.package")
import("private.action.require.impl.utils.get_requires")

-- generate a hash key of all packages to cache packages on github/ci
--
-- on windows.yml
--
-- - name: Retrieve dependencies hash
--   id: packageskey
--   run: echo "::set-output name=hash::$(xmake l utils.ci.packageskey)"

-- Cache xmake dependencies
-- - name: Retrieve cached xmake dependencies
--   uses: actions/cache@v2
--   with:
--     path: ${{env.APPLOCALDATA}}\.xmake\packages
--     key: ${{ steps.packageskey.outputs.hash }}
--
function main(requires_raw)

    -- get requires and extra config
    local requires_extra = nil
    local requires, requires_extra = get_requires(requires_raw)
    if not requires or #requires == 0 then
        return
    end

    -- get keys
    local keys = {}
    for _, instance in ipairs(package.load_packages(requires, {requires_extra = requires_extra})) do
        table.insert(keys, instance:installdir()) -- contain name/version/buildhash
    end
    table.sort(keys)
    keys = table.concat(keys, ",")
    print(hash.uuid4(keys):gsub('-', ''):lower())
end


