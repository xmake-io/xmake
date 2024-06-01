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
import("private.tools.rust.check_target")

-- translate local path in dependencies
-- @see https://github.com/xmake-io/xmake/issues/4222
-- https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html
--
-- e.g.
-- [dependencies]
-- hello_utils = { path = "./hello_utils", version = "0.1.0" }
--
-- [dependencies.my_lib]
-- path = "../my_lib"
function _translate_local_path_in_deps(cargotoml, rootdir)
    local content = io.readfile(cargotoml)
    content = content:gsub("path%s+=%s+\"(.-)\"", function (localpath)
        if not path.is_absolute(localpath) then
            localpath = path.absolute(localpath, rootdir)
        end
        localpath = localpath:gsub("\\", "/")
        return "path = \"" .. localpath .. "\""
    end)
    io.writefile(cargotoml, content)
end

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

    -- get target
    -- e.g. x86_64-pc-windows-msvc, aarch64-unknown-none
    -- @see https://github.com/xmake-io/xmake/issues/4049
    local target = check_target(opt.arch, true) and opt.arch or nil

    -- generate Cargo.toml
    local sourcedir = path.join(opt.cachedir, "source")
    local cargotoml = path.join(sourcedir, "Cargo.toml")
    os.tryrm(sourcedir)
    if configs.cargo_toml then
        assert(os.isfile(configs.cargo_toml), "%s not found!", configs.cargo_toml)
        os.cp(configs.cargo_toml, cargotoml)
        _translate_local_path_in_deps(cargotoml, path.directory(configs.cargo_toml))
        -- we need add `[workspace]` to prevent cargo from searching up for a parent.
        -- https://github.com/rust-lang/cargo/issues/10534#issuecomment-1087631050
        local tomlfile = io.open(cargotoml, "a")
        tomlfile:print("")
        tomlfile:print("[lib]")
        tomlfile:print("crate-type = [\"staticlib\"]")
        tomlfile:print("")
        tomlfile:print("[workspace]")
        tomlfile:print("")
        tomlfile:close()
    else
        local tomlfile = io.open(cargotoml, "w")
        tomlfile:print("[lib]")
        tomlfile:print("crate-type = [\"staticlib\"]")
        tomlfile:print("")
        tomlfile:print("[package]")
        tomlfile:print("name = \"cargodeps\"")
        tomlfile:print("version = \"0.1.0\"")
        tomlfile:print("edition = \"2018\"")
        tomlfile:print("")
        tomlfile:print("[dependencies]")

        local features = configs.features
        if features then
            features = table.wrap(features)
            tomlfile:print("%s = {version = \"%s\", features = [\"%s\"], default-features = %s}", name, require_version, table.concat(features, "\", \""), configs.default_features)
        else
            tomlfile:print("%s = \"%s\"", name, require_version)
        end
        tomlfile:print("")
        tomlfile:close()
    end

    -- generate .cargo/config.toml
    local configtoml = path.join(sourcedir, ".cargo", "config.toml")
    if target then
        io.writefile(configtoml, format([[
[build]
target = "%s"
]], target))
    end

    -- generate main.rs
    local file = io.open(path.join(sourcedir, "src", "lib.rs"), "w")
    if configs.main == false then
        file:print("#![no_main]")
    end
    if configs.std == false then
        file:print("#![no_std]")
    end
    if configs.main == false then
        file:print([[
    use core::panic::PanicInfo;

    #[panic_handler]
    fn panic(_panic: &PanicInfo<'_>) -> ! {
        loop {}
    }]])
    else
        file:print([[
    fn main() {
        println!("Hello, world!");
    }]])
    end
    file:close()

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
    local librarydir = path.join(installdir, "lib")
    local librarydir_host = path.join(installdir, "lib", "host")
    os.tryrm(librarydir)
    if target then
        os.vcp(path.join(sourcedir, "target", target, opt.mode == "debug" and "debug" or "release", "deps"), librarydir)
        -- @see https://github.com/xmake-io/xmake/issues/5156#issuecomment-2142566862
        os.vcp(path.join(sourcedir, "target", opt.mode == "debug" and "debug" or "release", "deps"), librarydir_host)
    else
        os.vcp(path.join(sourcedir, "target", opt.mode == "debug" and "debug" or "release", "deps"), librarydir)
    end

    -- install metadata
    argv = {"metadata", "--format-version", "1", "--manifest-path", cargotoml, "--color", "never"}
    if target then
        table.insert(argv, "--filter-platform")
        table.insert(argv, target)
    end

    local metadata = os.iorunv(cargo.program, argv, {curdir = sourcedir})

    -- fetch the direct dependencies list regradless of the target platform
    table.insert(argv, "--no-deps")
    local metadata_without_deps = os.iorunv(cargo.program, argv, {curdir = sourcedir})

    io.save(path.join(installdir, "metadata.txt"), {metadata = metadata, metadata_without_deps = metadata_without_deps})
end
