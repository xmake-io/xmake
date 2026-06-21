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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.tools.rustc.target_triple")
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

-- is it a cargo workspace manifest? (it contains a [workspace] or [workspace.xxx] table)
function _is_workspace_manifest(content)
    for _, line in ipairs(content:split("\n", {plain = true, strict = true})) do
        if line:match("^%s*%[workspace[%].]") then
            return true
        end
    end
    return false
end

-- get the workspace inheritance tables from the workspace root manifest
--
-- if the given Cargo.toml is a member of a cargo workspace and uses workspace inheritance,
-- e.g. `anyhow.workspace = true`, `version.workspace = true`, `[lints] workspace = true`,
-- we need to inject the `[workspace.package]`/`[workspace.dependencies]`/`[workspace.lints]`
-- tables from the workspace root manifest, otherwise cargo will fail to resolve them, e.g.
--
--   error inheriting `anyhow` from workspace root manifest's `workspace.dependencies.anyhow`
--   `workspace.dependencies` was not defined
--
-- @see https://github.com/xmake-io/xmake/issues/7619
-- https://doc.rust-lang.org/cargo/reference/workspaces.html#the-workspacedependencies-table
function _get_workspace_inherited_tables(cargo_toml)

    -- find the workspace root manifest by walking up
    local rootmanifest
    local dir = path.directory(path.absolute(cargo_toml))
    while dir and #dir > 0 do
        local manifest = path.join(dir, "Cargo.toml")
        if os.isfile(manifest) then
            local content = io.readfile(manifest)
            if content and _is_workspace_manifest(content) then
                rootmanifest = manifest
                break
            end
        end
        local parentdir = path.directory(dir)
        if parentdir == dir then
            break
        end
        dir = parentdir
    end

    -- not a workspace member, or the manifest itself is the workspace root (self-contained)
    if not rootmanifest or path.absolute(rootmanifest) == path.absolute(cargo_toml) then
        return
    end

    -- extract all the [workspace.xxx] sub-tables, e.g. [workspace.package]/[workspace.dependencies]/[workspace.lints]
    -- we do not copy the bare [workspace] table (members/exclude), otherwise cargo will search for the member crates.
    local content = io.readfile(rootmanifest)
    if not content then
        return
    end
    local result = {}
    local in_subtable = false
    for _, line in ipairs(content:split("\n", {plain = true, strict = true})) do
        local header = line:match("^%s*%[(.-)%]%s*$")
        if header then
            in_subtable = header:trim():startswith("workspace.")
            if in_subtable then
                table.insert(result, line)
            end
        elseif in_subtable then
            table.insert(result, line)
        end
    end
    if #result == 0 then
        return
    end

    -- translate the local paths in the workspace dependencies, they are relative to the workspace root directory
    local rootdir = path.directory(rootmanifest)
    local workspace_toml = table.concat(result, "\n")
    workspace_toml = workspace_toml:gsub("path%s+=%s+\"(.-)\"", function (localpath)
        if not path.is_absolute(localpath) then
            localpath = path.absolute(localpath, rootdir)
        end
        localpath = localpath:gsub("\\", "/")
        return "path = \"" .. localpath .. "\""
    end)
    return workspace_toml
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
    local target = #opt.arch:split("%-") >= 2 and check_target(opt.arch, true) and opt.arch
    if not target then
        target = target_triple(opt.plat, opt.arch)
    end

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
        -- inject the workspace inheritance tables if the given Cargo.toml is a workspace member,
        -- e.g. `anyhow.workspace = true`. @see https://github.com/xmake-io/xmake/issues/7619
        local workspace_toml = _get_workspace_inherited_tables(configs.cargo_toml)
        if workspace_toml then
            tomlfile:write(workspace_toml)
            tomlfile:print("")
        end
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
