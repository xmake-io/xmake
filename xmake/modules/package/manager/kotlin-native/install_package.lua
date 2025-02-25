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
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.base.json")
import("core.base.semver")
import("lib.detect.find_tool")
import("package.manager.kotlin-native.configurations")
import("net.http")

-- select package version
-- e.g. https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-json-iosarm64/maven-metadata.xml
function _select_package_version(name, opt)
    local installdir = opt.installdir
    local manifest_file = path.join(installdir, "maven-metadata.xml")
    for _, repository in ipairs(opt.repositories) do
        local manifest_url = ("%s/%s-%s/maven-metadata.xml", repository, (name:gsub("%.", "/"):gsub(":", "/")), opt.triplet)
        local ok = try {
            function()
                http.download(manifest_url, manifest_file, {
                    insecure = global.get("insecure-ssl")})
                return true
            end
        }
        if ok and os.isfile(manifest_file) then
            local manifest = io.readfile(manifest_file)
            print(manifest)
        end
    end
end

-- install package
--
-- @param name  the package name, e.g. org.jetbrains.kotlinx:kotlinx-serialization-json 1.8.0
-- @param opt   the options, e.g. {verbose = true}
--
function main(name, opt)
    opt = opt or {}
    local configs = opt.configs or {}
    local repositories = opt.repositories

    -- init triplet
    local arch = opt.arch
    local plat = opt.plat
    plat = configurations.plat(plat)
    arch = configurations.arch(arch)
    local triplet = configurations.triplet(plat, arch)

    -- select version
    local installdir = assert(opt.installdir, "installdir not found!")
    local require_version = opt.require_version
    if require_version == "latest" then
        require_version = nil
    end
    local version, repository = _select_package_version(name, {
        triplet = triplet,
        version = require_version,
        installdir = installdir,
        repositories = repositories})
    assert(version and repository, "package(%s): %s not found for %s!", name, require_version, triplet)




end
