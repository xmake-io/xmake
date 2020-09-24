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
-- @file        clean.lua
--

-- imports
import("core.base.option")
import("core.project.cache")
import("core.package.package")

-- clear the unused or invalid package directories
function _clear_packagedirs(packagedir)

    -- clear them
    local package_name = path.filename(packagedir)
    for _, versiondir in ipairs(os.dirs(path.join(packagedir, "*"))) do
        local version = path.filename(versiondir)
        for _, hashdir in ipairs(os.dirs(path.join(versiondir, "*"))) do
            local hash = path.filename(hashdir)
            local references_file = path.join(hashdir, "references.txt")
            local referenced = false
            local references = os.isfile(references_file) and io.load(references_file) or nil
            if references then
                for projectdir, refdate in pairs(references) do
                    if os.isdir(projectdir) then
                        referenced = true
                        break
                    end
                end
            end
            local manifest_file = path.join(hashdir, "manifest.txt")
            local status = nil
            if os.emptydir(hashdir) then
                status = "empty"
            elseif not referenced then
                status = "unused"
            elseif not os.isfile(manifest_file) then
                status = "invalid"
            end
            if status then
                local description = string.format("remove this ${magenta}%s-%s${clear}/${yellow}%s${clear} (${red}%s${clear})", package_name, version, hash, status)
                local confirm = utils.confirm({default = true, description = description})
                if confirm then
                    os.rm(hashdir)
                end
            end
        end
        if os.emptydir(versiondir) then
            os.rm(versiondir)
        end
    end
    if os.emptydir(packagedir) then
        os.rm(packagedir)
    end
end

-- clean the given or all package caches
function main(package_names)

    -- trace
    print("clearing packages ..")

    -- clear all unused packages
    local installdir = package.installdir()
    if package_names then
        for _, package_name in ipairs(package_names) do
            for _, packagedir in ipairs(os.dirs(path.join(installdir, package_name:sub(1, 1), package_name))) do
                _clear_packagedirs(packagedir)
            end
        end
    else
        for _, packagedir in ipairs(os.dirs(path.join(installdir, "*", "*"))) do
            _clear_packagedirs(packagedir)
        end
    end

    -- trace
    print("clearing caches ..")

    -- clear cache directory
    os.rm(package.cachedir())

    -- clear require cache
    local require_cache = cache("local.require")
    require_cache:clear()
    require_cache:flush()
end

