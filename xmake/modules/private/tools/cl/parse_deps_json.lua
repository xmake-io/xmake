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
-- @file        parse_deps_json.lua
--

-- imports
import("core.project.project")
import("core.base.hashset")
import("core.base.json")
import("core.tool.toolchain")

-- get $VCInstallDir
function _VCInstallDir()
    local VCInstallDir = _g.VCInstallDir
    if not VCInstallDir then
        local msvc = toolchain.load("msvc")
        if msvc then
            local vcvars = msvc:config("vcvars")
            if vcvars and vcvars.VCInstallDir then
                VCInstallDir = vcvars.VCInstallDir:lower() -- @note we need lower case for json/deps
                _g.VCInstallDir = VCInstallDir
            end
        end
    end
    return VCInstallDir
end

-- get $WindowsSdkDir
function _WindowsSdkDir()
    local WindowsSdkDir = _g.WindowsSdkDir
    if not WindowsSdkDir then
        local msvc = toolchain.load("msvc")
        if msvc then
            local vcvars = msvc:config("vcvars")
            if vcvars and vcvars.WindowsSdkDir then
                WindowsSdkDir = vcvars.WindowsSdkDir:lower() -- @note we need lower case for json/deps
                _g.WindowsSdkDir = WindowsSdkDir
            end
        end
    end
    return WindowsSdkDir
end

-- normailize path of a dependecy
function _normailize_dep(dep, projectdir)
    if path.is_absolute(dep) then
        dep = path.translate(dep)
    else
        dep = path.absolute(dep, projectdir)
    end
    dep = dep:lower()
    local VCInstallDir = _VCInstallDir()
    local WindowsSdkDir = _WindowsSdkDir()
    if (VCInstallDir and dep:startswith(VCInstallDir)) or (WindowsSdkDir and dep:startswith(WindowsSdkDir)) then
        -- we ignore headerfiles in vc install directory
        return
    end
    if dep:startswith(projectdir) then
        return path.relative(dep, projectdir)
    else
        -- we need also check header files outside project
        -- https://github.com/xmake-io/xmake/issues/1154
        return dep
    end
end

-- parse depsfiles from string
--
--[[
{
    "Version": "1.2",
    "Data": {
        "Source": "c:\users\ruki\desktop\user_headerunit\src\main.cpp",
        "ProvidedModule": "",
        "Includes": [],
        "ImportedModules": [
            {
                "Name": "hello",
                "BMI": "c:\users\ruki\desktop\user_headerunit\src\hello.ifc"
            }
        ],
        "ImportedHeaderUnits": [
            {
                "Header": "c:\users\ruki\desktop\user_headerunit\src\header.hpp",
                "BMI": "c:\users\ruki\desktop\user_headerunit\src\header.hpp.ifc"
            }
        ]
    }
}]]
function main(depsdata)

    -- decode json data first
    depsdata = json.decode(depsdata)

    -- get includes
    local data
    if depsdata then
        data = depsdata.Data
    end
    if data then
        includes = data.Includes
        for _, item in ipairs(data.ImportedModules) do
            local bmifile = item.BMI
            if bmifile then
                includes = includes or {}
                table.insert(includes, bmifile)
            end
        end
        for _, item in ipairs(data.ImportedHeaderUnits) do
            local bmifile = item.BMI
            if bmifile then
                includes = includes or {}
                table.insert(includes, bmifile)
            end
        end
    end

    -- translate it
    local results = hashset.new()
    local projectdir = os.projectdir():lower() -- we need generate lower string, because json values are all lower
    for _, includefile in ipairs(includes) do
        includefile = _normailize_dep(includefile, projectdir)
        if includefile then
            results:insert(includefile)
        end
    end
    return results:to_array()
end

