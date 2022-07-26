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

-- uninstall headers
function _uninstall_headers(target, opt)
    local includedir = path.join(target:installdir(), opt and opt.includedir or "include")
    local _, dstheaders = target:headerfiles(includedir, {installonly = true})
    for _, dstheader in ipairs(dstheaders) do
        os.vrm(dstheader)
    end
end

-- uninstall shared libraries for package
function _uninstall_shared_for_package(target, pkg, outputdir)
    for _, dllpath in ipairs(table.wrap(pkg:get("libfiles"))) do
        if dllpath:endswith(".dll") then
            local dllname = path.filename(dllpath)
            os.vrm(path.join(outputdir, dllname))
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
    os.tryrm(path.join(binarydir, path.filename(target:symbolfile())))

    -- remove the dependent shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/961
    for _, dep in ipairs(target:orderdeps()) do
        if dep:kind() == "shared" then
            os.vrm(path.join(binarydir, path.filename(dep:targetfile())))
        end
        _uninstall_shared_for_packages(dep, binarydir)
    end

    -- uninstall shared libraries for packages
    _uninstall_shared_for_packages(target, binarydir)
end

-- uninstall shared library
function uninstall_shared(target, opt)

    -- remove the target file
    local binarydir = path.join(target:installdir(), opt and opt.bindir or "bin")
    os.vrm(path.join(binarydir, path.filename(target:targetfile())))
    os.tryrm(path.join(binarydir, path.filename(target:symbolfile())))

    -- remove *.lib for shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/714
    local targetfile = target:targetfile()
    local librarydir = path.join(target:installdir(), opt and opt.libdir or "lib")
    os.vrm(path.join(librarydir, path.basename(targetfile) .. (target:is_plat("mingw") and ".dll.a" or ".lib")))

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
    os.tryrm(path.join(librarydir, path.filename(target:symbolfile())))

    -- remove headers from the include directory
    _uninstall_headers(target, opt)
end

-- uninstall headeronly library
function uninstall_headeronly(target, opt)
    _uninstall_headers(target, opt)
end
