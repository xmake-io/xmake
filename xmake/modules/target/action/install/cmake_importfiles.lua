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

-- get the lib file of the target
function _get_libfile(target, installdir)
    local libfile = path.filename(target:targetfile())
    if target:is_plat("windows") then
        libfile = libfile:gsub("%.dll$", ".lib")
    elseif target:is_plat("mingw") then
        if os.isfile(path.join(installdir, "lib", libfile:gsub("%.dll$", ".dll.a"))) then
            libfile = libfile:gsub("%.dll$", ".dll.a")
        else
            libfile = libfile:gsub("%.dll$", ".lib")
        end
    end
    return libfile
end

-- get the builtin variables
function _get_builtinvars(target, installdir)
    return {TARGETNAME      = target:name(),
            PROJECTNAME     = project.name() or target:name(),
            TARGETFILENAME  = target:targetfile() and _get_libfile(target, installdir),
            TARGETKIND      = target:is_headeronly() and "INTERFACE" or (target:is_shared() and "SHARED" or "STATIC"),
            PACKAGE_VERSION = target:get("version") or "1.0.0",
            TARGET_PTRBYTES = target:is_arch("x86", "i386") and "4" or "8"}
end

-- install cmake config file
function _install_cmake_configfile(target, installdir, filename, opt)

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
        content = content:split("#######################+#")[1]
        content = content:gsub("(@(.-)@)", function(_, variable)
            variable = variable:trim()
            local value = builtinvars[variable]
            return type(value) == "function" and value() or value
        end)
        io.writefile(importfile_dst, content)
    end
end

-- append target to cmake config file
function _append_cmake_configfile(target, installdir, filename, opt)

    -- get import file path
    local projectname = project.name() or target:name()
    local importfile_src = path.join(os.programdir(), "scripts", "cmake_importfiles", filename)
    local importfile_dst = path.join(installdir, opt and opt.libdir or "lib", "cmake", projectname, (filename:gsub("xxx", projectname)))

    -- get the builtin variables
    local builtinvars = _get_builtinvars(target, installdir)

    -- generate the file if not exist / file is outdated
    if target:is_headeronly() or not os.isfile(importfile_dst) or os.mtime(importfile_dst) < os.mtime(target:targetfile()) then
        _install_cmake_configfile(target, installdir, filename, opt)
    end

    -- copy and replace builtin variables
    local content = io.readfile(importfile_src)
    local dst_content = io.readfile(importfile_dst)
    if content then
        content = content:split("#######################+#")[2]
        content = content:gsub("(@(.-)@)", function(_, variable)
            variable = variable:trim()
            local value = builtinvars[variable]
            return type(value) == "function" and value() or value
        end)
        content = content:trim()

        -- check if the target already exists
        if not dst_content:match(format("%sTargets.cmake", target:name())) then
            io.writefile(importfile_dst, dst_content:trim() .. "\n\n" .. content .. "\n")
        end
    end
end

-- install cmake target file
function _install_cmake_targetfile(target, installdir, filename, opt)

    -- get import file path
    local projectname = project.name() or target:name()
    local importfile_src = path.join(os.programdir(), "scripts", "cmake_importfiles", filename)
    local importfile_dst = path.join(installdir, opt and opt.libdir or "lib", "cmake", projectname, (filename:gsub("xxx", target:name())))

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
    _append_cmake_configfile(target, installdir, "xxxConfig.cmake", opt)
    _install_cmake_configfile(target, installdir, "xxxConfigVersion.cmake", opt)
    _install_cmake_targetfile(target, installdir, "xxxTargets.cmake", opt)
    if not target:is_headeronly() then
        if is_mode("debug") then
            _install_cmake_targetfile(target, installdir, "xxxTargets-debug.cmake", opt)
        else
            _install_cmake_targetfile(target, installdir, "xxxTargets-release.cmake", opt)
        end
    end
end

