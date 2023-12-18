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

-- get specvars
function _get_specvars(package)
    local specvars = table.clone(package:specvars())
    return specvars
end

-- pack srpm package
function _pack_srpm(rpmbuild, package)

    -- install the initial specfile
    local specfile = package:specfile()
    if not os.isfile(specfile) then
        local specfile_template = path.join(os.programdir(), "scripts", "xpack", "srpm", "srpm.spec")
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

    -- generate the setup.sh script
    --[[
    local sourcedir = package:sourcedir()
    local setupfile = path.join(sourcedir, "__setup__.sh")
    os.cp(path.join(os.programdir(), "scripts", "xpack", "srpm", "setup.sh"), setupfile)
    local scriptfile = io.open(setupfile, "a+")
    if scriptfile then
        _write_installcmds(package, scriptfile, batchcmds.get_installcmds(package):cmds())
        for _, component in table.orderpairs(package:components()) do
            if component:get("default") ~= false then
                _write_installcmds(package, scriptfile, batchcmds.get_installcmds(component):cmds())
            end
        end
        scriptfile:close()
    end]]

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
