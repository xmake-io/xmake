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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      chooyy
-- @file        main.lua
--

-- imports
import("lib.detect.find_tool")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")
import(".batchcmds")

-- get the iscc (Inno Setup Command-Line Compiler)
function _get_iscc()

    -- enter the environments of innosetup
    local oldenvs = packagenv.enter("innosetup")

    -- find iscc
    local packages = {}
    local iscc = find_tool("iscc")
    if not iscc then
        table.join2(packages, install_packages("innosetup"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need to force detect and flush detect cache after loading all environments
    if not iscc then
        iscc = find_tool("iscc", {force = true})
    end
    assert(iscc, "iscc not found!")
    return iscc, oldenvs
end

-- translate the file path
function _translate_filepath(package, filepath)
    filepath = filepath:replace(package:install_rootdir(), "{app}", {plain = true})
    filepath = filepath:gsub("/", "\\")
    return filepath
end

-- get the component flag
function _get_component_flag(opt)
    if opt.component then
        return "; Components: " .. opt.component
    end
    return ""
end

-- new empty command strings
function _new_commands()
    return {
        files             = {},
        dirs              = {},
        registry          = {},
        run               = {},
        installdelete     = {},
        uninstalldelete   = {},
        code              = {},
        raw               = {}
    }
end

-- merge command strings
function _merge_commands(dst, src)
    for _, name in ipairs({"files", "dirs", "registry", "run",
                           "installdelete", "uninstalldelete", "code", "raw"}) do
        table.join2(dst[name], src[name])
    end
end

-- get command strings
function _get_command_strings(package, cmd, opt)
    opt = table.join(cmd.opt or {}, opt)
    local result = _new_commands()
    local component_flag = _get_component_flag(opt)
    local kind = cmd.kind
    if kind == "cp" then
        -- https://jrsoftware.org/ishelp/topic_filessection.htm
        local srcpath = cmd.srcpath
        local dstpath = _translate_filepath(package, cmd.dstpath)

        -- match files and directories
        local srcitems = os.filedirs(srcpath)
        for _, srcitem in ipairs(srcitems) do
            if os.isdir(srcitem) then
                -- copy directory recursively
                local dstdir = dstpath
                if opt.rootdir then
                    dstdir = path.join(dstdir, path.relative(srcitem, opt.rootdir))
                else
                    dstdir = path.join(dstdir, path.filename(srcitem))
                end
                dstdir = _translate_filepath(package, dstdir)
                srcitem = path.absolute(path.normalize(srcitem))
                table.insert(result.files, string.format('Source: "%s\\*"; DestDir: "%s"; Flags: ignoreversion recursesubdirs createallsubdirs%s',
                    srcitem, dstdir, component_flag))
            else
                -- copy file
                local dstfile = dstpath
                if #srcitems > 1 or path.islastsep(dstfile) then
                    if opt.rootdir then
                        dstfile = path.join(dstfile, path.relative(srcitem, opt.rootdir))
                    else
                        dstfile = path.join(dstfile, path.filename(srcitem))
                    end
                end
                srcitem = path.absolute(path.normalize(srcitem))
                local srcname = path.filename(srcitem)
                local dstname = path.filename(dstfile)
                local dstdir = _translate_filepath(package, path.directory(dstfile))
                local destname = ""
                if dstname ~= srcname then
                    destname = string.format('DestName: "%s"; ', dstname)
                end
                table.insert(result.files, string.format('Source: "%s"; DestDir: "%s"; %sFlags: ignoreversion%s',
                    srcitem, dstdir, destname, component_flag))
            end
        end
    elseif kind == "rm" then
        local filepath = _translate_filepath(package, cmd.filepath)
        local target = opt.install and result.installdelete or result.uninstalldelete
        table.insert(target, string.format('Type: files; Name: "%s"%s', filepath, component_flag))
    elseif kind == "rmdir" then
        local dir = _translate_filepath(package, cmd.dir)
        local target = opt.install and result.installdelete or result.uninstalldelete
        table.insert(target, string.format('Type: filesandordirs; Name: "%s"%s', dir, component_flag))
    elseif kind == "mkdir" then
        local dir = _translate_filepath(package, cmd.dir)
        table.insert(result.dirs, string.format('Name: "%s"%s', dir, component_flag))
    elseif kind == "mv" then
        local srcpath = _translate_filepath(package, cmd.srcpath)
        local dstpath = _translate_filepath(package, cmd.dstpath)
        table.insert(result.code, string.format("    RenameFile(ExpandConstant('%s'), ExpandConstant('%s'));", srcpath, dstpath))
    elseif kind == "runv" or kind == "vrunv" then
        local program = cmd.program
        if program then
            if path.is_absolute(program) then
                program = _translate_filepath(package, program)
            elseif os.isfile(program) then
                program = path.absolute(program)
            end
        end
        local params = cmd.argv and table.concat(cmd.argv, " ") or ""
        table.insert(result.run, string.format('Filename: "%s"; Parameters: "%s"; Flags: postinstall skipifsilent%s',
            program or "", params, component_flag))
    elseif kind == "inno" then
        table.insert(result.raw, cmd.rawstr)
    end
    return result
end

-- get commands string
function _get_commands_string(package, cmds, opt)
    local result = _new_commands()
    for _, cmd in ipairs(cmds) do
        _merge_commands(result, _get_command_strings(package, cmd, opt))
    end
    return result
end

-- get install commands of component
function _get_component_installcmds(component)
    return _get_commands_string(component, batchcmds.get_installcmds(component):cmds(), {install = true, component = component:name()})
end

-- get uninstall commands of component
function _get_component_uninstallcmds(component)
    return _get_commands_string(component, batchcmds.get_uninstallcmds(component):cmds(), {install = false, component = component:name()})
end

-- get install commands
function _get_installcmds(package)
    return _get_commands_string(package, batchcmds.get_installcmds(package):cmds(), {install = true})
end

-- get uninstall commands
function _get_uninstallcmds(package)
    return _get_commands_string(package, batchcmds.get_uninstallcmds(package):cmds(), {install = false})
end

-- get the component entry
function _get_component_string(component)
    local parts = {
        string.format('Name: "%s"', component:name()),
        string.format('Description: "%s"', component:title())
    }
    if component:get("default") ~= false then
        table.insert(parts, "Types: full")
    end
    return table.concat(parts, "; ")
end

-- get the architectures string
function _get_arch(package)
    local arch = package:arch()
    if arch == "x64" or arch == "x86_64" then
        return "ArchitecturesAllowed=x64compatible\nArchitecturesInstallIn64BitMode=x64compatible"
    elseif arch == "arm64" then
        return "ArchitecturesAllowed=arm64\nArchitecturesInstallIn64BitMode=arm64"
    elseif arch == "arm64ec" then
        return "ArchitecturesAllowed=arm64"
    elseif arch == "arm" then
        return "ArchitecturesAllowed=arm32compatible"
    else
        return "ArchitecturesAllowed=x86compatible"
    end
end

-- get specvars
function _get_specvars(package)
    local specvars = table.clone(package:specvars())
    specvars.PACKAGE_OUTPUTDIR = path.absolute(package:outputdir())
    specvars.PACKAGE_BASENAME = package:basename()

    -- version cannot be empty with Inno Setup
    if not specvars.PACKAGE_VERSION or specvars.PACKAGE_VERSION == "" then
        specvars.PACKAGE_VERSION = "0.0.0"
    end

    -- company cannot be empty with Inno Setup
    if not specvars.PACKAGE_COMPANY or specvars.PACKAGE_COMPANY == "" then
        specvars.PACKAGE_COMPANY = package:name()
    end
    specvars.PACKAGE_VERSION_MAJOR = specvars.PACKAGE_VERSION_MAJOR or "0"
    specvars.PACKAGE_VERSION_MINOR = specvars.PACKAGE_VERSION_MINOR or "0"
    specvars.PACKAGE_VERSION_ALTER = specvars.PACKAGE_VERSION_ALTER or "0"
    specvars.PACKAGE_INNO_APPID = hash.uuid(package:name())
    specvars.PACKAGE_INNO_ARCH = _get_arch(package)

    -- the installer icon and license file
    local iconfile = package:get("iconfile")
    if iconfile then
        specvars.PACKAGE_ICONFILE = path.absolute(iconfile)
    end
    local licensefile = package:get("licensefile")
    if licensefile then
        specvars.PACKAGE_LICENSEFILE = path.absolute(licensefile)
    end

    -- the uninstall display icon
    local displayicon = package:displayicon()
    if displayicon then
        displayicon = _translate_filepath(package, displayicon)
    end
    specvars.PACKAGE_DISPLAYICON = displayicon or ""

    -- the binary directory
    specvars.PACKAGE_BINDIR = _translate_filepath(package, package:bindir())

    -- collect main install/uninstall commands
    local commands = _new_commands()
    _merge_commands(commands, _get_installcmds(package))
    _merge_commands(commands, _get_uninstallcmds(package))

    -- collect component install/uninstall commands
    local components = {}
    for _, component in table.orderpairs(package:components()) do
        table.insert(components, _get_component_string(component))
        _merge_commands(commands, _get_component_installcmds(component))
        _merge_commands(commands, _get_component_uninstallcmds(component))
    end

    -- the install/uninstall sections
    specvars.PACKAGE_INNO_COMPONENTS = table.concat(components, "\n")
    specvars.PACKAGE_INNO_FILES = table.concat(commands.files, "\n")
    specvars.PACKAGE_INNO_DIRS = table.concat(commands.dirs, "\n")
    specvars.PACKAGE_INNO_REGISTRY = table.concat(commands.registry, "\n")
    specvars.PACKAGE_INNO_RUN = table.concat(commands.run, "\n")
    specvars.PACKAGE_INNO_INSTALLDELETE = table.concat(commands.installdelete, "\n")
    specvars.PACKAGE_INNO_UNINSTALLDELETE = table.concat(commands.uninstalldelete, "\n")
    specvars.PACKAGE_INNO_CODE = table.concat(commands.code, "\n")
    specvars.PACKAGE_INNO_RAW = table.concat(commands.raw, "\n")
    return specvars
end

-- pack inno package
function _pack_inno(iscc, package)

    -- install the initial specfile
    local specfile = path.join(package:builddir(), package:basename() .. ".iss")
    if not os.isfile(specfile) then
        local specfile_template = package:get("specfile") or path.join(os.programdir(), "scripts", "xpack", "inno", "setup.iss")
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
        local name = name:trim()
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
    os.vrunv(iscc, {specfile})
end

function main(package)

    -- only for windows
    if not is_host("windows") then
        return
    end

    cprint("packing %s", package:outputfile())

    -- get iscc
    local iscc, oldenvs = _get_iscc()

    -- pack inno package
    _pack_inno(iscc.program, package)

    -- done
    os.setenvs(oldenvs)
end
