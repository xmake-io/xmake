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
import("utils.archive")
import("private.utils.batchcmds")

-- install headers
function _install_headers(target, batchcmds_, includedir)
    local srcheaders, dstheaders = target:headerfiles(includedir, {installonly = true})
    if srcheaders and dstheaders then
        local i = 1
        for _, srcheader in ipairs(srcheaders) do
            local dstheader = dstheaders[i]
            if dstheader then
                batchcmds_:cp(srcheader, dstheader)
            end
            i = i + 1
        end
    end
end

-- install shared libraries for package
function _install_shared_for_package(target, pkg, batchcmds_, outputdir)
    _g.installed_dllfiles = _g.installed_dllfiles or {}
    for _, dllpath in ipairs(table.wrap(pkg:get("libfiles"))) do
        if dllpath:endswith(".dll") then
            -- prevent packages using the same libfiles from overwriting each other
            if not _g.installed_dllfiles[dllpath] then
                local dllname = path.filename(dllpath)
                batchcmds_:cp(dllpath, path.join(outputdir, dllname))
                _g.installed_dllfiles[dllpath] = true
            end
        end
    end
end

-- install shared libraries for packages
function _install_shared_for_packages(target, batchcmds_, outputdir)
    _g.installed_packages = _g.installed_packages or {}
    for _, pkg in ipairs(target:orderpkgs()) do
        if not _g.installed_packages[pkg:name()] then
            if pkg:enabled() and pkg:get("libfiles") then
                _install_shared_for_package(target, pkg, batchcmds_, outputdir)
            end
            _g.installed_packages[pkg:name()] = true
        end
    end
end

-- uninstall headers
function _uninstall_headers(target, batchcmds_, includedir)
    local _, dstheaders = target:headerfiles(includedir, {installonly = true})
    for _, dstheader in ipairs(dstheaders) do
        batchcmds_:rm(dstheader, {emptydirs = true})
    end
end

-- uninstall shared libraries for package
function _uninstall_shared_for_package(target, pkg, batchcmds_, outputdir)
    for _, dllpath in ipairs(table.wrap(pkg:get("libfiles"))) do
        if dllpath:endswith(".dll") then
            local dllname = path.filename(dllpath)
            batchcmds_:rm(path.join(outputdir, dllname), {emptydirs = true})
        end
    end
end

-- uninstall shared libraries for packages
function _uninstall_shared_for_packages(target, batchcmds_, outputdir)
    _g.uninstalled_packages = _g.uninstalled_packages or {}
    for _, pkg in ipairs(target:orderpkgs()) do
        if not _g.uninstalled_packages[pkg:name()] then
            if pkg:enabled() and pkg:get("libfiles") then
                _uninstall_shared_for_package(target, pkg, batchcmds_, outputdir)
            end
            _g.uninstalled_packages[pkg:name()] = true
        end
    end
end

-- on install binary target command
function _on_target_installcmd_binary(target, batchcmds_, opt)
    local package = opt.package
    local bindir = package:bindir()

    -- install target file
    batchcmds_:cp(target:targetfile(), path.join(bindir, target:filename()))
    if os.isfile(target:symbolfile()) then
        batchcmds_:cp(target:symbolfile(), path.join(bindir, path.filename(target:symbolfile())))
    end

    -- install the dependent shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/961
    _g.installed_dllfiles = _g.installed_dllfiles or {}
    for _, dep in ipairs(target:orderdeps()) do
        if dep:kind() == "shared" then
            local depfile = dep:targetfile()
            if os.isfile(depfile) then
                if not _g.installed_dllfiles[depfile] then
                    batchcmds_:cp(depfile, path.join(bindir, path.filename(depfile)))
                    _g.installed_dllfiles[depfile] = true
                end
            end
        end
        -- install all shared libraries in packages in all deps
        _install_shared_for_packages(dep, batchcmds_, bindir)
    end

    -- install shared libraries for all packages
    _install_shared_for_packages(target, batchcmds_, bindir)
end

