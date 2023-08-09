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
import("core.base.option")
import("core.base.semver")
import("core.base.hashset")
import("core.base.json")
import("core.project.config")
import("core.project.target")
import("lib.detect.find_tool")
import("lib.detect.find_file")
import("private.tools.rust.check_target")

-- get cargo registry directory
function _get_cargo_registrydir()
    return path.join(is_host("windows") and os.getenv("USERPROFILE") or "~", ".cargo", "registry")
end

-- get the Cargo.toml of package
-- e.g. ~/.cargo/registry/src/github.com-1ecc6299db9ec823/obj-rs-0.6.4/Cargo.toml
function _get_package_toml(name)
    local registrydir = _get_cargo_registrydir()
    local registrysrc = path.join(registrydir, "src")
    if os.isdir(registrysrc) then
        local files = os.files(path.join(registrysrc, "*", name .. "-*", "Cargo.toml"))
        for _, file in ipairs(files) do
            local dir = path.directory(file)
            local basename = path.filename(dir)
            if basename:startswith(name) then
                basename = basename:sub(#name + 1)
                if basename:match("^%-[%d%.]+$") then
                    return file
                end
            end
        end
    end
end

-- get rust library name
--
-- e.g.
-- sdl2 -> libsdl2
-- future-util -> libfuture_util
function _get_libname(name)
    -- we attempt to parse libname from Cargo.toml/[lib]
    -- @see https://github.com/xmake-io/xmake/issues/3452
    -- e.g. obj-rs -> libobj
    local tomlfile = _get_package_toml(name)
    if tomlfile then
        local libinfo = false
        local tomldata = io.readfile(tomlfile)
        for _, line in ipairs(tomldata:split("\n")) do
            if line:find("[lib]", 1, true) then
                libinfo = true
            elseif line:find("[", 1, true) then
                libinfo = false
            elseif libinfo then
                local name = line:match("name%s+=%s+\"(.+)\"")
                if name then
                    return "lib" .. name
                end
            end
        end
    end
    return "lib" .. name:gsub("-", "_")
end

-- get the name set of libraries
function _get_names_of_libraries(name, target, configs)
    local names = hashset.new()
    if configs.cargo_toml then
        local cargo = assert(find_tool("cargo"), "cargo not found!")
        local cargo_args = {"metadata", "--format-version", "1", "--manifest-path", configs.cargo_toml, "--color", "never"}
        if check_target(target, true) then
            table.insert(cargo_args, "--filter-platform")
            table.insert(cargo_args, target)
        end
        if configs.features then
            table.insert(cargo_args, "--features")
            table.insert(cargo_args, table.concat(configs.features, ","))
        end
        if configs.default_features == false then
            table.insert(cargo_args, "--no-default-features")
        end

        local output = os.iorunv(cargo.program, cargo_args)
        local metadata = json.decode(output)

        -- fetch the direct dependencies list regradless of the target platform
        table.insert(cargo_args, "--no-deps")
        output = os.iorunv(cargo.program, cargo_args)
        local metadata_no_deps = json.decode(output)
        -- FIXME: should consider the case of multiple packages in a workspace!
        local direct_deps = metadata_no_deps.packages[1].dependencies

        -- get the intersection of the direct dependencies and all dependencies for the target platform
        for _, dep in ipairs(direct_deps) do
            local dep_metadata
            for _, pkg in ipairs(metadata.packages) do
                if pkg.name == dep.name then
                    dep_metadata = pkg
                    break
                end
            end
            if dep_metadata then
                names:insert(_get_libname(dep.name))
            end
        end
    else
        names:insert(_get_libname(name))
    end
    return names
end

-- find package using the cargo package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, require_version = "1.12.x")
--
function main(name, opt)

    -- get configs
    opt = opt or {}
    local configs = opt.configs or {}

    -- get names of libraries
    local names = _get_names_of_libraries(name, opt.arch, configs)
    assert(not names:empty())

    local frameworkdirs
    local frameworks
    local librarydir = path.join(opt.installdir, "lib")
    local libfiles = os.files(path.join(librarydir, "*.rlib"))
    for _, libraryfile in ipairs(libfiles) do
        local filename = path.filename(libraryfile)
        local libraryname = filename:split('-', {plain = true})[1]
        if names:has(libraryname) then
            frameworkdirs = frameworkdirs or {}
            frameworks = frameworks or {}
            table.insert(frameworkdirs, librarydir)
            table.insert(frameworks, libraryfile)
        end
    end
    local result
    if frameworks and frameworkdirs then
        result = result or {}
        result.libfiles = libfiles
        result.frameworkdirs = frameworkdirs and table.unique(frameworkdirs) or nil
        result.frameworks = frameworks
        result.version = opt.require_version
    end
    return result
end
