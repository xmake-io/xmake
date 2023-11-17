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

-- get unique tag
function _get_unique_tag(content)
    return hash.uuid(content):split("-", {plain = true})[1]:lower()
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
            local dstdir = path.normalize(path.directory(path.join("$InstDir", dstfile)))
            table.insert(result, string.format("SetOutPath \"%s\"", dstdir))
            table.insert(result, string.format("File /oname=%s \"%s\"", dstname, srcfile))
        end
    elseif kind == "rm" then
        local filepath = path.normalize(path.join("$InstDir", cmd.filepath))
        table.insert(result, string.format("${%s} \"%s\"", opt.install and "RMFileIfExists" or "unRMFileIfExists", filepath))
        if opt.emptydirs then
            table.insert(result, string.format("${%s} \"%s\"", opt.install and "RMEmptyParentDirs" or "unRMEmptyParentDirs", filepath))
        end
    elseif kind == "rmdir" then
        local dir = path.normalize(path.join("$InstDir", cmd.dir))
        table.insert(result, string.format("${%s} \"%s\"", opt.install and "RMDirIfExists" or "unRMDirIfExists", dir))
        if opt.emptydirs then
            table.insert(result, string.format("${%s} \"%s\"", opt.install and "RMEmptyParentDirs" or "unRMEmptyParentDirs", dir))
        end
    elseif kind == "mv" then
        local srcpath = path.normalize(path.join("$InstDir", cmd.srcpath))
        local dstpath = path.normalize(path.join("$InstDir", cmd.dstpath))
        table.insert(result, string.format("Rename \"%s\" \"%s\"", srcpath, dstpath))
    elseif kind == "cd" then
        local dir = path.normalize(path.join("$InstDir", cmd.dir))
        table.insert(result, string.format("SetOutPath \"%s\"", dir))
    elseif kind == "mkdir" then
        local dir = path.normalize(path.join("$InstDir", cmd.dir))
        table.insert(result, string.format("CreateDirectory \"%s\"", dir))
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

-- get install commands
function _get_installcmds(package)
    return _get_commands_string(package, batchcmds.get_installcmds(package), {install = true})
end

-- get uninstall commands
function _get_uninstallcmds(package)
    return _get_commands_string(package, batchcmds.get_uninstallcmds(package), {install = false})
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
        return path.normalize(path.join(package:bindir(), path.filename(targetfile)))
    end
end

-- get specvars
function _get_specvars(package)
    local specvars = table.clone(package:specvars())
    specvars.PACKAGE_WORKDIR = path.absolute(os.projectdir())
    specvars.PACKAGE_BINDIR = package:bindir()
    specvars.PACKAGE_OUTPUTFILE = path.absolute(package:outputfile())
    specvars.PACKAGE_INSTALLCMDS = function ()
        return _get_installcmds(package)
    end
    specvars.PACKAGE_UNINSTALLCMDS = function ()
        return _get_uninstallcmds(package)
    end
    specvars.PACKAGE_NSIS_DISPLAY_NAME = _get_filter_value(package, "nsis_displayname") or package:name()
    specvars.PACKAGE_NSIS_DISPLAY_ICON = _get_filter_value(package, "nsis_displayicon") or _get_target_filepath(package) or ""
    specvars.PACKAGE_NSIS_INSTALL_SECTIONS = function ()
        local result = {}
        local cmds = package:get("nsis_installcmds")
        for name, cmd in pairs(cmds) do
            local tag = "Install" .. _get_unique_tag(name)
            table.insert(result, string.format('Section "%s" %s', name, tag))
            table.insert(result, cmd)
            table.insert(result, "SectionEnd")
        end
        return table.concat(result, "\n  ")
    end
    specvars.PACKAGE_NSIS_INSTALL_DESCS = function ()
        local result = {}
        local cmds = package:get("nsis_installcmds")
        for name, cmd in pairs(cmds) do
            local tag = "Install" .. _get_unique_tag(name)
            local description = package:extraconf("nsis_installcmds." .. name, cmd, "description") or name
            table.insert(result, string.format('LangString DESC_%s ${LANG_ENGLISH} "%s"', tag, description))
        end
        return table.concat(result, "\n  ")
    end
    specvars.PACKAGE_NSIS_INSTALL_DESCRIPTION_TEXTS = function ()
        local result = {}
        local cmds = package:get("nsis_installcmds")
        for name, _ in pairs(cmds) do
            local tag = "Install" .. _get_unique_tag(name)
            table.insert(result, string.format('!insertmacro MUI_DESCRIPTION_TEXT ${%s} $(DESC_%s)', tag, tag))
        end
        return table.concat(result, "\n  ")
    end
    return specvars
end

-- pack nsis package
function _pack_nsis(makensis, package)

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
