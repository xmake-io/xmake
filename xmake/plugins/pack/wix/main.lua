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
    local wix = find_tool("wix")
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

function _to_rtf_string(str)
    if str == "" then
        return str
    end

    local escape_text = str:gsub("\\", "\\\\")
    escape_text = escape_text:gsub("{", "\\{")
    escape_text = escape_text:gsub("}", "\\}")

    local rtf = "{\\rtf1\\ansi{\\fonttbl\\f0\\fswiss Helvetica;}\\f0\\pard ";
    rtf = rtf .. escape_text:gsub("\r\n", " \\par ") .. "}"
    return rtf
end

-- get a table where the key is a directory and the value a list of files
-- used to regroup all files that are placed in the same directory under the same component.
function _get_cp_kind_table(package, cmds, opt)

    local result = {}
    for _, cmd in ipairs(cmds) do
        if cmd.kind ~= "cp" then
            goto continue
        end

        local option = table.join(cmd.opt or {}, opt)
        local srcfiles = os.files(cmd.srcpath)
        for _, srcfile in ipairs(srcfiles) do
            -- the destination is directory? append the filename
            local dstfile = cmd.dstpath
            if #srcfiles > 1 or path.islastsep(dstfile) then
                if option.rootdir then
                    dstfile = path.join(dstfile, path.relative(srcfile, option.rootdir))
                else
                    dstfile = path.join(dstfile, path.filename(srcfile))
                end
            end
            srcfile = path.normalize(srcfile)
            local dstname = path.filename(dstfile)
            local dstdir = path.normalize(path.directory(dstfile))
            dstdir = _translate_filepath(package, dstdir)

            if result[dstdir] then
                table.insert(result[dstdir], {srcfile, dstname})
            else
                result[dstdir] = {{srcfile, dstname}}
            end
        end
        ::continue::
    end
    return result
end

-- get id
function _get_id(name)
    return "A" .. hash.uuid(name):gsub("-", ".")
end

-- for each id/guid in the file wix want them to be unique
-- so compute a hash for each directory based on the file that are inside
function _get_dir_id(cp_table)
    local hashes = {}
    for dir, files in pairs(cp_table) do
        local s = ""
        for _, file in ipairs(files) do
            s = s .. table.concat(file, "")
        end
        -- wix required id to start with a letter and without any hyphen
        hashes[dir] = _get_id(s)
    end
    return hashes
end

-- get custom commands
function _get_other_commands(package, cmd, opt)
    opt = table.join(cmd.opt or {}, opt)
    local result = ""
    local kind = cmd.kind
    local id = _get_id()
    if kind == "rm" then
        local subdirectory = _translate_filepath(package, path.directory(cmd.filepath))
        subdirectory = subdirectory ~= "." and string.format([[Subdirectory="%s"]], subdirectory) or ""
        local on = opt.install and [[On="install"]] or [[On="uninstall"]]
        local filename = path.filename(cmd.filepath)
        result = string.format([[<RemoveFile Id="%s" Directory="INSTALLFOLDER" Name="%s" %s %s/>]], id, filename, subdirectory, on)
    elseif kind == "rmdir" then
        local dir = _translate_filepath(package, cmd.dir)
        local subdirectory = dir ~= "." and string.format([[Subdirectory="%s"]], dir) or ""
        local on = opt.install and [[On="install"]] or [[On="uninstall"]]
        result = string.format([[<RemoveFolder Id="%s" Directory="INSTALLFOLDER" %s %s/>]], id, subdirectory, on)
    elseif kind == "mkdir" then
        local dir = _translate_filepath(package, cmd.dir)
        local subdirectory = dir ~= "." and string.format([[Subdirectory="%s"]], dir) or ""
        result = string.format([[<CreateFolder Id="%s" Directory="INSTALLFOLDER" %s/>]], id, subdirectory)
    elseif kind == "wix" then
        result = cmd.rawstr
    end
    return result
end

-- get the string of a wix feature
function _get_feature_string(name, title, opt)
    local level = opt.default and 1 or 2
    local description = opt.description or ""
    local allow_absent = opt.force and "false" or "true"
    local allow_advertise = opt.force and "false" or "true"
    local typical_default = [[TypicalDefault="install"]]
    local directory = opt.config_dir and [[ConfigurableDirectory="INSTALLFOLDER"]] or ""
    local feature = string.format([[<Feature Id="%s" Title="%s" Description="%s" Level="%d" AllowAdvertise="%s" AllowAbsent="%s" %s %s>]],
        name:gsub("[ ()]", ""), title, description, level, allow_advertise, allow_absent, typical_default, directory)
    return feature
