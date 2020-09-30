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

-- uninstall headers
function _uninstall_headers(target, opt)
    local includedir = path.join(target:installdir(), opt and opt.includedir or "include")
    local _, dstheaders = target:headerfiles(includedir)
    for _, dstheader in ipairs(dstheaders) do
        os.vrm(dstheader)
    end
end

-- uninstall shared libraries for package
function _uninstall_shared_for_package(target, pkg, outputdir)
    for _, dllpath in ipairs(table.wrap(pkg:get("libfiles"))) do
        if dllpath:endswith(".dll") then
            os.vrm(path.join(outputdir, dllname))
        end
    end
end

-- uninstall shared libraries for packages
function _uninstall_shared_for_packages(target, outputdir)
    _g.uninstalled_packages = _g.uninstalled_packages or {}
    for _, pkg in ipairs(target:orderpkgs()) do
        if not _g.uninstalled_packages[pkg:name()] then
            local extrainfo = pkg:extrainfo() or {}
            local has_shared = extrainfo.configs and extrainfo.configs.shared
            if has_shared and pkg:enabled() and pkg:get("libfiles") then
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

    -- remove the dependent shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/961
    for _, dep in ipairs(target:orderdeps()) do
        if dep:targetkind() == "shared" and is_plat("windows", "mingw") then
            os.vrm(path.join(binarydir, path.filename(dep:targetfile())))
        end
    end

    -- uninstall shared libraries for packages
    _uninstall_shared_for_packages(target, binarydir)
end

-- uninstall shared library
function uninstall_shared(target, opt)

    -- remove the target file
    local binarydir = path.join(target:installdir(), opt and opt.bindir or "bin")
    os.vrm(path.join(binarydir, path.filename(target:targetfile())))

    -- remove *.lib for shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/714
    local targetfile = target:targetfile()
    local librarydir = path.join(target:installdir(), opt and opt.libdir or "lib")
    os.vrm(path.join(librarydir, path.basename(targetfile) .. ".lib"))

    -- remove headers from the include directory
    _uninstall_headers(target, opt)

    -- uninstall shared libraries for packages
    _uninstall_shared_for_packages(target, binarydir)
end

-- uninstall static library
function uninstall_static(target, opt)

    -- remove the target file
    local librarydir = path.join(target:installdir(), opt and opt.libdir or "lib")
    os.vrm(path.join(librarydir, path.filename(target:targetfile())))

    -- remove headers from the include directory
    _uninstall_headers(target, opt)
end
