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
import("core.project.config")
import("lib.detect.find_tool")

-- install package
--
-- e.g.
-- add_requires("cargo::base64")
-- add_requires("cargo::base64 0.13.0")
-- add_requires("cargo::flate2 1.0.17", {configs = {features = {"zlib"}, ["default-features"] = false}})
-- add_requires("cargo::xxx", {configs = {cargo_toml = path.join(os.projectdir(), "Cargo.toml")}})
--
-- @param name  the package name, e.g. cargo::base64
-- @param opt   the options, e.g. { verbose = true, mode = "release", plat = , arch = , require_version = "x.x.x"}
--
-- @return      true or false
--
function main(name, opt)

    -- find cargo
    local cargo = find_tool("cargo")
    if not cargo then
        raise("cargo not found!")
    end

    -- get required version
    opt = opt or {}
    local configs = opt.configs or {}
    local require_version = opt.require_version
    if not require_version or require_version == "latest" then
        require_version = "*"
    end

    -- generate Cargo.toml
    local sourcedir = path.join(opt.cachedir, "source")
    local cargotoml = path.join(sourcedir, "Cargo.toml")
    os.tryrm(sourcedir)
    if configs.cargo_toml then
        assert(os.isfile(configs.cargo_toml), "%s not found!", configs.cargo_toml)
        os.cp(configs.cargo_toml, cargotoml)
        -- we need add `[workspace]` to prevent cargo from searching up for a parent.
        -- https://github.com/rust-lang/cargo/issues/10534#issuecomment-1087631050
        local tomlfile = io.open(cargotoml, "a")
        tomlfile:print("")
        tomlfile:print("[workspace]")
        tomlfile:print("")
        tomlfile:close()
    else
        local tomlfile = io.open(cargotoml, "w")
        tomlfile:print("[package]")
        tomlfile:print("name = \"cargodeps\"")
        tomlfile:print("version = \"0.1.0\"")
        tomlfile:print("edition = \"2018\"")
        tomlfile:print("")
        tomlfile:print("[dependencies]")
        tomlfile:print("")

        local features = configs.features
        if features then
            features = table.wrap(features)
            tomlfile:print("%s = {version = \"%s\", features = [\"%s\"], default-features = %s}", name, require_version, table.concat(features, "\", \""), configs.default_features)
        else
            tomlfile:print("%s = \"%s\"", name, require_version)
        end
        tomlfile:close()
    end

    -- generate main.rs
    io.writefile(path.join(sourcedir, "src", "main.rs"), [[
fn main() {
    println!("Hello, world!");
}
    ]])

    -- do build
    local argv = {"build"}
    if opt.mode ~= "debug" then
        table.insert(argv, "--release")
    end
    if option.get("verbose") then
        table.insert(argv, option.get("diagnosis") and "-vv" or "-v")
    end
    os.vrunv(cargo.program, argv, {curdir = sourcedir})

    -- do install
    local installdir = opt.installdir
    os.tryrm(path.join(installdir, "lib"))
    os.vcp(path.join(sourcedir, "target", opt.mode == "debug" and "debug" or "release", "deps"), path.join(installdir, "lib"))
end
