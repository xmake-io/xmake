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
import("private.action.clean.remove_files")

-- uninstall headers
function _uninstall_headers(target, opt)
    local includedir = path.join(target:installdir(), opt and opt.includedir or "include")
    local _, dstheaders = target:headerfiles(includedir, {installonly = true})
    for _, dstheader in ipairs(dstheaders) do
        remove_files(dstheader, {emptydir = true})
    end
end

-- uninstall shared libraries for package
function _uninstall_shared_for_package(target, pkg, outputdir)
    for _, sopath in ipairs(table.wrap(pkg:get("libfiles"))) do
        if sopath:endswith(".so") or sopath:match(".+%.so%..+$") or sopath:endswith(".dylib") then
            local soname = path.filename(sopath)
            local filepath = path.join(outputdir, soname)
            -- https://github.com/xmake-io/xmake/issues/2665#issuecomment-1209619081
            if os.islink(filepath) then
                -- relative link? e.g. libxx.so -> libxx.4.so
                local realitem = os.readlink(filepath)
                if realitem and not path.is_absolute(realitem) then
                    local realpath = path.join(outputdir, realitem)
                    if os.isfile(realpath) then
                        os.vrm(realpath)
                    end
                end
            end
            remove_files(filepath, {emptydir = true})
        end
    end
end

-- uninstall shared libraries for packages
function _uninstall_shared_for_packages(target, outputdir)
    _g.uninstalled_packages = _g.uninstalled_packages or {}
    for _, pkg in ipairs(target:orderpkgs()) do
        if not _g.uninstalled_packages[pkg:name()] then
            if pkg:enabled() and pkg:get("libfiles") then
                _uninstall_shared_for_package(target, pkg, outputdir)
            end
            _g.uninstalled_packages[pkg:name()] = true
        end
    end
end

-- uninstall binary
function uninstall_binary(target, opt)

    -- remove the target file
    local binarydir = path.join(target:installdir(), opt and opt.bindir or "bin")
    os.vrm(path.join(binarydir, path.filename(target:targetfile())))

    -- remove the dependent shared (*.so) target
    -- @see https://github.com/xmake-io/xmake/issues/961
    local librarydir = path.join(target:installdir(), opt and opt.libdir or "lib")
    for _, dep in ipairs(target:orderdeps()) do
        if dep:kind() == "shared" then
            os.vrm(path.join(librarydir, path.filename(dep:targetfile())))
        end
        _uninstall_shared_for_packages(dep, librarydir)
    end

    -- uninstall shared libraries for packages
    _uninstall_shared_for_packages(target, librarydir)
end

-- uninstall shared library
function uninstall_shared(target, opt)

    -- remove the target file
    local librarydir = path.join(target:installdir(), opt and opt.libdir or "lib")
    os.vrm(path.join(librarydir, path.filename(target:targetfile())))

    -- remove headers from the include directory
    _uninstall_headers(target, opt)

    -- uninstall shared libraries for packages
    _uninstall_shared_for_packages(target, librarydir)
end

-- uninstall static library
function uninstall_static(target, opt)

    -- remove the target file
    local librarydir = path.join(target:installdir(), opt and opt.libdir or "lib")
    os.vrm(path.join(librarydir, path.filename(target:targetfile())))

    -- remove headers from the include directory
    _uninstall_headers(target, opt)
end

-- uninstall headeronly library
function uninstall_headeronly(target, opt)
    _uninstall_headers(target, opt)
end
