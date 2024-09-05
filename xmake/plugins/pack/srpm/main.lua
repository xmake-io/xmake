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
import("core.base.hashset")
import("lib.detect.find_tool")
import("lib.detect.find_file")
import("utils.archive")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")
import(".batchcmds")

-- get the rpmbuild
function _get_rpmbuild()

    -- enter the environments of rpmbuild
    local oldenvs = packagenv.enter("rpm")

    -- find rpmbuild
    local packages = {}
    local rpmbuild = find_tool("rpmbuild")
    if not rpmbuild then
        table.join2(packages, install_packages("rpm"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need to force detect and flush detect cache after loading all environments
    if not rpmbuild then
        rpmbuild = find_tool("rpmbuild", {force = true})
    end
    assert(rpmbuild, "rpmbuild not found!")
    return rpmbuild, oldenvs
end

-- get archive file
function _get_archivefile(package)
    return path.absolute(path.join(package:buildir(), package:basename() .. ".tar.gz"))
end

-- translate the file path
function _translate_filepath(package, filepath)
    return filepath:replace(package:install_rootdir(), "%{buildroot}/%{_exec_prefix}", {plain = true})
end

-- get install command
function _get_customcmd(package, installcmds, cmd)
    local opt = cmd.opt or {}
    local kind = cmd.kind
    if kind == "cp" then
        local srcfiles = os.files(cmd.srcpath)
        for _, srcfile in ipairs(srcfiles) do
            -- the destination is directory? append the filename
            local dstfile = _translate_filepath(package, cmd.dstpath)
            if #srcfiles > 1 or path.islastsep(dstfile) then
                if opt.rootdir then
                    dstfile = path.join(dstfile, path.relative(srcfile, opt.rootdir))
                else
                    dstfile = path.join(dstfile, path.filename(srcfile))
                end
            end
            table.insert(installcmds, string.format("install -Dpm0644 \"%s\" \"%s\"", srcfile, dstfile))
        end
    elseif kind == "rm" then
        local filepath = _translate_filepath(package, cmd.filepath)
        table.insert(installcmds, string.format("rm -f \"%s\"", filepath))
    elseif kind == "rmdir" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(installcmds, string.format("rm -rf \"%s\"", dir))
    elseif kind == "mv" then
        local srcpath = _translate_filepath(package, cmd.srcpath)
        local dstpath = _translate_filepath(package, cmd.dstpath)
        table.insert(installcmds, string.format("mv \"%s\" \"%s\"", srcfile, dstfile))
    elseif kind == "cd" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(installcmds, string.format("cd \"%s\"", dir))
    elseif kind == "mkdir" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(installcmds, string.format("mkdir -p \"%s\"", dir))
    elseif cmd.program then
        local argv = {}
        for _, arg in ipairs(cmd.argv) do
            if path.instance_of(arg) then
                arg = arg:clone():set(_translate_filepath(package, arg:rawstr())):str()
            elseif path.is_absolute(arg) then
                arg = _translate_filepath(package, arg)
            end
            table.insert(argv, arg)
        end
        table.insert(installcmds, string.format("%s", os.args(table.join(cmd.program, argv))))
    end
end

-- get build commands
function _get_buildcmds(package, buildcmds, cmds)
    for _, cmd in ipairs(cmds) do
        _get_customcmd(package, buildcmds, cmd)
    end
end

-- get install commands
function _get_installcmds(package, installcmds, cmds)
    for _, cmd in ipairs(cmds) do
        _get_customcmd(package, installcmds, cmd)
    end
end

-- get specvars
function _get_specvars(package)
    local specvars = table.clone(package:specvars())
    specvars.PACKAGE_ARCHIVEFILE = path.filename(_get_archivefile(package))
    local datestr = os.iorunv("date", {"+%a %b %d %Y"}, {envs = {LC_TIME = "en_US"}})
    if datestr then
        datestr = datestr:trim()
    end
    specvars.PACKAGE_PREFIXDIR = package:prefixdir() or ""
    specvars.PACKAGE_DATE = datestr or ""
    specvars.PACKAGE_INSTALLCMDS = function ()
        local prefixdir = package:get("prefixdir")
        package:set("prefixdir", nil)
        local installcmds = {}
        _get_installcmds(package, installcmds, batchcmds.get_installcmds(package):cmds())
        for _, component in table.orderpairs(package:components()) do
            if component:get("default") ~= false then
                _get_installcmds(package, installcmds, batchcmds.get_installcmds(component):cmds())
            end
        end
        package:set("prefixdir", prefixdir)
        return table.concat(installcmds, "\n")
    end
    specvars.PACKAGE_BUILDCMDS = function ()
        local buildcmds = {}
        _get_buildcmds(package, buildcmds, batchcmds.get_buildcmds(package):cmds())
        return table.concat(buildcmds, "\n")
    end
    specvars.PACKAGE_BUILDREQUIRES = function ()
        local requires = {}
        local buildrequires = package:get("buildrequires")
        if buildrequires then
            for _, buildrequire in ipairs(buildrequires) do
                table.insert(requires, "BuildRequires: " .. buildrequire)
            end
        else
            local programs = hashset.new()
            for _, cmd in ipairs(batchcmds.get_buildcmds(package):cmds()) do
                local program = cmd.program
                if program then
                    programs:insert(program)
                end
            end
            local map = {
                xmake = "xmake",
                cmake = "cmake",
                make = "make"
            }
            for _, program in programs:keys() do
                local requirename = map[program]
                if requirename then
                    table.insert(requires, "BuildRequires: " .. requirename)
                end
            end
            if #requires > 0 then
                table.insert(requires, "BuildRequires: gcc")
                table.insert(requires, "BuildRequires: gcc-c++")
            end
        end
        return table.concat(requires, "\n")
    end
    return specvars
end

-- pack srpm package
function _pack_srpm(rpmbuild, package)

    -- ensure prefixdir
    local prefixdir = package:get("prefixdir")
    if not prefixdir then
        prefixdir = package:name() .. "-" .. package:version()
        package:set("prefixdir", prefixdir)
    end

    -- install the initial specfile
    local specfile = path.join(package:buildir(), package:basename() .. ".spec")
    if not os.isfile(specfile) then
        local specfile_template = package:get("specfile") or path.join(os.programdir(), "scripts", "xpack", "srpm", "srpm.spec")
        os.cp(specfile_template, specfile, {writeable = true})
    end

    -- replace variables in specfile
    -- and we need to avoid `attempt to yield across a C-call boundary` in io.gsub
    local specvars = _get_specvars(package)
    local pattern = package:extraconf("specfile", "pattern") or "%${([^\n]-)}"
    local specvars_names = {}
    local specvars_values = {}
    io.gsub(specfile, "(" .. pattern .. ")", function(_, name)
        table.insert(specvars_names, name)
    end)
    for _, name in ipairs(specvars_names) do
        name = name:trim()
        if specvars_values[name] == nil then
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
            specvars_values[name] = value
        end
    end
    io.gsub(specfile, "(" .. pattern .. ")", function(_, name)
        name = name:trim()
        return specvars_values[name]
    end)

    -- archive source files
    local srcfiles, dstfiles = package:sourcefiles()
    for idx, srcfile in ipairs(srcfiles) do
        os.vcp(srcfile, dstfiles[idx])
    end
    for _, component in table.orderpairs(package:components()) do
        if component:get("default") ~= false then
            local srcfiles, dstfiles = component:sourcefiles()
            for idx, srcfile in ipairs(srcfiles) do
                os.vcp(srcfile, dstfiles[idx])
            end
        end
    end

    -- archive install files
    local rootdir = package:source_rootdir()
    local oldir = os.cd(rootdir)
    local archivefiles = os.files("**")
    os.cd(oldir)
    local archivefile = _get_archivefile(package)
    os.tryrm(archivefile)
    archive.archive(archivefile, archivefiles, {curdir = rootdir, compress = "best"})

    -- pack srpm package
    os.vrunv(rpmbuild, {"-bs", specfile,
        "--define", "_topdir " .. package:buildir(),
        "--define", "_sourcedir " .. package:buildir(),
        "--define", "_srcrpmdir " .. package:outputdir()})

    -- pack rpm package
    if package:format() == "rpm" then
        local srpmfile = find_file("*.src.rpm", package:outputdir())
        if srpmfile then
            os.vrunv(rpmbuild, {"--rebuild", srpmfile, "--define", "_rpmdir " .. package:outputdir()})
        end
    end
end

function main(package)

    if not is_host("linux") then
        return
    end

    cprint("packing %s", package:outputfile())

    -- get rpmbuild
    local rpmbuild, oldenvs = _get_rpmbuild()

    -- pack srpm package
    _pack_srpm(rpmbuild.program, package)

    -- done
    os.setenvs(oldenvs)
end
