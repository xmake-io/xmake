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
-- @author      A2va
-- @file        main.lua
--

import("lib.detect.find_tool")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")

import(".batchcmds")

-- get the wixtoolset
function _get_wix()

    -- enter the environments of wix
    local oldenvs = packagenv.enter("wixtoolset")

    -- find makensis
    local packages = {}
    local wix = find_tool("wix", {require_version = ">=4.0.0"})
    if not wix then
        table.join2(packages, install_packages("wixtoolset"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need to force detect and flush detect cache after loading all environments
    if not wix then
        wix = find_tool("wix", {force = true})
    end
    assert(wix, "wix not found (ensure that wix is up to date)!")
    return wix, oldenvs
end

-- translate the file path
function _translate_filepath(package, filepath)
    return path.relative(filepath, package:install_rootdir())
end

function _get_cp_command(package, cmd, opt)
    opt = table.join(cmd.opt or {}, opt)
    local result = {}
    local kind = cmd.kind

    if kind == "cp" then
        local srcfiles = os.files(cmd.srcpath)
        for _, srcfile in ipairs(srcfiles) do
            -- the destination is directory? append the filename
            local dstfile = cmd.dstpath
            if #srcfiles > 1 or path.islastsep(dstfile) then
                if opt.rootdir then
                    dstfile = path.join(dstfile, path.relative(srcfile, opt.rootdir))
                else
                    dstfile = path.join(dstfile, path.filename(srcfile))
                end
            end
            srcfile = path.normalize(srcfile)
            local dstname = path.filename(dstfile)
            local dstdir = path.normalize(path.directory(dstfile))
            local relative_dstdir = _translate_filepath(package, dstdir)

            local subdirectory = dstdir ~= package:install_rootdir() and string.format([[Subdirectory="%s"]], relative_dstdir) or ""
            local component_string = string.format([[<Component Id="%s" Directory="INSTALLFOLDER" %s>"]], dstname, subdirectory)
            local file_string = string.format([[<File Source="%s" Name="%s" KeyPath="yes"/>]], srcfile, dstname)

            table.insert(result, component_string)
            table.insert(result, file_string)
            table.insert(result, "</Component>")
        end
    end
    return result
end

function _get_other_commands(package, cmd, opt)
    opt = table.join(cmd.opt or {}, opt)
    local result = {}
    local kind = cmd.kind

    if kind == "rm" then
        local filepath = _translate_filepath(package, cmd.filepath)
        local subdirectory = cmd.filepath ~= package:install_rootdir() and string.format([[Subdirectory="%s"]], filepath) or ""
        local on = opt.install and [[On="install"]] or [[On="uninstall"]]
        
        local remove_file = string.format([[<RemoveFile Directory="INSTALLFOLDER" %s %s/>]], subdirectory, on)
        table.insert(result, remove_file)
    elseif kind == "rmdir" then
        local dir = _translate_filepath(package, cmd.dir)
        local subdirectory = cmd.dir ~= package:install_rootdir() and string.format([[Subdirectory="%s"]], dir) or ""
        local on = opt.install and [[On="install"]] or [[On="uninstall"]]
        
        local remove_dir = string.format([[<RemoveFile Directory="INSTALLFOLDER" %s %s/>]], subdirectory, on)
        table.insert(result, remove_dir)
    elseif kind == "mkdir" then
        local dir = _translate_filepath(package, cmd.dir)
        local subdirectory = cmd.dir ~= package:install_rootdir() and string.format([[Subdirectory="%s"]], dir) or ""
        local make_dir = string.format([[<CreateFolder Directory="INSTALLFOLDER" %s/>]], subdirectory)
        table.insert(result, make_dir)
    else
        wprint("kind %s is not supported with wix", kind)
    end
    return result
end

-- get commands string
function _get_commands_string(package, cmds, opt, func)
    local cmdstrs = {}
    for _, cmd in ipairs(cmds) do
        table.join2(cmdstrs, func(package, cmd, opt))
    end
    return table.concat(cmdstrs, "\n  ")
end

-- get install commands
function _get_installcmds(package)
    return _get_commands_string(package, batchcmds.get_installcmds(package):cmds(), {install = true})
end

-- get uninstall commands
function _get_uninstallcmds(package)
    return _get_commands_string(package, batchcmds.get_uninstallcmds(package):cmds(), {install = false})
end

-- get install commands of component
function _get_component_installcmds(component)
    return _get_commands_string(component, batchcmds.get_installcmds(component):cmds(), {install = true})
end

-- get uninstall commands of component
function _get_component_uninstallcmds(component)
    return _get_commands_string(component, batchcmds.get_uninstallcmds(component):cmds(), {install = false})
end

-- get specvars
function _get_specvars(package)

    local specvars = table.clone(package:specvars())
    -- install
    local installcmds = batchcmds.get_installcmds(package):cmds()
    specvars.PACKAGE_INSTALLCMDS = function ()
        return _get_commands_string(package, installcmds, {install = true}, _get_cp_command)
    end
    specvars.PACKAGE_WIX_FILE_OPERATION_INSTALL = function ()
        return _get_commands_string(package, installcmds, {install = true}, _get_other_commands)
    end

    -- uninstall
    local uninstallcmds = batchcmds.get_uninstallcmds(package):cmds()
    specvars.PACKAGE_WIX_FILE_OPERATION_UNINSTALL = function ()
        return _get_commands_string(package, uninstallcmds, {install = false}, _get_other_commands)
    end

    specvars.PACKAGE_WIX_UPGRADECODE = hash.uuid(package:name())

    -- company cannot be empty with wix
    if package:get("company") == nil or package:get("company") == "" then
        specvars.PACKAGE_COMPANY = package:name()
    end
    return specvars
end

function _pack_wix(wix, package)

    -- install the initial specfile
    local specfile = package:specfile()
    if not os.isfile(specfile) then
        local specfile_template = path.join(os.programdir(), "scripts", "xpack", "wix", "msi.wxs")
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
    -- os.vrunv(wix, {specfile})
end

function main(package)
    -- only for windows
    if not is_host("windows") then
        return
    end

    cprint("packing %s", package:outputfile())

    -- get wix
    local wix, oldenvs = _get_wix()

    -- pack nsis package
    _pack_wix(wix.program, package)

    -- done
    os.setenvs(oldenvs)
end