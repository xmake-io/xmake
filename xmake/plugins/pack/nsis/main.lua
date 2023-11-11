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

-- pack nsis package
function _pack_nsis(makensis, package, opt)

    -- install the initial specfile
    local specfile = package:specfile()
    if not os.isfile(specfile) then
        local specfile_template = path.join(os.programdir(), "scripts", "xpack", "nsis", "makensis.nsi")
        os.cp(specfile_template, specfile)
    end

    -- get version
    local version, version_build = package:version()
    assert(version, "xpack(%s): version not found!", package:name())
    version = semver.new(version)

    -- generate specfile
    print("xpack(%s)", package:name())
    print("    description: %s", package:description())
    print("    installcmd: ", package:script("installcmd"))

    local argv = {}
    if version:major() then
        table.insert(argv, "/DMAJOR=" .. version:major())
    end
    if version:minor() then
        table.insert(argv, "/DMINOR=" .. version:minor())
    end
    if version:patch() then
        table.insert(argv, "/DPATCH=" .. version:patch())
    end
    if version_build then
        table.insert(argv, "/DBUILD=" .. version_build)
    end
    table.insert(argv, specfile)
    os.vrunv(makensis, argv)
end

function main(package)

    -- get makensis
    local makensis, oldenvs = _get_makensis()

    -- clean the build directory first
    os.tryrm(package:buildir())

    -- pack nsis package
    _pack_nsis(makensis.program, package, opt)

    -- done
    os.setenvs(oldenvs)
end
