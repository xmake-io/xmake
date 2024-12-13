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
-- @file        batchcmds.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.project")
import("utils.archive")
import("utils.binary.deplibs", {alias = "get_depend_libraries"})
import("private.utils.batchcmds")

function _get_target_bindir(package, target)
    local bindir = package:bindir()
    local prefixdir = target:prefixdir()
    if prefixdir then
        bindir = path.join(package:installdir(), prefixdir, target:extraconf("prefixdir", prefixdir, "bindir") or "bin")
    end
    return path.normalize(bindir)
end

function _get_target_libdir(package, target)
    local libdir = package:libdir()
    local prefixdir = target:prefixdir()
    if prefixdir then
        libdir = path.join(package:installdir(), prefixdir, target:extraconf("prefixdir", prefixdir, "libdir") or "lib")
    end
    return path.normalize(libdir)
end

function _get_target_includedir(package, target)
    local includedir = package:includedir()
    local prefixdir = target:prefixdir()
    if prefixdir then
        includedir = path.join(package:installdir(), prefixdir, target:extraconf("prefixdir", prefixdir, "includedir") or "include")
    end
    return path.normalize(includedir)
end

function _get_target_installdir(package, target)
    local installdir = package:installdir()
    local prefixdir = target:prefixdir()
    if prefixdir then
        installdir = path.join(package:installdir(), prefixdir)
    end
    return path.normalize(installdir)
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

-- copy file with symlinks
function _copy_file_with_symlinks(batchcmds_, srcfile, outputdir)
    if os.islink(srcfile) then
        local srcfile_symlink = os.readlink(srcfile)
        if not path.is_absolute(srcfile_symlink) then
            srcfile_symlink = path.join(path.directory(srcfile), srcfile_symlink)
        end
        _copy_file_with_symlinks(batchcmds_, srcfile_symlink, outputdir)
        batchcmds_:cp(srcfile, path.join(outputdir, path.filename(srcfile)), {symlink = true, force = true})
    else
        batchcmds_:cp(srcfile, path.join(outputdir, path.filename(srcfile)))
    end
end

-- update install rpath, we can only get and update rpathdirs with `{installonly = true}`
-- e.g. add_rpathdirs("@loader_path/../lib", {installonly = true})
function _update_target_install_rpath(target, batchcmds_, opt)
    if target:is_plat("windows", "mingw") then
        return
    end
    local package = opt.package
    local bindir = _get_target_bindir(package, target)
    local targetfile = path.join(bindir, target:filename())
    if target:policy("install.rpath") then
        batchcmds_:clean_rpath(targetfile, {plat = target:plat(), arch = target:arch()})
        local result, sources = target:get_from("rpathdirs", "*")
        if result and sources then
            for idx, rpathdirs in ipairs(result) do
                local source = sources[idx]
                local extraconf = target:extraconf_from("rpathdirs", source)
                if extraconf then
                    for _, rpathdir in ipairs(rpathdirs) do
                        local extra = extraconf[rpathdir]
                        if extra and extra.installonly then
                            batchcmds_:insert_rpath(targetfile, rpathdir, {plat = target:plat(), arch = target:arch()})
                        end
                    end
                end
            end
        end
    end
end

-- install target files
function _install_target_files(target, batchcmds_, opt)
    local package = opt.package
    local srcfiles, dstfiles = target:installfiles(_get_target_installdir(package, target))
    if srcfiles and dstfiles then
        for idx, srcfile in ipairs(srcfiles) do
            batchcmds_:cp(srcfile, dstfiles[idx], {symlink = true})
        end
    end
    for _, dep in ipairs(target:orderdeps()) do
        local srcfiles, dstfiles = dep:installfiles(_get_target_installdir(package, dep), {interface = true})
        if srcfiles and dstfiles then
            for idx, srcfile in ipairs(srcfiles) do
                batchcmds_:cp(srcfile, dstfiles[idx], {symlink = true})
            end
        end
    end
end

-- install target headers
function _install_target_headers(target, batchcmds_, opt)
    local package = opt.package
    local srcheaders, dstheaders = target:headerfiles(_get_target_includedir(package, target), {installonly = true})
    if srcheaders and dstheaders then
        for idx, srcheader in ipairs(srcheaders) do
            batchcmds_:cp(srcheader, dstheaders[idx])
        end
    end
    for _, dep in ipairs(target:orderdeps()) do
        local srcheaders, dstheaders = dep:headerfiles(_get_target_includedir(package, dep), {installonly = true, interface = true})
        if srcheaders and dstheaders then
            for idx, srcheader in ipairs(srcheaders) do
                batchcmds_:cp(srcheader, dstheaders[idx])
            end
        end
    end
