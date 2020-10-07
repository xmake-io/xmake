--!A cross-toolchain build utility based on Lua
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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.base.option")
import("core.project.config")

-- add the given icl environment
function _add_iclenv(toolchain, name)

    -- get iclvarsall
    local iclvarsall = config.get("__iclvarsall")
    if not iclvarsall then
        return
    end

    -- get icl environment for the current arch
    local arch = toolchain:arch()
    local iclenv = iclvarsall[arch] or {}

    -- get the paths for the icl environment
    local env = iclenv[name]
    if env then
        toolchain:add("runenvs", name:upper(), path.splitenv(env))
    end
end

-- load intel on windows
function _load_intel_on_windows(toolchain)

    -- set toolset
    if toolchain:is_plat("windows") then
        toolchain:set("toolset", "cc", "icl.exe")
        toolchain:set("toolset", "cxx", "icl.exe")
        toolchain:set("toolset", "mrc", "rc.exe")
        if toolchain:is_arch("x64") then
            toolchain:set("toolset", "as",  "ml64.exe")
        else
            toolchain:set("toolset", "as",  "ml.exe")
        end
        toolchain:set("toolset", "ld",  "link.exe")
        toolchain:set("toolset", "sh",  "link.exe")
        toolchain:set("toolset", "ar",  "link.exe")
        toolchain:set("toolset", "ex",  "lib.exe")
    else
        toolchain:set("toolset", "cc", "icc")
        toolchain:set("toolset", "cxx", "icpc", "icc")
        toolchain:set("toolset", "ld", "icpc", "icc")
        toolchain:set("toolset", "sh", "icpc", "icc")
        toolchain:set("toolset", "ar", "ar")
        toolchain:set("toolset", "ex", "ar")
        toolchain:set("toolset", "strip", "strip")
        toolchain:set("toolset", "as", "icc")
    end

    -- add icl environments
    _add_iclenv(toolchain, "PATH")
    _add_iclenv(toolchain, "LIB")
    _add_iclenv(toolchain, "INCLUDE")
    _add_iclenv(toolchain, "LIBPATH")
end

-- load intel on linux
function _load_intel_on_linux(toolchain)

    -- set toolset
    toolchain:set("toolset", "cc", "icc")
    toolchain:set("toolset", "cxx", "icpc", "icc")
    toolchain:set("toolset", "ld", "icpc", "icc")
    toolchain:set("toolset", "sh", "icpc", "icc")
    toolchain:set("toolset", "ar", "ar")
    toolchain:set("toolset", "ex", "ar")
    toolchain:set("toolset", "strip", "strip")
    toolchain:set("toolset", "as", "icc")

    -- add march flags
    local march
    if toolchain:is_arch("x86_64", "x64") then
        march = "-m64"
    elseif toolchain:is_arch("i386", "x86") then
        march = "-m32"
    end
    if march then
        toolchain:add("cxflags", march)
        toolchain:add("asflags", march)
        toolchain:add("ldflags", march)
        toolchain:add("shflags", march)
    end

    -- add includedirs and linkdirs
    for _, includedir in ipairs({"/usr/local/include", "/usr/include"}) do
        if os.isdir(includedir) then
            toolchain:add("includedirs", includedir)
        end
    end
    for _, linkdir in ipairs({"/usr/local/lib", "/usr/lib"}) do
        if os.isdir(linkdir) then
            toolchain:add("linkdirs", linkdir)
        end
    end
end

-- main entry
function main(toolchain)
    if is_host("windows") then
        return _load_intel_on_windows(toolchain)
    else
        return _load_intel_on_linux(toolchain)
    end
end

