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
-- @file        windows.lua
--

-- imports
import("lib.detect.find_file")

-- install headers
function _install_headers(target, opt)
    local includedir = path.join(target:installdir(), opt and opt.includedir or "include")
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
    _g.installed_dllfiles = _g.installed_dllfiles or {}
    for _, dllpath in ipairs(table.wrap(pkg:get("libfiles"))) do
        if dllpath:endswith(".dll") then
            -- prevent packages using the same libfiles from overwriting each other
            if not _g.installed_dllfiles[dllpath] then
                local dllname = path.filename(dllpath)
                if os.isfile(path.join(outputdir, dllname)) then
                    wprint("'%s' already exists in install dir, overwriting it from package(%s).", dllname, pkg:name())
                end
                os.vcp(dllpath, outputdir)
                _g.installed_dllfiles[dllpath] = true
            end
        end
    end
end

-- install shared libraries for packages
function _install_shared_for_packages(target, outputdir)
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
    local binarydir = path.join(target:installdir(), opt and opt.bindir or "bin")
    os.mkdir(binarydir)
    os.vcp(target:targetfile(), binarydir)
    os.trycp(target:symbolfile(), binarydir)

    -- install the dependent shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/961
    _g.installed_dllfiles = _g.installed_dllfiles or {}
    for _, dep in ipairs(target:orderdeps()) do
        if dep:kind() == "shared" then
            local depfile = dep:targetfile()
            if os.isfile(depfile) then
                if not _g.installed_dllfiles[depfile] then
                    os.vcp(depfile, binarydir)
                    _g.installed_dllfiles[depfile] = true
                end
            end
        end
        -- install all shared libraries in packages in all deps
        _install_shared_for_packages(dep, binarydir)
    end

    -- install shared libraries for all packages
    _install_shared_for_packages(target, binarydir)
end

-- install shared library
function install_shared(target, opt)

    -- install dll library to the binary directory
    local binarydir = path.join(target:installdir(), opt and opt.bindir or "bin")
    os.mkdir(binarydir)
    os.vcp(target:targetfile(), binarydir)
    os.trycp(target:symbolfile(), binarydir)

    -- install *.lib for shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/714
    local targetfile = target:targetfile()
    local librarydir = path.join(target:installdir(), opt and opt.libdir or "lib")
    local targetfile_lib = path.join(path.directory(targetfile), path.basename(targetfile) .. (target:is_plat("mingw") and ".dll.a" or ".lib"))
    if os.isfile(targetfile_lib) then
        os.mkdir(librarydir)
        os.vcp(targetfile_lib, librarydir)
    end

    -- install shared libraries for all packages
    _install_shared_for_packages(target, binarydir)

    -- install headers
    _install_headers(target, opt)
end

-- install static library
function install_static(target, opt)

    -- install library
    local librarydir = path.join(target:installdir(), opt and opt.libdir or "lib")
    os.mkdir(librarydir)
    os.vcp(target:targetfile(), librarydir)
    os.trycp(target:symbolfile(), librarydir)

    -- install headers
    _install_headers(target, opt)
end

-- install headeronly
function install_headeronly(target, opt)
    _install_headers(target, opt)
end
