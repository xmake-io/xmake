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

-- install files
function _install_files(target)
    local srcfiles, dstfiles = target:installfiles()
    if srcfiles and dstfiles then
        local i = 1
        for _, srcfile in ipairs(srcfiles) do
            local dstfile = dstfiles[i]
            if dstfile then
                os.vcp(srcfile, dstfile)
            end
            i = i + 1
        end
    end
end

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

-- install shared libraries
function _install_shared_libraries(target, opt)
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

    -- do install
    for _, libfile in ipairs(libfiles) do
        local filename = path.filename(libfile)
        local filepath = path.join(bindir, filename)
        if os.isfile(filepath) then
            wprint("'%s' already exists in install dir, we are copying '%s' to overwrite it.", filepath, libfile)
        end
        os.cp(libfile, filepath)
    end
end

-- install binary
function _install_binary(target, opt)
    local bindir = target:bindir()
    os.mkdir(bindir)
    os.vcp(target:targetfile(), bindir)
    os.trycp(target:symbolfile(), path.join(bindir, path.filename(target:symbolfile())))
    _install_shared_libraries(target, opt)
end

-- install shared library
function _install_shared(target, opt)
    local bindir = target:is_plat("windows", "mingw") and target:bindir() or target:libdir()
    os.mkdir(bindir)
    local targetfile = target:targetfile()

    if target:is_plat("windows", "mingw") then
        -- install *.lib for shared/windows (*.dll) target
        -- @see https://github.com/xmake-io/xmake/issues/714
        os.vcp(target:targetfile(), bindir)
        local libdir = target:libdir()
        local targetfile_lib = path.join(path.directory(targetfile), path.basename(targetfile) .. (target:is_plat("mingw") and ".dll.a" or ".lib"))
        if os.isfile(targetfile_lib) then
            os.mkdir(libdir)
            os.vcp(targetfile_lib, libdir)
        end
    else
        -- install target with soname and symlink
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
                os.vcp(targetfile_with_version, bindir, {symlink = true, force = true})
            end
            os.vcp(targetfile_with_soname, bindir, {symlink = true, force = true})
            os.vcp(targetfile, bindir, {symlink = true, force = true})
        else
            os.vcp(targetfile, bindir)
        end
    end
    os.trycp(target:symbolfile(), path.join(bindir, path.filename(target:symbolfile())))

    _install_headers(target, opt)
    _install_shared_libraries(target, opt)
end

-- install static library
function _install_static(target, opt)
    local libdir = target:libdir()
    os.mkdir(libdir)
    os.vcp(target:targetfile(), libdir)
    os.trycp(target:symbolfile(), path.join(libdir, path.filename(target:symbolfile())))
    _install_headers(target, opt)
end

-- install headeronly library
function _install_headeronly(target, opt)
    _install_headers(target, opt)
end

-- install moduleonly library
function _install_moduleonly(target, opt)
    _install_headers(target, opt)
end

function main(target, opt)
    local installdir = target:installdir()
    if not installdir then
        wprint("please use `xmake install -o installdir` or `set_installdir` to set install directory.")
        return
    end
    print("installing %s to %s ..", target:name(), installdir)

    if target:is_binary() then
        _install_binary(target, opt)
    elseif target:is_shared() then
        _install_shared(target, opt)
    elseif target:is_static() then
        _install_static(target, opt)
    elseif target:is_headeronly() then
        _install_headeronly(target, opt)
    elseif target:is_moduleonly() then
        _install_moduleonly(target, opt)
    end

    _install_files(target)
end
