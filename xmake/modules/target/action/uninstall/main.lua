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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.project")
import("utils.binary.deplibs", {alias = "get_depend_libraries"})
import("private.action.clean.remove_files")

function _get_target_libdir(target, opt)
    if not opt.installdir then
        return target:libdir()
    end
    assert(opt.libdir, "opt.libdir is missing")
    return path.join(opt.installdir, opt.libdir)
end

function _get_target_bindir(target, opt)
    if not opt.installdir then
        return target:bindir()
    end
    assert(opt.bindir, "opt.bindir is missing")
    return path.join(opt.installdir, opt.bindir)
end

function _get_target_includedir(target, opt)
    if not opt.installdir then
        return target:includedir()
    end
    assert(opt.includedir, "opt.includedir is missing")
    return path.join(opt.installdir, opt.includedir)
end

-- we need to get all deplibs, e.g. app -> libfoo.so -> libbar.so ...
-- @see https://github.com/xmake-io/xmake/issues/5325#issuecomment-2242597732
function _get_target_package_deplibs(binaryfile, depends, libfiles, opt)
    local deplibs = get_depend_libraries(binaryfile, {plat = opt.plat, arch = opt.arch})
    local depends_new = hashset.new()
    for _, deplib in ipairs(deplibs) do
        local libname = path.filename(deplib)
        if not depends:has(libname) then
            depends:insert(libname)
            depends_new:insert(libname)
        end
    end
    for _, libfile in ipairs(libfiles) do
        local libname = path.filename(libfile)
        if depends_new:has(libname) then
            _get_target_package_deplibs(libfile, depends, libfiles, opt)
        end
    end
end

function _get_target_package_libfiles(target, opt)
    if option.get("nopkgs") then
        return {}
    end
    opt = opt or {}
    local libfiles = {}
    for _, pkg in ipairs(target:orderpkgs(opt)) do
        if pkg:enabled() and pkg:get("libfiles") then
            for _, libfile in ipairs(table.wrap(pkg:get("libfiles"))) do
                local filename = path.filename(libfile)
                if filename:endswith(".dll") or filename:endswith(".so") or filename:find("%.so%.%d+$") or filename:endswith(".dylib") then
                    table.insert(libfiles, libfile)
                end
            end
        end
    end
    -- we can only reserve used libraries
    if project.policy("install.strip_packagelibs") then
        if target:is_binary() or target:is_shared() or opt.binaryfile then
            local depends = hashset.new()
            _get_target_package_deplibs(opt.binaryfile or target:targetfile(), depends, libfiles, {plat = target:plat(), arch = target:arch()})
            table.remove_if(libfiles, function (_, libfile) return not depends:has(path.filename(libfile)) end)
        end
    end
    return libfiles
end

-- get target libraries
function _get_target_libfiles(target, libfiles, binaryfile, refs)
    if not refs[target] then
        local plaindeps = target:get("deps")
        if plaindeps then
            for _, depname in ipairs(plaindeps) do
                local dep = target:dep(depname)
                if dep then
                    if dep:is_shared() then
                        local depfile = dep:targetfile()
                        if os.isfile(depfile) then
                            table.insert(libfiles, depfile)
                        end
                        _get_target_libfiles(dep, libfiles, dep:targetfile(), refs)
                    elseif dep:is_library() then
                        _get_target_libfiles(dep, libfiles, binaryfile, refs)
                    end
                end
            end
        end
        table.join2(libfiles, _get_target_package_libfiles(target, {binaryfile = binaryfile}))
        refs[target] = true
    end
end

-- remove file with symbols
function _remove_file_with_symbols(filepath)
    if os.islink(filepath) then
        local filepath_symlink = os.readlink(filepath)
        if not path.is_absolute(filepath_symlink) then
            filepath_symlink = path.join(path.directory(filepath), filepath_symlink)
        end
        _remove_file_with_symbols(filepath_symlink)
    end
    remove_files(filepath, {emptydir = true})
end

