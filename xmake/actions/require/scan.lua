--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional scanrmation
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
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
-- @file        scan.lua
--

-- imports
import("core.base.option")
import("core.package.package")

-- scan local package
function _scan_package(packagedir)

    -- show packages
    local package_name = path.filename(packagedir)
    for _, versiondir in ipairs(os.dirs(path.join(packagedir, "*"))) do
        local version = path.filename(versiondir)
        cprint("${magenta}%s-%s${clear}:", package_name, version)

        -- show package hash
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
            local manifest = os.isfile(manifest_file) and io.load(manifest_file) or nil
            cprintf("  -> ${yellow}%s${clear}: ${green}%s, %s", hash, manifest and manifest.plat or "", manifest and manifest.arch or "")
            if os.emptydir(hashdir) then
                cprintf(", ${red}empty")
            elseif not referenced then
                cprintf(", ${red}unused")
            elseif not manifest then
                cprintf(", ${red}invalid")
            end
            print("")
            if manifest and manifest.configs then
                print("    -> %s", string.serialize(manifest.configs, true))
            end
        end
    end
end

-- scan local packages
function main(package_names)

    -- trace
    print("scanning packages ..")

    -- scan packages
    local installdir = package.installdir()
    if package_names then
        for _, package_name in ipairs(package_names) do
            for _, packagedir in ipairs(os.dirs(path.join(installdir, package_name:sub(1, 1), package_name))) do
                _scan_package(packagedir)
            end
        end
    else
        for _, packagedir in ipairs(os.dirs(path.join(installdir, "*", "*"))) do
            _scan_package(packagedir)
        end
    end
end