end

-- install target shared libraries
function _install_target_shared_libraries(target, batchcmds_, opt)
    local package = opt.package
    local bindir = target:is_plat("windows", "mingw") and _get_target_bindir(package, target) or _get_target_libdir(package, target)

    -- get all dependent shared libraries
    local libfiles = {}
    _get_target_libfiles(target, libfiles, target:targetfile(), {})
    libfiles = table.unique(libfiles)

    -- do install
    for _, libfile in ipairs(libfiles) do
        _copy_file_with_symlinks(batchcmds_, libfile, bindir)
    end
end

-- uninstall target files
function _uninstall_target_files(target, batchcmds_, opt)
    local package = opt.package
    local _, dstfiles = target:installfiles(_get_target_installdir(package, target))
    for _, dstfile in ipairs(dstfiles) do
        batchcmds_:rm(dstfile, {emptydirs = true})
    end
    for _, dep in ipairs(target:orderdeps()) do
        local _, dstfiles = dep:installfiles(_get_target_installdir(package, dep), {interface = true})
        for _, dstfile in ipairs(dstfiles) do
            batchcmds_:rm(dstfile, {emptydirs = true})
        end
    end
end

-- uninstall target headers
function _uninstall_target_headers(target, batchcmds_, opt)
    local package = opt.package
    local _, dstheaders = target:headerfiles(_get_target_includedir(package, target), {installonly = true})
    for _, dstheader in ipairs(dstheaders) do
        batchcmds_:rm(dstheader, {emptydirs = true})
    end
    for _, dep in ipairs(target:orderdeps()) do
        local _, dstheaders = dep:headerfiles(_get_target_includedir(package, dep), {installonly = true, interface = true})
        for _, dstheader in ipairs(dstheaders) do
            batchcmds_:rm(dstheader, {emptydirs = true})
        end
    end
end

-- uninstall target shared libraries
function _uninstall_target_shared_libraries(target, batchcmds_, opt)
    local package = opt.package
    local bindir = target:is_plat("windows", "mingw") and _get_target_bindir(package, target) or _get_target_libdir(package, target)

    -- get all dependent shared libraries
    local libfiles = {}
    _get_target_libfiles(target, libfiles, target:targetfile(), {})
    libfiles = table.unique(libfiles)

    -- do uninstall
    for _, libfile in ipairs(libfiles) do
        local filename = path.filename(libfile)
        batchcmds_:rm(path.join(bindir, filename), {emptydirs = true})
    end
end

-- on install binary target command
function _on_target_installcmd_binary(target, batchcmds_, opt)
    local package = opt.package
    local bindir = _get_target_bindir(package, target)
    batchcmds_:cp(target:targetfile(), path.join(bindir, target:filename()))
    if os.isfile(target:symbolfile()) then
        batchcmds_:cp(target:symbolfile(), path.join(bindir, path.filename(target:symbolfile())))
    end
    _install_target_shared_libraries(target, batchcmds_, opt)
    _update_target_install_rpath(target, batchcmds_, opt)
end

-- on install shared target command
function _on_target_installcmd_shared(target, batchcmds_, opt)
    local package = opt.package
    local bindir = target:is_plat("windows", "mingw") and _get_target_bindir(package, target) or _get_target_libdir(package, target)
    local libdir = _get_target_libdir(package, target)

    _copy_file_with_symlinks(batchcmds_, target:targetfile(), bindir)
    if os.isfile(target:symbolfile()) then
        batchcmds_:cp(target:symbolfile(), path.join(bindir, path.filename(target:symbolfile())))
    end

    -- install *.lib for shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/714
    local targetfile = target:targetfile()
    local targetfile_lib = path.join(path.directory(targetfile), path.basename(targetfile) .. (target:is_plat("mingw") and ".dll.a" or ".lib"))
    if os.isfile(targetfile_lib) then
        batchcmds_:mkdir(libdir)
        batchcmds_:cp(targetfile_lib, path.join(libdir, path.filename(targetfile_lib)))
    end

    _install_target_headers(target, batchcmds_, opt)
    _install_target_shared_libraries(target, batchcmds_, opt)
end

-- on install static target command
function _on_target_installcmd_static(target, batchcmds_, opt)
    local package = opt.package
    local libdir = _get_target_libdir(package, target)

    batchcmds_:cp(target:targetfile(), path.join(libdir, target:filename()))
    if os.isfile(target:symbolfile()) then
        batchcmds_:cp(target:symbolfile(), path.join(libdir, path.filename(target:symbolfile())))
    end

    _install_target_headers(target, batchcmds_, opt)
