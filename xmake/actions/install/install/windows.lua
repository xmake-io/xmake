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
-- @file        windows.lua
--

-- imports
import("lib.detect.find_file")

-- install headers
function _install_headers(target)
    local includedir = path.join(target:installdir(), "include")
    os.mkdir(includedir)
    local srcheaders, dstheaders = target:headerfiles(includedir)
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

-- get dll filename from the given .lib library
function _get_dll_filename_from_lib(libpath)
    local libdata = io.readfile(libpath, {encoding = "binary"})
    local _, _, dllname = libdata:find("__IMPORT_DESCRIPTOR_([%a%d_%-%.]+)\0", 1, false)
    if dllname then
        dllname = dllname .. ".dll"
    end
    return dllname
end

-- install shared libraries for package
function _install_shared_for_package(target, pkg, outputdir)
    local linkdirs = pkg:get("linkdirs")
    for _, link in ipairs(table.wrap(pkg:get("links"))) do
        repeat

            -- first search for dlls with same name as lib
            local dllname = link .. ".dll"
            local dllpath = find_file(dllname, linkdirs)
            if dllpath then
                if os.isfile(path.join(outputdir, dllname)) then
                    wprint("'%s' already exists in install dir, overwriting it from package(%s).", dllname, pkg:name())
                end
                os.vcp(dllpath, outputdir)
                break
            end

            -- dll not the same name as lib, find name from lib and search again
            local libname = link .. ".lib"
            local libpath = find_file(libname, linkdirs)
            if libpath then
                local dllname = _get_dll_filename_from_lib(libpath)
                if dllname then
                    local dllpath = find_file(dllname, linkdirs)
                    if dllpath then
                        if os.isfile(path.join(outputdir, dllname)) then
                            wprint("'%s' already exists in install dir, overwriting it from package(%s).", dllname, pkg:name())
                        end
                        os.vcp(dllpath, outputdir)
                        break
                    end
                end
            end
        until false
    end
end

-- install shared libraries for packages
function _install_shared_for_packages(target, outputdir)
    _g.installed_packages = _g.installed_packages or {}
    for _, pkg in ipairs(target:orderpkgs()) do
        if not _g.installed_packages[pkg:name()] then
            local extrainfo = pkg:extrainfo() or {}
            local has_shared = extrainfo.configs and extrainfo.configs.shared
            if has_shared and pkg:enabled() and pkg:get("links") and pkg:get("linkdirs") then
                _install_shared_for_package(target, pkg, outputdir)
            end
            _g.installed_packages[pkg:name()] = true
        end
    end
end

-- install binary
function install_binary(target)

    -- install binary
    local binarydir = path.join(target:installdir(), "bin")
    os.mkdir(binarydir)
    os.vcp(target:targetfile(), binarydir)

    -- install the dependent shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/961
    for _, dep in ipairs(target:orderdeps()) do
        if dep:targetkind() == "shared" and target:is_plat("windows", "mingw") then
            local depfile = dep:targetfile()
            if os.isfile(depfile) then
                os.vcp(depfile, binarydir)
            end
        end
    end

    -- install shared libraries for all packages
    _install_shared_for_packages(target, binarydir)
end

-- install shared library
function install_shared(target)

    -- install dll library to the binary directory
    local binarydir = path.join(target:installdir(), "bin")
    os.mkdir(binarydir)
    os.vcp(target:targetfile(), binarydir)

    -- install *.lib for shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/714
    local targetfile = target:targetfile()
    local librarydir = path.join(target:installdir(), "lib")
    local targetfile_lib = path.join(path.directory(targetfile), path.basename(targetfile) .. ".lib")
    if os.isfile(targetfile_lib) then
        os.mkdir(librarydir)
        os.vcp(targetfile_lib, librarydir)
    end

    -- install shared libraries for all packages
    _install_shared_for_packages(target, binarydir)

    -- install headers
    _install_headers(target)
end

-- install static library
function install_static(target)

    -- install library
    local librarydir = path.join(target:installdir(), "lib")
    os.mkdir(librarydir)
    os.vcp(target:targetfile(), librarydir)

    -- install headers
    _install_headers(target)
end
