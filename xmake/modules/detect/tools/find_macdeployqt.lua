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
-- @author      RubMaker
-- @file        find_macdeployqt.lua
--

-- imports
import("lib.detect.find_program")
import("detect.sdks.find_qt")

-- find macdeployqt
--
-- @return      program
--
-- @code
--
-- local macdeployqt = find_macdeployqt()
--
-- @endcode
--
function main()

    -- find program from system PATH
    local program = find_program("macdeployqt")

    -- If not found, try to find it in the Qt installation
    if not program then
        local qt = find_qt()
        if qt and qt.bindir then
            local macdeployqt_path = path.join(qt.bindir, "macdeployqt")
            if os.isfile(macdeployqt_path) then
                program = {program = macdeployqt_path}
            end
        end
    end

    return program
end