-- uninstall files
function _uninstall_files(target)
    local _, dstfiles = target:installfiles()
    for _, dstfile in ipairs(dstfiles) do
        remove_files(dstfile, {emptydir = true})
    end
    for _, dep in ipairs(target:orderdeps()) do
        local _, dstfiles = dep:installfiles(dep:installdir(), {interface = true})
        for _, dstfile in ipairs(dstfiles) do
            remove_files(dstfile, {emptydir = true})
        end
    end
end

-- uninstall headers
function _uninstall_headers(target, opt)
    local _, dstheaders = target:headerfiles(_get_target_includedir(target, opt), {installonly = true})
    for _, dstheader in ipairs(dstheaders) do
        remove_files(dstheader, {emptydir = true})
    end
    for _, dep in ipairs(target:orderdeps()) do
        local _, dstfiles = dep:headerfiles(_get_target_includedir(dep, opt), {installonly = true, interface = true})
        for _, dstfile in ipairs(dstfiles) do
            remove_files(dstfile, {emptydir = true})
        end
    end
end

-- uninstall shared libraries
function _uninstall_shared_libraries(target, opt)
    local bindir = target:is_plat("windows", "mingw") and _get_target_bindir(target, opt) or _get_target_libdir(target, opt)

    -- get all dependent shared libraries
    local libfiles = {}
    _get_target_libfiles(target, libfiles, target:targetfile(), {})
    libfiles = table.unique(libfiles)

    -- do uninstall
    for _, libfile in ipairs(libfiles) do
        local filename = path.filename(libfile)
        local filepath = path.join(bindir, filename)
        _remove_file_with_symbols(filepath)
    end
end

-- uninstall binary
function _uninstall_binary(target, opt)
    local bindir = _get_target_bindir(target, opt)
    remove_files(path.join(bindir, path.filename(target:targetfile())), {emptydir = true})
    remove_files(path.join(bindir, path.filename(target:symbolfile())), {emptydir = true})
    _uninstall_shared_libraries(target, opt)
end

-- uninstall shared library
function _uninstall_shared(target, opt)
    local bindir = target:is_plat("windows", "mingw") and _get_target_bindir(target, opt) or _get_target_libdir(target, opt) 
    if target:is_plat("windows", "mingw") then
        -- uninstall *.lib for shared/windows (*.dll) target
        -- @see https://github.com/xmake-io/xmake/issues/714
        local libdir = _get_target_libdir(target, opt)
        local targetfile = target:targetfile()
        remove_files(path.join(bindir, path.filename(targetfile)), {emptydir = true})
        remove_files(path.join(libdir, path.basename(targetfile) .. (target:is_plat("mingw") and ".dll.a" or ".lib")), {emptydir = true})
    else
        local targetfile = path.join(bindir, path.filename(target:targetfile()))
        _remove_file_with_symbols(targetfile)
    end
    remove_files(path.join(bindir, path.filename(target:symbolfile())), {emptydir = true})

    _uninstall_headers(target, opt)
    _uninstall_shared_libraries(target, opt)
end

-- uninstall static library
function _uninstall_static(target, opt)
    local libdir = _get_target_libdir(target, opt)
    remove_files(path.join(libdir, path.filename(target:targetfile())), {emptydir = true})
    remove_files(path.join(libdir, path.filename(target:symbolfile())), {emptydir = true})
    _uninstall_headers(target, opt)
end

-- uninstall headeronly library
function _uninstall_headeronly(target, opt)
    _uninstall_headers(target, opt)
end

-- uninstall moduleonly library
function _uninstall_moduleonly(target, opt)
    _uninstall_headers(target, opt)
end

function main(target, opt)
    opt = opt or {}
    local installdir = opt.installdir or target:installdir()
    if not installdir then
        wprint("please use `xmake install -o installdir` or `set_installdir` to set install directory.")
        return
    end
    print("uninstalling %s to %s ..", target:name(), installdir)

    if target:is_binary() then
        _uninstall_binary(target, opt)
    elseif target:is_shared() then
        _uninstall_shared(target, opt)
    elseif target:is_static() then
        _uninstall_static(target, opt)
    elseif target:is_headeronly() then
        _uninstall_headeronly(target, opt)
    elseif target:is_moduleonly() then
        _uninstall_moduleonly(target, opt)
    end

    _uninstall_files(target)
end

