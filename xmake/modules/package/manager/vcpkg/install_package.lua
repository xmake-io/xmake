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
import("core.base.json")
import("core.base.semver")
import("lib.detect.find_tool")
import("package.manager.vcpkg.configurations")

-- need manifest mode?
function _need_manifest(opt)
    local require_version = opt.require_version
    if require_version ~= nil and require_version ~= "latest" then
        return true
    end
    local configs = opt.configs
    if configs and (configs.features or configs.default_features == false or configs.baseline) then
        return true
    end
end

-- install for classic mode
function _install_for_classic(vcpkg, name, opt)

    -- get configs
    local configs = opt.configs or {}

    -- init triplet
    local arch = opt.arch
    local plat = opt.plat
    plat = configurations.plat(plat)
    arch = configurations.arch(arch)
    local triplet = configurations.triplet(configs, plat, arch)

    -- init argv
    local argv = {"install", name .. ":" .. triplet}
    if option.get("diagnosis") then
        table.insert(argv, "--debug")
    end

    -- install package
    os.vrunv(vcpkg, argv)
end

-- install for manifest mode
function _install_for_manifest(vcpkg, name, opt)

    -- get configs
    local configs = opt.configs or {}

    -- init triplet
    local arch = opt.arch
    local plat = opt.plat
    plat = configurations.plat(plat)
    arch = configurations.arch(arch)
    local triplet = configurations.triplet(configs, plat, arch)

    -- init argv
    local argv = {"--feature-flags=\"versions\"", "install", "--x-wait-for-lock", "--triplet", triplet}
    if option.get("diagnosis") then
        table.insert(argv, "--debug")
    end

    -- generate platform
    local platform = plat .. " & " .. arch

    -- generate dependencies
    local require_version = opt.require_version
    if require_version == "latest" then
        require_version = nil
    end
    -- 1.2.11+13 -> 1.2.11#13
    if require_version then
        require_version = require_version:gsub("%+", "#")
    end
    local minversion = require_version
    if minversion and minversion:startswith(">=") then
        minversion = minversion:sub(3)
    end
    local dependencies = {}
    table.insert(dependencies, {
        name = name,
        ["version>="] = minversion,
        platform = platform,
        features = configs.features,
        ["default-features"] = configs.default_features})

    -- generate overrides to use fixed version
    local overrides
    if require_version and semver.is_valid(require_version) then
        overrides = {{name = name, version = require_version}}
    end

    -- generate manifest, vcpkg.json
    local baseline = configs.baseline or "44d94c2edbd44f0c01d66c2ad95eb6982a9a61bc" -- 2021.04.30
    local manifest = {
        name = "stub",
        version = "1.0",
        dependencies = dependencies,
        ["builtin-baseline"] = baseline,
        overrides = overrides}
    local installdir = assert(opt.installdir, "installdir not found!")
    json.savefile(path.join(installdir, "vcpkg.json"), manifest)
    if not os.isdir(installdir) then
        os.mkdir(installdir)
    end
    if option.get("diagnosis") then
        vprint(path.join(installdir, "vcpkg.json"))
        vprint(manifest)
    end

    -- generate vcpkg-configuration.json
    -- @see https://github.com/xmake-io/xmake/issues/2469
    if configs.registries or configs.default_registries then
        local configuration = {registries = configs.registries, ["default-registries"] = configs.default_registries}
        json.savefile(path.join(installdir, "vcpkg-configuration.json"), configuration)
    end

    -- install package
    os.vrunv(vcpkg, argv, {curdir = installdir})
end

-- install package
--
-- @param name  the package name, e.g. pcre2, pcre2/libpcre2-8
-- @param opt   the options, e.g. {verbose = true}
--
-- @return      true or false
--
function main(name, opt)

    -- attempt to find vcpkg
    local vcpkg = find_tool("vcpkg")
    if not vcpkg then
        raise("vcpkg not found!")
    end

    -- do install
    opt = opt or {}
    if _need_manifest(opt) then
        _install_for_manifest(vcpkg.program, name, opt)
    else
        _install_for_classic(vcpkg.program, name, opt)
    end
end
