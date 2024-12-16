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

function _find_package(name, metainfo, result)
    local libinfo = metainfo.libraries[name]
    if libinfo then
        for _, file in ipairs(libinfo.files) do
            local filepath = path.join(metainfo.packagesdir, name, file)
            print(filepath, os.isfile(filepath))
        end
    end
    local targetinfo = metainfo.targets[name]
    if targetinfo then
        local dependencies = targetinfo.dependencies
        if dependencies then
            for k, v in pairs(dependencies) do
                _find_package(k .. "/" .. v, metainfo, result)
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
    local metainfo = {}
    metainfo.targets = targets
    metainfo.libraries = manifest.libraries
    if manifest.project and manifest.project.restore then
        metainfo.packagesdir = manifest.project.restore.packagesPath
    end
    if target_root and metainfo.targets and metainfo.libraries and metainfo.packagesdir then
        local result = {}
        _find_package(target_root, metainfo, result)
        if result.links or result.includedirs then
            return result
        end
    end
end

