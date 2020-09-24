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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xcodeproj.lua
--

-- imports
import(".cmake.cmakelists")
import("lib.detect.find_tool")

-- TODO maybe we need implement it by myself, do not use cmake
function make(outputdir)

    -- check
    assert(is_plat(os.host()), "only support host platform now!")

    -- find cmake
    local cmake = assert(find_tool("cmake"), "we need cmake to generate xcode project!")

    -- get the cmakelists file
    local cmakefile = path.join(outputdir, "CMakeLists.txt")
    if not os.isfile(cmakefile) then
        cmakelists.make(outputdir)
    end
    assert(os.isfile(cmakefile), "CMakeLists.txt not found!")

    -- generate xcode project
    local oldir = os.cd(os.projectdir())
    os.vrunv(cmake.program, {"-G", "Xcode", cmakefile})
    os.cd(oldir)
end
