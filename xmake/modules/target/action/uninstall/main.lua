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
import("utils.symbols.depend", {alias = "get_depend_libraries"})
import("private.action.clean.remove_files")

function _get_target_package_libfiles(target, opt)
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
    if target:is_binary() or target:is_shared() then
        local depends = hashset.new()
        local targetfile = target:targetfile()
        local depend_libraries = get_depend_libraries(targetfile, {plat = target:plat(), arch = target:arch()})
        for _, libfile in ipairs(depend_libraries) do
            depends:insert(path.filename(libfile))
        end
        table.remove_if(libfiles, function (_, libfile) return not depends:has(path.filename(libfile)) end)
    end
    return libfiles
end

-- uninstall files
function _uninstall_files(target)
    local _, dstfiles = target:installfiles()
    for _, dstfile in ipairs(dstfiles) do
        remove_files(dstfile, {emptydir = true})
    end
end

-- uninstall headers
function _uninstall_headers(target, opt)
    local includedir = target:includedir()
    local _, dstheaders = target:headerfiles(includedir, {installonly = true})
    for _, dstheader in ipairs(dstheaders) do
        remove_files(dstheader, {emptydir = true})
    end
end

-- uninstall shared libraries
function _uninstall_shared_libraries(target, opt)
    local bindir = target:is_plat("windows", "mingw") and target:bindir() or target:libdir()

    -- get all dependent shared libraries
    local libfiles = {}
    for _, dep in ipairs(target:orderdeps()) do
        if dep:kind() == "shared" then
            local depfile = dep:targetfile()
            if os.isfile(depfile) then
                table.insert(libfiles, depfile)
            end
        end
        table.join2(libfiles, _get_target_package_libfiles(dep, {interface = true}))
    end
    table.join2(libfiles, _get_target_package_libfiles(target))

    -- deduplicate libfiles, prevent packages using the same libfiles from overwriting each other
    libfiles = table.unique(libfiles)

    -- do uninstall
    for _, libfile in ipairs(libfiles) do
        local filename = path.filename(libfile)
        local filepath = path.join(bindir, filename)
        remove_files(filepath, {emptydir = true})
    end
end

-- uninstall binary
function _uninstall_binary(target, opt)
    local bindir = target:bindir()
    remove_files(path.join(bindir, path.filename(target:targetfile())), {emptydir = true})
    remove_files(path.join(bindir, path.filename(target:symbolfile())), {emptydir = true})
    _uninstall_shared_libraries(target, opt)
end

-- uninstall shared library
function _uninstall_shared(target, opt)
    local bindir = target:is_plat("windows", "mingw") and target:bindir() or target:libdir()

    if target:is_plat("windows", "mingw") then
        -- uninstall *.lib for shared/windows (*.dll) target
        -- @see https://github.com/xmake-io/xmake/issues/714
        local libdir = target:libdir()
        local targetfile = target:targetfile()
        remove_files(path.join(bindir, path.filename(targetfile)), {emptydir = true})
        remove_files(path.join(libdir, path.basename(targetfile) .. (target:is_plat("mingw") and ".dll.a" or ".lib")), {emptydir = true})
    else
        local targetfile = path.join(bindir, path.filename(target:targetfile()))
        if os.islink(targetfile) then
            local targetfile_with_soname = os.readlink(targetfile)
            if not path.is_absolute(targetfile_with_soname) then
                targetfile_with_soname = path.join(bindir, targetfile_with_soname)
            end
            if os.islink(targetfile_with_soname) then
                local targetfile_with_version = os.readlink(targetfile_with_soname)
                if not path.is_absolute(targetfile_with_version) then
                    targetfile_with_version = path.join(bindir, targetfile_with_version)
                end
                remove_files(targetfile_with_version, {emptydir = true})
            end
            remove_files(targetfile_with_soname, {emptydir = true})
        end
        remove_files(targetfile, {emptydir = true})
    end
    remove_files(path.join(bindir, path.filename(target:symbolfile())), {emptydir = true})

    _uninstall_headers(target, opt)
    _uninstall_shared_libraries(target, opt)
end

-- uninstall static library
function _uninstall_static(target, opt)
    local libdir = target:libdir()
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
    local installdir = target:installdir()
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

