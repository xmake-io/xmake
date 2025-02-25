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
-- @file        find_package.lua
--

-- imports
import("lib.detect.find_file")
import("lib.detect.find_tool")
import("core.base.option")
import("core.project.config")
import("core.project.target")
import("package.manager.kotlin-native.configurations")

-- find package from the kotlin-native package manager
--
-- @param name  the package name, e.g. org.jetbrains.kotlinx:kotlinx-serialization-json 1.8.0
-- @param opt   the options, e.g. {verbose = true)
--
function main(name, opt)
    opt = opt or {}
    local result = {}
    local installdir = assert(opt.installdir, "installdir not found!")
    local manifest_file = path.join(installdir, "installed_manifest.txt")
    if os.isfile(manifest_file) then
        return io.load(manifest_file)
    end
end
