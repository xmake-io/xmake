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
import("core.base.json")
import("core.project.config")
import("core.project.target")

function _find_package(name, targets, libraries, result)
    local libinfo = libraries[name]
    if libinfo then
        print("find", name, libinfo)
    end
    local targetinfo = targets[name]
    if targetinfo then
        local dependencies = targetinfo.dependencies
        if dependencies then
            for k, v in pairs(dependencies) do
                _find_package(k .. "/" .. v, targets, libraries, result)
            end
        end
    end
end

-- find package from the nuget package manager
--
-- @param name  the package name, e.g. zlib, pcre
-- @param opt   the options, e.g. {verbose = true)
--
function main(name, opt)
    opt = opt or {}

    -- load manifest info
    local installdir = assert(opt.installdir, "installdir not found!")
    local stubdir = path.join(installdir, "stub")
    local manifestfile = path.join(stubdir, "obj", "project.assets.json")
    if not os.isfile(manifestfile) then
        return
    end
    local manifest = json.loadfile(manifestfile)
    local targets
    for k, v in pairs(manifest.targets) do
        targets = v
        break
    end
    local target_root
    if targets then
        for k, v in pairs(targets) do
            if k:startswith(name) then
                target_root = k
                break
            end
        end
    end
    local libraries = manifest.libraries
    if target_root and libraries then
        local result = {}
        _find_package(target_root, targets, libraries, result)
        if result.links or result.includedirs then
            return result
        end
    end
end

