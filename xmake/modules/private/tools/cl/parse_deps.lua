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
-- @file        parse_deps.lua
--

-- imports
import("core.project.project")
import("core.base.hashset")
import("parse_include")
import("core.tool.toolchain")

-- get $VCInstallDir
function _VCInstallDir()
    local VCInstallDir = _g.VCInstallDir
    if not VCInstallDir then
        local msvc = toolchain.load("msvc")
        if msvc then
            local vcvars = msvc:config("vcvars")
            if vcvars and vcvars.VCInstallDir then
                VCInstallDir = vcvars.VCInstallDir
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
                WindowsSdkDir = vcvars.WindowsSdkDir
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
function main(depsdata)
    local results = hashset.new()
    for _, line in ipairs(depsdata:split("\n", {plain = true})) do
        local includefile = parse_include(line:trim())
        if includefile then
            includefile = _normailize_dep(includefile, os.projectdir())
            if includefile then
                results:insert(includefile)
            end
        end
    end
    return results:to_array()
end