-- on install shared target command
function _on_target_installcmd_shared(target, batchcmds_, opt)
    local package = opt.package
    local bindir = package:bindir()
    local libdir = package:libdir()
    local includedir = package:includedir()

    -- install target file
    batchcmds_:cp(target:targetfile(), path.join(bindir, target:filename()))
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

    -- install shared libraries for all packages
    _install_shared_for_packages(target, batchcmds_, bindir)

    -- install headers
    _install_headers(target, batchcmds_, includedir)
end

-- on install static target command
function _on_target_installcmd_static(target, batchcmds_, opt)
    local package = opt.package
    local libdir = package:libdir()
    local includedir = package:includedir()

    -- install target file
    batchcmds_:cp(target:targetfile(), path.join(libdir, target:filename()))
    if os.isfile(target:symbolfile()) then
        batchcmds_:cp(target:symbolfile(), path.join(libdir, path.filename(target:symbolfile())))
    end

    -- install headers
    _install_headers(target, batchcmds_, includedir)
end

-- on install headeronly target command
function _on_target_installcmd_headeronly(target, batchcmds_, opt)
    local package = opt.package
    local includedir = package:includedir()

    -- install headers
    _install_headers(target, batchcmds_, includedir)
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
    local srcfiles, dstfiles = target:installfiles(package:installdir())
    for idx, srcfile in ipairs(srcfiles) do
        batchcmds_:cp(srcfile, dstfiles[idx])
    end
end

-- on uninstall binary target command
function _on_target_uninstallcmd_binary(target, batchcmds_, opt)
    local package = opt.package
    local bindir = package:bindir()

    -- uninstall target file
    batchcmds_:rm(path.join(bindir, target:filename()), {emptydirs = true})
    batchcmds_:rm(path.join(bindir, path.filename(target:symbolfile())), {emptydirs = true})

    -- remove the dependent shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/961
    for _, dep in ipairs(target:orderdeps()) do
        if dep:is_shared() then
            batchcmds_:rm(path.join(bindir, path.filename(dep:targetfile())), {emptydirs = true})
        end
        _uninstall_shared_for_packages(dep, batchcmds_, bindir)
    end

    -- uninstall shared libraries for packages
    _uninstall_shared_for_packages(target, batchcmds_, bindir)
end

-- on uninstall shared target command
function _on_target_uninstallcmd_shared(target, batchcmds_, opt)
    local package = opt.package
    local bindir = package:bindir()
    local libdir = package:libdir()
    local includedir = package:includedir()

    -- uninstall target file
    batchcmds_:rm(path.join(bindir, target:filename()), {emptydirs = true})
    batchcmds_:rm(path.join(bindir, path.filename(target:symbolfile())), {emptydirs = true})

    -- remove *.lib for shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/714
    local targetfile = target:targetfile()
    batchcmds_:rm(path.join(libdir, path.basename(targetfile) .. (target:is_plat("mingw") and ".dll.a" or ".lib")), {emptydirs = true})

    -- remove headers from the include directory
    _uninstall_headers(target, batchcmds_, includedir)

    -- uninstall shared libraries for packages
    _uninstall_shared_for_packages(target, batchcmds_, bindir)
end

-- on uninstall static target command
function _on_target_uninstallcmd_static(target, batchcmds_, opt)
    local package = opt.package
    local libdir = package:libdir()
    local includedir = package:includedir()

    -- uninstall target file
    batchcmds_:rm(path.join(libdir, target:filename()), {emptydirs = true})
    batchcmds_:rm(path.join(libdir, path.filename(target:symbolfile())), {emptydirs = true})

    -- remove headers from the include directory
    _uninstall_headers(target, batchcmds_, includedir)
end

-- on uninstall headeronly target command
function _on_target_uninstallcmd_headeronly(target, batchcmds_, opt)
    local package = opt.package
    local includedir = package:includedir()
    _uninstall_headers(target, batchcmds_, includedir)
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
    local _, dstfiles = target:installfiles(package:installdir())
    for _, dstfile in ipairs(dstfiles) do
        batchcmds_:rm(dstfile, {emptydirs = true})
    end
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
        batchcmds_:cp(srcfile, dstfiles[idx])
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