end

-- on install headeronly target command
function _on_target_installcmd_headeronly(target, batchcmds_, opt)
    _install_target_headers(target, batchcmds_, opt)
end

-- on install source target command
function _on_target_installcmd_source(target, batchcmds_, opt)
    local package = opt.package
    batchcmds_:vrunv("xmake", {"install", "-P", ".", "-y", "-o", path(package:install_rootdir()), target:name()})
end

-- on build target command
function _on_target_buildcmd(target, batchcmds_, opt)
    local package = opt.package
    batchcmds_:vrunv("xmake", {"build", "-P", ".",  "-y", target:name()})
end

-- on install target command
function _on_target_installcmd(target, batchcmds_, opt)
    local package = opt.package
    if package:from_source() then
        _on_target_installcmd_source(target, batchcmds_, opt)
        return
    end

    -- install target binaries
    local scripts = {
        binary     = _on_target_installcmd_binary,
        shared     = _on_target_installcmd_shared,
        static     = _on_target_installcmd_static,
        headeronly = _on_target_installcmd_headeronly
    }
    local script = scripts[target:kind()]
    if script then
        script(target, batchcmds_, opt)
    end

    -- install target files
    _install_target_files(target, batchcmds_, opt)
end

-- on uninstall binary target command
function _on_target_uninstallcmd_binary(target, batchcmds_, opt)
    local package = opt.package
    local bindir = _get_target_bindir(package, target)

    -- uninstall target file
    batchcmds_:rm(path.join(bindir, target:filename()), {emptydirs = true})
    batchcmds_:rm(path.join(bindir, path.filename(target:symbolfile())), {emptydirs = true})

    -- uninstall target shared libraries
    _uninstall_target_shared_libraries(target, batchcmds_, opt)
end

-- on uninstall shared target command
function _on_target_uninstallcmd_shared(target, batchcmds_, opt)
    local package = opt.package
    local bindir = target:is_plat("windows", "mingw") and _get_target_bindir(package, target) or _get_target_libdir(package, target)
    local libdir = _get_target_libdir(package, target)

    -- uninstall target file
    batchcmds_:rm(path.join(bindir, target:filename()), {emptydirs = true})
    batchcmds_:rm(path.join(bindir, path.filename(target:symbolfile())), {emptydirs = true})

    -- uninstall *.lib for shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/714
    local targetfile = target:targetfile()
    batchcmds_:rm(path.join(libdir, path.basename(targetfile) .. (target:is_plat("mingw") and ".dll.a" or ".lib")), {emptydirs = true})

    -- uninstall target headers
    _uninstall_target_headers(target, batchcmds_, opt)

    -- uninstall target shared libraries
    _uninstall_target_shared_libraries(target, batchcmds_, opt)
end

-- on uninstall static target command
function _on_target_uninstallcmd_static(target, batchcmds_, opt)
    local package = opt.package
    local libdir = _get_target_libdir(package, target)

    -- uninstall target file
    batchcmds_:rm(path.join(libdir, target:filename()), {emptydirs = true})
    batchcmds_:rm(path.join(libdir, path.filename(target:symbolfile())), {emptydirs = true})

    -- remove headers from the include directory
    _uninstall_target_headers(target, batchcmds_, opt)
end

-- on uninstall headeronly target command
function _on_target_uninstallcmd_headeronly(target, batchcmds_, opt)
    _uninstall_target_headers(target, batchcmds_, opt)
end

-- on uninstall source target command
function _on_target_uninstallcmd_source(target, batchcmds_, opt)
    -- TODO
end

-- on uninstall target command
function _on_target_uninstallcmd(target, batchcmds_, opt)
    local package = opt.package
    if package:from_source() then
        _on_target_uninstallcmd_source(target, batchcmds_, opt)
        return
    end

    -- uninstall target binaries
    local scripts = {
        binary     = _on_target_uninstallcmd_binary,
        shared     = _on_target_uninstallcmd_shared,
        static     = _on_target_uninstallcmd_static,
        headeronly = _on_target_uninstallcmd_headeronly
    }
    local script = scripts[target:kind()]
    if script then
        script(target, batchcmds_, opt)
    end

    -- uninstall target files
    _uninstall_target_files(target, batchcmds_, opt)
end

