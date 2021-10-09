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
-- @file        packagenv.lua
--

-- imports
import("core.package.package", {alias = "core_package"})

-- enter the package environments
function _enter_package(package_name, envs, installdir)
    for name, values in pairs(envs) do
        if name == "PATH" or name == "LD_LIBRARY_PATH" or name == "DYLD_LIBRARY_PATH" then
            for _, value in ipairs(values) do
                if path.is_absolute(value) then
                    os.addenv(name, value)
                else
                    os.addenv(name, path.join(installdir, value))
                end
            end
        else
            os.addenv(name, table.unpack(table.wrap(values)))
        end
    end
end

-- enter environment of the given binary packages, git, 7z, ..
function enter(...)
    local oldenvs = os.getenvs()
    for _, name in ipairs({...}) do
        for _, manifest_file in ipairs(os.files(path.join(core_package.installdir(), name:sub(1, 1), name, "*", "*", "manifest.txt"))) do
            local manifest = io.load(manifest_file)
            if manifest and manifest.plat == os.host() and manifest.arch == os.arch() then
                _enter_package(name, manifest.envs, path.directory(manifest_file))
            end
        end
    end
    return oldenvs
end

