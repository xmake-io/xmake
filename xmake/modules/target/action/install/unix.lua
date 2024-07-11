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
-- @file        unix.lua
--

-- imports
import("core.base.option")

-- install headers
function _install_headers(target, opt)
    local includedir = target:includedir()
    os.mkdir(includedir)
    local srcheaders, dstheaders = target:headerfiles(includedir, {installonly = true})
    if srcheaders and dstheaders then
        local i = 1
        for _, srcheader in ipairs(srcheaders) do
            local dstheader = dstheaders[i]
            if dstheader then
                os.vcp(srcheader, dstheader)
            end
            i = i + 1
        end
    end
end

-- install shared libraries for package
function _install_shared_for_package(target, pkg, outputdir)
    _g.installed_libfiles = _g.installed_libfiles or {}
    for _, sopath in ipairs(table.wrap(pkg:get("libfiles"))) do
        if sopath:endswith(".so") or sopath:match(".+%.so%..+$") or sopath:endswith(".dylib") then
            -- prevent packages using the same system libfiles from overwriting each other
            if not _g.installed_libfiles[sopath] then
                local soname = path.filename(sopath)
                local targetname = path.join(outputdir, soname)
                if os.isfile(targetname) then
                    wprint("'%s' already exists in install dir, overwriting it from package(%s).", soname, pkg:name())
                    -- rm because symlink cannot overwrite existing file
                    os.rm(targetname)
                end
                -- we need to reserve symlink
                -- @see https://github.com/xmake-io/xmake/issues/1582
                os.vcp(sopath, outputdir, {symlink = true, force = true})
                _g.installed_libfiles[sopath] = true
            end
        end
    end
end

-- install shared libraries for packages
function _install_shared_for_packages(target, outputdir)
    if option.get("nopkgs") then
        return
    end
    _g.installed_packages = _g.installed_packages or {}
    for _, pkg in ipairs(target:orderpkgs()) do
        if not _g.installed_packages[pkg:name()] then
            if pkg:enabled() and pkg:get("libfiles") then
                _install_shared_for_package(target, pkg, outputdir)
            end
            _g.installed_packages[pkg:name()] = true
        end
    end
end

-- install binary
function install_binary(target, opt)

    -- install binary
    local bindir = target:bindir()
    os.mkdir(bindir)
    os.vcp(target:targetfile(), bindir)

    -- install libraries
    local libdir = target:libdir()
    os.mkdir(libdir)

    -- install the dependent shared (*.so) target
    -- @see https://github.com/xmake-io/xmake/issues/961
    for _, dep in ipairs(target:orderdeps()) do
        if dep:kind() == "shared" then
            local depfile = dep:targetfile()
            if os.isfile(depfile) then
                os.vcp(depfile, libdir)
            end
        end
        -- install all shared libraries in packages in all deps
        _install_shared_for_packages(dep, libdir)
    end

    -- install shared libraries for all packages
    _install_shared_for_packages(target, libdir)
end

-- install shared library
function install_shared(target, opt)

    -- install libraries
    local libdir = target:libdir()
    os.mkdir(libdir)
    local targetfile = target:targetfile()
    if os.islink(targetfile) then
        local targetfile_with_soname = os.readlink(targetfile)
        if not path.is_absolute(targetfile_with_soname) then
            targetfile_with_soname = path.join(target:targetdir(), targetfile_with_soname)
        end
        if os.islink(targetfile_with_soname) then
            local targetfile_with_version = os.readlink(targetfile_with_soname)
            if not path.is_absolute(targetfile_with_version) then
                targetfile_with_version = path.join(target:targetdir(), targetfile_with_version)
            end
            os.vcp(targetfile_with_version, libdir, {symlink = true, force = true})
        end
        os.vcp(targetfile_with_soname, libdir, {symlink = true, force = true})
        os.vcp(targetfile, libdir, {symlink = true, force = true})
    else
        os.vcp(targetfile, libdir)
    end

    -- install shared libraries for all packages
    _install_shared_for_packages(target, libdir)

    -- install headers
    _install_headers(target, opt)
end

-- install static library
function install_static(target, opt)

    -- install libraries
    local libdir = target:libdir()
    os.mkdir(libdir)
    os.vcp(target:targetfile(), libdir)

    -- install headers
    _install_headers(target, opt)
end

-- install headeronly library
function install_headeronly(target, opt)
    _install_headers(target, opt)
end

-- install moduleonly library
function install_moduleonly(target, opt)
    _install_headers(target, opt)
end
