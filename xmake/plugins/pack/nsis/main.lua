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
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")
import(".filter")
import(".batchcmds")

-- check makensis, we need check some plugins
function _check_makensis(program)
    local tmpdir = os.tmpfile() .. ".dir"
    io.writefile(path.join(tmpdir, "test.nsis"), [[
        !include "MUI2.nsh"
        !include "WordFunc.nsh"
        !include "WinMessages.nsh"
        !include "FileFunc.nsh"
        !include "UAC.nsh"

        Name "test"
        OutFile "test.exe"

        Function .onInit
        FunctionEnd

        Section "test" InstallExeutable
        SectionEnd

        Function un.onInit
        FunctionEnd

        Section "Uninstall"
        SectionEnd]])
    os.runv(program, {"test.nsis"}, {curdir = tmpdir})
    os.tryrm(tmpdir)
end

-- get the makensis
function _get_makensis()

    -- enter the environments of nsis
    local oldenvs = packagenv.enter("nsis")

    -- find makensis
    local packages = {}
    local makensis = find_tool("makensis", {check = _check_makensis})
    if not makensis then
        table.join2(packages, install_packages("nsis"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need to force detect and flush detect cache after loading all environments
    if not makensis then
        makensis = find_tool("makensis", {check = _check_makensis, force = true})
    end
    assert(makensis, "makensis not found!")
    return makensis, oldenvs
end

-- get unique tag
function _get_unique_tag(content)
    return hash.strhash32(content)
end

-- translate the file path
function _translate_filepath(package, filepath)
    return filepath:replace(package:install_rootdir(), "$InstDir", {plain = true})
end

-- get command string
function _get_command_strings(package, cmd, opt)
    opt = table.join(cmd.opt or {}, opt)
    local result = {}
    local kind = cmd.kind
    if kind == "cp" then
        -- https://nsis.sourceforge.io/Reference/File
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
            srcfile = path.normalize(srcfile)
            local dstname = path.filename(dstfile)
            local dstdir = path.normalize(path.directory(dstfile))
            table.insert(result, string.format("SetOutPath \"%s\"", dstdir))
            table.insert(result, string.format("File \"/oname=%s\" \"%s\"", dstname, srcfile))
        end
    elseif kind == "rm" then
        local filepath = _translate_filepath(package, cmd.filepath)
        table.insert(result, string.format("${%s} \"%s\"", opt.install and "RMFileIfExists" or "unRMFileIfExists", filepath))
        if opt.emptydirs then
            table.insert(result, string.format("${%s} \"%s\"", opt.install and "RMEmptyParentDirs" or "unRMEmptyParentDirs", filepath))
        end
    elseif kind == "rmdir" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(result, string.format("${%s} \"%s\"", opt.install and "RMDirIfExists" or "unRMDirIfExists", dir))
        if opt.emptydirs then
            table.insert(result, string.format("${%s} \"%s\"", opt.install and "RMEmptyParentDirs" or "unRMEmptyParentDirs", dir))
        end
    elseif kind == "mv" then
        local srcpath = _translate_filepath(package, cmd.srcpath)
        local dstpath = _translate_filepath(package, cmd.dstpath)
        table.insert(result, string.format("Rename \"%s\" \"%s\"", srcpath, dstpath))
    elseif kind == "cd" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(result, string.format("SetOutPath \"%s\"", dir))
    elseif kind == "mkdir" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(result, string.format("CreateDirectory \"%s\"", dir))
    elseif kind == "nsis" then
        table.insert(result, cmd.rawstr)
    end
    return result
end

-- get commands string
function _get_commands_string(package, cmds, opt)
    local cmdstrs = {}
    for _, cmd in ipairs(cmds) do
        table.join2(cmdstrs, _get_command_strings(package, cmd, opt))
    end
    return table.concat(cmdstrs, "\n  ")
end

-- get install commands of component
function _get_component_installcmds(component)
    return _get_commands_string(component, batchcmds.get_installcmds(component):cmds(), {install = true})
end

-- get uninstall commands of component
function _get_component_uninstallcmds(component)
    return _get_commands_string(component, batchcmds.get_uninstallcmds(component):cmds(), {install = false})
end

-- get install commands
function _get_installcmds(package)
    return _get_commands_string(package, batchcmds.get_installcmds(package):cmds(), {install = true})
end

-- get uninstall commands
function _get_uninstallcmds(package)
    return _get_commands_string(package, batchcmds.get_uninstallcmds(package):cmds(), {install = false})
end

-- get value and filter it
function _get_filter_value(package, name)
    local value = package:get(name)
    if type(value) == "string" then
        value = filter.handle(value, package)
    end
    return value
end

-- get target file path
function _get_target_filepath(package)
    local targetfile
    for _, target in ipairs(package:targets()) do
        if target:is_binary() then
            targetfile = target:targetfile()
            break
        end
    end
    if targetfile then
        return _translate_filepath(package, path.join(package:bindir(), path.filename(targetfile)))
    end
end

-- get specvars
function _get_specvars(package)
    local specvars = table.clone(package:specvars())
    specvars.PACKAGE_WORKDIR = path.absolute(os.projectdir())
    specvars.PACKAGE_BINDIR = _translate_filepath(package, package:bindir())
    specvars.PACKAGE_OUTPUTFILE = path.absolute(package:outputfile())
    if specvars.PACKAGE_VERSION_BUILD then
        -- @see https://github.com/xmake-io/xmake/issues/5306
        specvars.PACKAGE_VERSION_BUILD = specvars.PACKAGE_VERSION_BUILD:gsub(" ", "_")
    end
    specvars.PACKAGE_INSTALLCMDS = function ()
        return _get_installcmds(package)
    end
    specvars.PACKAGE_UNINSTALLCMDS = function ()
        return _get_uninstallcmds(package)
    end
    specvars.PACKAGE_NSIS_DISPLAY_ICON = function ()
        local iconpath = _get_filter_value(package, "nsis_displayicon")
        if iconpath then
            iconpath = path.join(package:installdir(), iconpath)
        end
        if not iconpath then
            iconpath = _get_target_filepath(package) or ""
        end
        return _translate_filepath(package, iconpath)
    end

    -- install sections
    local install_sections = {}
    local install_descs = {}
    local install_description_texts = {}
    for name, component in table.orderpairs(package:components()) do
        local installcmds = _get_component_installcmds(component)
        if installcmds and #installcmds > 0 then
            local tag = "Install" .. name
            table.insert(install_sections, string.format('Section%s "%s" %s', component:get("default") == false and " /o" or "", component:title(), tag))
            table.insert(install_sections, installcmds)
            table.insert(install_sections, "SectionEnd")
            table.insert(install_descs, string.format('LangString DESC_%s ${LANG_ENGLISH} "%s"', tag, component:description() or ""))
            table.insert(install_description_texts, string.format('!insertmacro MUI_DESCRIPTION_TEXT ${%s} $(DESC_%s)', tag, tag))
        end
        local uninstallcmds = _get_component_uninstallcmds(component)
        if uninstallcmds and #uninstallcmds > 0 then
            local tag = "Uninstall" .. name
            table.insert(install_sections, string.format('Section "un.%s" %s', component:title(), tag))
            table.insert(install_sections, uninstallcmds)
            table.insert(install_sections, "SectionEnd")
        end
    end
    specvars.PACKAGE_NSIS_INSTALL_SECTIONS = table.concat(install_sections, "\n  ")
    specvars.PACKAGE_NSIS_INSTALL_DESCS = table.concat(install_descs, "\n  ")
    specvars.PACKAGE_NSIS_INSTALL_DESCRIPTION_TEXTS = table.concat(install_description_texts, "\n  ")
    return specvars
end

-- pack nsis package
function _pack_nsis(makensis, package)

    -- install the initial specfile
    local specfile = path.join(package:buildir(), package:basename() .. ".nsi")
    if not os.isfile(specfile) then
        local specfile_template = package:get("specfile") or path.join(os.programdir(), "scripts", "xpack", "nsis", "makensis.nsi")
        os.cp(specfile_template, specfile)
    end

    -- replace variables in specfile,
    -- and we need to avoid `attempt to yield across a C-call boundary` in io.gsub
    local specvars = _get_specvars(package)
    local pattern = package:extraconf("specfile", "pattern") or "%${([^\n]-)}"
    local specvars_names = {}
    local specvars_values = {}
    io.gsub(specfile, "(" .. pattern .. ")", function(_, name)
        table.insert(specvars_names, name)
    end, {encoding = "ansi"})
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
    end, {encoding = "ansi"})

    -- make package
    os.vrunv(makensis, {specfile})
end

function main(package)

    -- only for windows
    if not is_host("windows") then
        return
    end

    cprint("packing %s", package:outputfile())

    -- get makensis
    local makensis, oldenvs = _get_makensis()

    -- pack nsis package
    _pack_nsis(makensis.program, package)

    -- done
    os.setenvs(oldenvs)
end