end

function _get_component_string(id, subdirectory)
    local subdirectory = (subdirectory ~= "." and subdirectory ~= nil) and string.format([[Subdirectory="%s"]], subdirectory) or ""
    return string.format([[<Component Id="%s" Guid="%s" Directory="INSTALLFOLDER" %s>]], id:gsub("[ ()]", ""), hash.uuid(id), subdirectory)
end

-- build a feature from batchcmds
function _build_feature(package, opt)
    opt = opt or {}
    local default = opt.default or package:get("default")

    local result = {}
    local name = opt.name or package:title()
    table.insert(result, _get_feature_string(name, package:title(), table.join(opt, {default = default, description = package:description()})))

    local installcmds = batchcmds.get_installcmds(package):cmds()
    local uninstallcmds = batchcmds.get_uninstallcmds(package):cmds()

    local cp_table = _get_cp_kind_table(package, installcmds, opt)
    table.remove_if(installcmds, function (_, cmd) return cmd.kind == "cp" end)

    local dir_id = _get_dir_id(cp_table)
    for dir, files in pairs(cp_table) do
        table.insert(result, _get_component_string(dir_id[dir], dir))
        for _, file in ipairs(files) do
            local srcfile = file[1]
            local dstname = file[2]
            table.insert(result, string.format([[<File Source="%s" Name="%s" Id="%s"/>]], srcfile, dstname, _get_id()))
        end
        table.insert(result, "</Component>")
    end

    table.insert(result, _get_component_string(name .. "Cmds"))
    for _, cmd in ipairs(installcmds) do
        table.insert(result, _get_other_commands(package, cmd, {install = true}))
    end
    for _, cmd in ipairs(uninstallcmds) do
        table.insert(result, _get_other_commands(package, cmd, {install = false}))
    end

    table.insert(result, "</Component>")
    table.insert(result, "</Feature>")
    return result
end

-- add to path feature
function _add_to_path(package)
    local result = {}
    table.insert(result, _get_feature_string("PATH", "Add to PATH", {default = false, force = false, description = "Add to PATH"}))
    table.insert(result, _get_component_string("PATH"))
    table.insert(result, [[<Environment Id="PATH" Name="PATH"  Value="[INSTALLFOLDER]bin" Permanent="false" Part="last" Action="set" System="true" />]])
    table.insert(result, "</Component>")
    table.insert(result, "</Feature>")
    return result
end

-- get specvars
function _get_specvars(package)
    local installcmds = batchcmds.get_installcmds(package):cmds()
    local specvars = table.clone(package:specvars())

    local features = {}
    table.join2(features, _build_feature(package, {default = true, force = true, config_dir = true}))
    table.join2(features, _add_to_path(package))
    for name, component in table.orderpairs(package:components()) do
        table.join2(features, _build_feature(component, {name = "Install " .. name}))
    end

    specvars.PACKAGE_LICENSEFILE = function ()
        local rtf_string = ""
        local licensefile = package:get("licensefile")
        if licensefile then
            rtf_string =  _to_rtf_string(io.readfile(licensefile))
        end

        local rtf_file = path.join(package:buildir(), "license.rtf")
        io.writefile(rtf_file, rtf_string)
        return rtf_file
    end

    specvars.PACKAGE_WIX_CMDS = table.concat(features, "\n  ")
    specvars.PACKAGE_WIX_UPGRADECODE = hash.uuid(package:name())

    -- company cannot be empty with wix
    if package:get("company") == nil or package:get("company") == "" then
        specvars.PACKAGE_COMPANY = package:name()
    end
    return specvars
end

function _pack_wix(wix, package)

    -- install the initial specfile
    local specfile = path.join(package:buildir(), package:basename() .. ".wxs")
    if not os.isfile(specfile) then
        local specfile_template = package:get("specfile") or path.join(os.programdir(), "scripts", "xpack", "wix", "msi.wxs")
        os.cp(specfile_template, specfile)
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

    local argv = {"build", specfile}
    table.join2(argv, {"-ext", "WixToolset.UI.wixext"})
    table.join2(argv, {"-o", package:outputfile()})

    if package:arch() == "x64" then
        table.join2(argv, {"-arch", "x64"})
    elseif package:arch() == "x86" then
        table.join2(argv, {"-arch", "x86"})
    end

    -- make package
    os.vrunv(wix, argv)
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
