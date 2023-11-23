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
import(".batchcmds")

-- get the makeself
function _get_makeself()

    -- enter the environments of makeself
    local oldenvs = packagenv.enter("makeself")

    -- find makeself
    local packages = {}
    local makeself = find_tool("makeself.sh")
    if not makeself then
        table.join2(packages, install_packages("makeself"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need to force detect and flush detect cache after loading all environments
    if not makeself then
        makeself = find_tool("makeself.sh", {force = true})
    end
    assert(makeself, "makeself not found!")
    return makeself, oldenvs
end

-- get specvars
function _get_specvars(package)
    local specvars = table.clone(package:specvars())
    return specvars
end

-- pack runself package
function _pack_runself(makeself, package)

    -- install the initial specfile
    local specfile = package:specfile()
    if not os.isfile(specfile) then
        local specfile_template = path.join(os.programdir(), "scripts", "xpack", "runself", "makeself.lsm")
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

    -- install the setup.sh script
    local installdir = package:installdir()
    local setupfile = path.join(installdir, "__setup__.sh")
    os.cp(path.join(os.programdir(), "scripts", "xpack", "runself", "setup.sh"), setupfile)

    -- make package
    os.vrunv(makeself, {"--gzip", "--sha256", "--lsm", specfile,
        installdir, package:outputfile(), package:basename(), "./__setup__.sh"})
end

function main(package)

    if is_subhost("windows") then
        return
    end

    cprint("packing %s", package:outputfile())

    -- get makeself
    local makeself, oldenvs = _get_makeself()

    -- pack runself package
    _pack_runself(makeself.program, package)

    -- done
    os.setenvs(oldenvs)
end
