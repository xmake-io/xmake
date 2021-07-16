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
-- @file        cmake_importfiles.lua
--

-- imports
import("core.project.project")

-- get the builtin variables
function _get_builtinvars(target, installdir)
    return {TARGETNAME      = target:name(),
            PROJECTNAME     = project.name() or target:name(),
            TARGETFILENAME  = path.filename(target:targetfile()),
            TARGETKIND      = target:is_shared() and "SHARED" or "STATIC",
            PACKAGE_VERSION = target:get("version") or "1.0.0"}
end

-- install cmake import file
function _install_cmake_importfile(target, installdir, filename, opt)

    -- get import file path
    local projectname = project.name() or target:name()
    local importfile_src = path.join(os.programdir(), "scripts", "cmake_importfiles", filename)
    local importfile_dst = path.join(installdir, opt and opt.libdir or "lib", "cmake", projectname, (filename:gsub("xxx", projectname)))

    -- trace
    vprint("generating %s ..", importfile_dst)

    -- get the builtin variables
    local builtinvars = _get_builtinvars(target, installdir)

    -- copy and replace builtin variables
    local content = io.readfile(importfile_src)
    if content then
        content = content:gsub("(@(.-)@)", function(_, variable)
            variable = variable:trim()
            local value = builtinvars[variable]
            return type(value) == "function" and value() or value
        end)
        io.writefile(importfile_dst, content)
    end
end

-- install .cmake import files
function main(target, opt)

    -- check
    opt = opt or {}
    assert(target:is_library(), 'cmake_importfiles: only support for library target(%s)!', target:name())

    -- get install directory
    local installdir = target:installdir()
    if not installdir then
        return
    end

    -- do install
    _install_cmake_importfile(target, installdir, "xxxConfig.cmake", opt)
    _install_cmake_importfile(target, installdir, "xxxConfigVersion.cmake", opt)
    _install_cmake_importfile(target, installdir, "xxxTargets.cmake", opt)
    if is_mode("debug") then
        _install_cmake_importfile(target, installdir, "xxxTargets-debug.cmake", opt)
    else
        _install_cmake_importfile(target, installdir, "xxxTargets-release.cmake", opt)
    end
end

