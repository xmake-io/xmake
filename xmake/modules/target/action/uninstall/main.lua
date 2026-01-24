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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.project")
import("private.action.clean.remove_files")
import("private.utils.target", {alias = "target_utils"})

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
    target_utils.get_target_libfiles(target, libfiles, target:targetfile(), {})
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

