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

-- get command string
function _get_command_strings(package, cmd)
    local result = {}
    local kind = cmd.kind
    if kind == "cp" then
        -- https://nsis.sourceforge.io/Reference/File
        local srcfiles = os.files(cmd.srcpath)
        for _, srcfile in ipairs(srcfiles) do
 --           table.insert(result, string.format("File /oname=%s %s", cmd.dstpath, srcfile))
        end
    elseif kind == "rm" then
        -- TODO
    elseif kind == "mv" then
        -- TODO
    elseif kind == "cd" then
        -- TODO
    elseif kind == "mkdir" then
        -- TODO
    elseif kind == "show" then
        -- TODO
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

-- get install commands
function _get_installcmds(package)
    local batchcmds_ = batchcmds.new()

    -- TODO

    -- get custom install commands
    local script = package:script("installcmd")
    if script then
        script(package, batchcmds_)
    end

    -- generate command string
    return _get_commands_string(package, batchcmds_:cmds())
end

-- get uninstall commands
function _get_uninstallcmds(package)
    local batchcmds_ = batchcmds.new()

    -- TODO

    -- get custom uninstall commands
    local script = package:script("uninstallcmd")
    if script then
        script(package, batchcmds_)
    end

    -- generate command string
    return _get_commands_string(package, batchcmds_:cmds())
end

-- get specvars
function _get_specvars(package)
    local specvars = table.clone(package:specvars())
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
