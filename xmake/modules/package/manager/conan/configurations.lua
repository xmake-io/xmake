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
-- @file        configurations.lua
--

-- get configurations
function main()
    return
    {
        build          = {description = "Use it to choose if you want to build from sources.", default = "missing", values = {"all", "never", "missing", "outdated"}},
        remote         = {description = "Set the conan remote server."},
        options        = {description = "Set the options values, e.g. OpenSSL:shared=True"},
        imports        = {description = "Set the imports for conan."},
        settings       = {description = "Set the build settings for conan."},
        build_requires = {description = "Set the build requires for conan.", default = "xmake_generator/0.1.0@bincrafters/testing"}
    }
end

