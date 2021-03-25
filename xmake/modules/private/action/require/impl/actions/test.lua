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
-- @file        test.lua
--

-- imports
import("core.base.option")
import("private.action.require.impl.utils.filter")

-- test the given package
function main(package)

    -- enter the test directory
    local testdir = path.join(os.tmpdir(), "pkgtest", package:name(), package:version_str() or "latest")
    if os.isdir(testdir) then
        os.tryrm(testdir)
    end
    if not os.isdir(testdir) then
        os.mkdir(testdir)
    end
    local oldir = os.cd(testdir)

    -- test it
    local script = package:script("test")
    if script ~= nil then
        filter.call(script, package)
    end

    -- restore the current directory
    os.cd(oldir)

    -- remove the test directory
    os.tryrm(testdir)
end
