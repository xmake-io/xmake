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
import("core.base.semver")
import("lib.detect.find_tool")
import("private.utils.batchcmds")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")

-- get the makensis
function _get_makensis()

    -- enter the environments of nsis
    local oldenvs = packagenv.enter("nsis")

    -- find makensis
    local packages = {}
    local makensis = find_tool("makensis", {check = "/CMDHELP"})
    if not makensis then
        table.join2(packages, install_packages("nsis"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need to force detect and flush detect cache after loading all environments
    if not makensis then
        makensis = find_tool("makensis", {check = "/CMDHELP", force = true})
    end
    assert(makensis, "makensis not found!")

    return makensis, oldenvs
end

-- copy files or directories and we can reserve the source directory structure
-- e.g. os.cp("src/**.h", "/tmp/", {rootdir = "src", symlink = true})

-- get command string
function _get_command_strings(package, cmd)
    local result = {}
    local opt = cmd.opt or {}
    local kind = cmd.kind
    if kind == "cp" then
        -- https://nsis.sourceforge.io/Reference/File
        local srcfiles = os.files(cmd.srcpath)
        for _, srcfile in ipairs(srcfiles) do
            -- the destination is directory? append the filename
            local dstfile = cmd.dstpath
            if path.islastsep(dstfile) then
                if opt.rootdir then
                    dstfile = path.join(dstfile, path.relative(srcfile, opt.rootdir))
                else
                    dstfile = path.join(dstfile, path.filename(srcfile))
                end
            end
            srcfile = path.normalize(srcfile)
            local dstname = path.filename(dstfile)
            local dstdir = path.normalize(path.directory(path.join("$INSTDIR", dstfile)))
            table.insert(result, string.format("SetOutPath \"%s\"", dstdir))
            table.insert(result, string.format("File /oname=%s \"%s\"", dstname, srcfile))
        end
    elseif kind == "rm" then
        local filepath = path.normalize(path.join("$INSTDIR", cmd.filepath))
        table.insert(result, string.format("Delete \"%s\"", filepath))
    elseif kind == "tryrm" then
        --[[
            IfFileExists "$InstDir\file" file_found file_not_found_or_end
            file_found:
              Delete "$InstDir\file"
              goto file_not_found_or_end
            file_not_found_or_end:
        --]]
        local filepath = path.normalize(path.join("$INSTDIR", cmd.filepath))
        local tag = hash.uuid(filepath):split("-", {plain = true})[1]:lower()
        table.insert(result, string.format("IfFileExists \"%s\" file_found_%s file_not_found_or_end_%s", filepath, tag, tag))
        table.insert(result, string.format("file_found_%s:", tag))
        table.insert(result, string.format("  Delete \"%s\"", filepath))
        table.insert(result, string.format("  goto file_not_found_or_end_%s", tag))
        table.insert(result, string.format("file_not_found_or_end_%s:", tag))
    elseif kind == "rmdir" then
        local dir = path.normalize(path.join("$INSTDIR", cmd.dir))
        table.insert(result, string.format("RMDir /r \"%s\"", dir))
    elseif kind == "mv" then
        local srcpath = path.normalize(path.join("$INSTDIR", cmd.srcpath))
        local dstpath = path.normalize(path.join("$INSTDIR", cmd.dstpath))
        table.insert(result, string.format("Rename \"%s\" \"%s\"", srcpath, dstpath))
    elseif kind == "cd" then
        local dir = path.normalize(path.join("$INSTDIR", cmd.dir))
        table.insert(result, string.format("SetOutPath \"%s\"", dir))
    elseif kind == "mkdir" then
        local dir = path.normalize(path.join("$INSTDIR", cmd.dir))
        table.insert(result, string.format("CreateDirectory \"%s\"", dir))
    end
    return result
end

-- get commands string
function _get_commands_string(package, cmds)
    local cmdstrs = {}
    for _, cmd in ipairs(cmds) do
        table.join2(cmdstrs, _get_command_strings(package, cmd))
    end
    return table.concat(cmdstrs, "\n  ")
end

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
        batchcmds_:rm(dstheader)
    end
end

-- uninstall shared libraries for package
function _uninstall_shared_for_package(target, pkg, batchcmds_, outputdir)
    for _, dllpath in ipairs(table.wrap(pkg:get("libfiles"))) do
        if dllpath:endswith(".dll") then
            local dllname = path.filename(dllpath)
            batchcmds_:rm(path.join(outputdir, dllname))
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
end

-- on install target command
function _on_target_installcmd(target, batchcmds_, opt)

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
    local srcfiles, dstfiles = target:installfiles(".")
    for idx, srcfile in ipairs(srcfiles) do
        batchcmds_:cp(srcfile, dstfiles[idx])
    end
end

-- on uninstall binary target command
function _on_target_uninstallcmd_binary(target, batchcmds_, opt)
    local package = opt.package
    local bindir = package:bindir()

    -- uninstall target file
    batchcmds_:rm(path.join(bindir, target:filename()))
    batchcmds_:tryrm(path.join(bindir, path.filename(target:symbolfile())))

    -- remove the dependent shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/961
    for _, dep in ipairs(target:orderdeps()) do
        if dep:is_shared() then
            batchcmds_:rm(path.join(bindir, path.filename(dep:targetfile())))
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
    batchcmds_:rm(path.join(bindir, target:filename()))
    batchcmds_:tryrm(path.join(bindir, path.filename(target:symbolfile())))

    -- remove *.lib for shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/714
    local targetfile = target:targetfile()
    batchcmds_:rm(path.join(libdir, path.basename(targetfile) .. (target:is_plat("mingw") and ".dll.a" or ".lib")))

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
    batchcmds_:rm(path.join(libdir, target:filename()))
    batchcmds_:tryrm(path.join(libdir, path.filename(target:symbolfile())))

    -- remove headers from the include directory
    _uninstall_headers(target, batchcmds_, includedir)
end

-- on uninstall headeronly target command
function _on_target_uninstallcmd_headeronly(target, batchcmds_, opt)
    local package = opt.package
    local includedir = package:includedir()
    _uninstall_headers(target, batchcmds_, includedir)
end

-- on uninstall target command
function _on_target_uninstallcmd(target, batchcmds_, opt)

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
    local _, dstfiles = target:installfiles(".")
    for _, dstfile in ipairs(dstfiles) do
        batchcmds_:rm(dstfile)
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

-- on install command
function _on_installcmd(package, batchcmds_)
    local srcfiles, dstfiles = package:installfiles(".")
    for idx, srcfile in ipairs(srcfiles) do
        batchcmds_:cp(srcfile, dstfiles[idx])
    end
    for _, target in ipairs(package:targets()) do
        _get_target_installcmds(target, batchcmds_, {package = package})
    end
end

-- on uninstall command
function _on_uninstallcmd(package, batchcmds_)
    local _, dstfiles = package:installfiles(".")
    for _, dstfile in ipairs(dstfiles) do
        batchcmds_:rm(dstfile)
    end
    for _, target in ipairs(package:targets()) do
        _get_target_uninstallcmds(target, batchcmds_, {package = package})
    end
end

-- get install commands
function _get_installcmds(package)
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

    -- generate command string
    return _get_commands_string(package, batchcmds_:cmds())
end

-- get uninstall commands
function _get_uninstallcmds(package)
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

    -- generate command string
    return _get_commands_string(package, batchcmds_:cmds())
end

-- get specvars
function _get_specvars(package)
    local specvars = table.clone(package:specvars())
    specvars.PACKAGE_WORKDIR = path.absolute(os.projectdir()):gsub("\\", "/")
    specvars.PACKAGE_OUTPUTFILE = path.absolute(package:outputfile()):gsub("\\", "/")
    specvars.PACKAGE_INSTALLCMDS = function ()
        return _get_installcmds(package)
    end
    specvars.PACKAGE_UNINSTALLCMDS = function ()
        return _get_uninstallcmds(package)
    end
    return specvars
end

-- pack nsis package
function _pack_nsis(makensis, package, opt)

    -- install the initial specfile
    local specfile = package:specfile()
    if not os.isfile(specfile) then
        local specfile_template = path.join(os.programdir(), "scripts", "xpack", "nsis", "makensis.nsi")
        os.cp(specfile_template, specfile)
    end

    -- replace variables in specfile
    local specvars = _get_specvars(package)
    local pattern = package:extraconf("specfile", "pattern") or "%${([^\n]-)}"
    io.gsub(specfile, "(" .. pattern .. ")", function(_, name)
        name = name:trim()
        local value = specvars[name]
        if type(value) == "function" then
            value = value()
        end
        if value ~= nil then
            dprint("  > replace %s -> %s", name, value)
        end
        if type(value) == "table" then
            dprint("invalid variable value", value)
        end
        return value
    end)

    -- make package
    os.vrunv(makensis, {specfile})
end

function main(package)

    -- get makensis
    local makensis, oldenvs = _get_makensis()

    -- clean the build directory first
    os.tryrm(package:buildir())

    -- pack nsis package
    os.mkdir(package:outputdir())
    _pack_nsis(makensis.program, package, opt)

    -- done
    os.setenvs(oldenvs)
end