-- get build commands from targets
function _get_target_buildcmds(target, batchcmds_, opt)

    -- call script to get build commands
    local scripts = {
        target:script("buildcmd_before"), -- TODO unused
        function (target)
            for _, r in ipairs(target:orderules()) do
                local before_buildcmd = r:script("buildcmd_before")
                if before_buildcmd then
                    before_buildcmd(target, batchcmds_, opt)
                end
            end
        end,
        target:script("buildcmd", _on_target_buildcmd), -- TODO unused
        function (target)
            for _, r in ipairs(target:orderules()) do
                local after_buildcmd = r:script("buildcmd_after")
                if after_buildcmd then
                    after_buildcmd(target, batchcmds_, opt)
                end
            end
        end,
        target:script("buildcmd_after") -- TODO unused
    }
    for i = 1, 5 do
        local script = scripts[i]
        if script ~= nil then
            script(target, batchcmds_, opt)
        end
    end
end

-- get install commands from targets
function _get_target_installcmds(target, batchcmds_, opt)

    -- call script to get install commands
    local scripts = {
        target:script("installcmd_before"),
        function (target)
            for _, r in ipairs(target:orderules()) do
                local before_installcmd = r:script("installcmd_before")
                if before_installcmd then
                    before_installcmd(target, batchcmds_, opt)
                end
            end
        end,
        target:script("installcmd", _on_target_installcmd),
        function (target)
            for _, r in ipairs(target:orderules()) do
                local after_installcmd = r:script("installcmd_after")
                if after_installcmd then
                    after_installcmd(target, batchcmds_, opt)
                end
            end
        end,
        target:script("installcmd_after")
    }
    for i = 1, 5 do
        local script = scripts[i]
        if script ~= nil then
            script(target, batchcmds_, opt)
        end
    end
end

-- get uninstall commands from targets
function _get_target_uninstallcmds(target, batchcmds_, opt)

    -- call script to get uninstall commands
    local scripts = {
        target:script("uninstallcmd_before"),
        function (target)
            for _, r in ipairs(target:orderules()) do
                local before_uninstallcmd = r:script("uninstallcmd_before")
                if before_uninstallcmd then
                    before_uninstallcmd(target, batchcmds_, opt)
                end
            end
        end,
        target:script("uninstallcmd", _on_target_uninstallcmd),
        function (target)
            for _, r in ipairs(target:orderules()) do
                local after_uninstallcmd = r:script("uninstallcmd_after")
                if after_uninstallcmd then
                    after_uninstallcmd(target, batchcmds_, opt)
                end
            end
        end,
        target:script("uninstallcmd_after")
    }
    for i = 1, 5 do
        local script = scripts[i]
        if script ~= nil then
            script(target, batchcmds_, opt)
        end
    end
end

-- on build command
function _on_buildcmd(package, batchcmds_)
    if not package:from_source() then
        return
    end
    for _, target in ipairs(package:targets()) do
        _get_target_buildcmds(target, batchcmds_, {package = package})
    end
end

-- on install command
function _on_installcmd(package, batchcmds_)
    local srcfiles, dstfiles = package:installfiles()
    for idx, srcfile in ipairs(srcfiles) do
        batchcmds_:cp(srcfile, dstfiles[idx], {symlink = true})
    end
    for _, target in ipairs(package:targets()) do
        _get_target_installcmds(target, batchcmds_, {package = package})
    end
end

-- on uninstall command
function _on_uninstallcmd(package, batchcmds_)
    local _, dstfiles = package:installfiles()
    for _, dstfile in ipairs(dstfiles) do
        batchcmds_:rm(dstfile, {emptydirs = true})
    end
    for _, target in ipairs(package:targets()) do
        _get_target_uninstallcmds(target, batchcmds_, {package = package})
    end
end

-- get build commands
function get_buildcmds(package)
    local batchcmds_ = batchcmds.new()

    -- call script to get build commands
    local scripts = {
        package:script("buildcmd_before"),
        package:script("buildcmd", _on_buildcmd),
        package:script("buildcmd_after")
    }
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(package, batchcmds_)
        end
    end
    return batchcmds_
end

-- get install commands
function get_installcmds(package)
    local batchcmds_ = batchcmds.new()

    -- call script to get install commands
    local scripts = {
        package:script("installcmd_before"),
        package:script("installcmd", _on_installcmd),
        package:script("installcmd_after")
    }
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(package, batchcmds_)
        end
    end
    return batchcmds_
end

-- get uninstall commands
function get_uninstallcmds(package)
    local batchcmds_ = batchcmds.new()

    -- call script to get uninstall commands
    local scripts = {
        package:script("uninstallcmd_before"),
        package:script("uninstallcmd", _on_uninstallcmd),
        package:script("uninstallcmd_after")
    }
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(package, batchcmds_)
        end
    end
    return batchcmds_
end

