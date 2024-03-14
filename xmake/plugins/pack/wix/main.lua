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

-- get a table where the key is a directory and the value a list of files
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

function _get_feature_string(name, opt)
    local level = opt.default and 1 or 0
    local description = opt.description or ""
    local allow_absent = opt.force and "false" or "true"
    local allow_advertise = opt.force and "false" or "true"
    local typical_default = opt.force and [[TypicalDefault=install"]] or ""
    local feature = string.format([[<Feature Id="%s" Title="%s" Description="%s" Level="%d" AllowAdvertise="%s" AllowAbsent="%s" %s ConfigurableDirectory="INSTALLFOLDER">]], name, name, description, level, allow_advertise, allow_absent, typical_default)
    return feature
end

function _get_component_string(id, subdirectory)
    local subdirectory = (subdirectory ~= ".") and string.format([[Subdirectory="%s"]], subdirectory) or "" 
    return string.format([[<Component Id="%s" Guid="%s" Directory="INSTALLFOLDER" %s>]], id, hash.uuid(id), subdirectory)
end 

function _build_feature(package, opt)
    opt = opt or {}
    local default = opt.default or package:get("default")

    local result = {}
    table.insert(result, _get_feature_string(package:title(), {default = default, force = opt.force, description = package:description()}))

    local installcmds = batchcmds.get_installcmds(package):cmds()
    local uninstallcmds = batchcmds.get_uninstallcmds(package):cmds()

    local cp_table = _get_cp_kind_table(package, installcmds, opt)

    for dir, files in pairs(cp_table) do
        local d = path.join(package:install_rootdir(), dir)
        table.insert(result, _get_component_string(d:gsub(path.sep(), "_"), dir))
        for _, file in ipairs(files) do
            local srcfile = file[1]
            local dstname = file[2]
            table.insert(result, string.format([[<File Source="%s" Name="%s"/>]], srcfile, dstname))
        end
        table.insert(result, "</Component>")
    end    

    table.insert(result, _get_component_string("OtherCmds"))
    table.insert(result, "</Component>")

    table.insert(result, "</Feature>")
    return result
end
-- get specvars
function _get_specvars(package)

    local installcmds = batchcmds.get_installcmds(package):cmds()
    local specvars = table.clone(package:specvars())

    local features = {}
    table.join2(features, _build_feature(package, {default = true, force = true}))

    specvars.PACKAGE_CMDS = table.concat(features, "\n  ")

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