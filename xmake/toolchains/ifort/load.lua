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

-- add the given ifort environment
function _add_ifortenv(toolchain, name)

    -- get ifortvarsall
    local ifortvarsall = config.get("__ifortvarsall")
    if not ifortvarsall then
        return
    end

    -- get ifort environment for the current arch
    local arch = toolchain:arch()
    local ifortenv = ifortvarsall[arch] or {}

    -- get the paths for the ifort environment
    local env = ifortenv[name]
    if env then
        toolchain:add("runenvs", name:upper(), path.splitenv(env))
    end
end

-- load intel on windows
function _load_intel_on_windows(toolchain)

    -- set toolset
    toolchain:set("toolset", "fc", "ifort.exe")
    toolchain:set("toolset", "mrc", "rc.exe")
    if toolchain:is_arch("x64") then
        toolchain:set("toolset", "as",  "ml64.exe")
    else
        toolchain:set("toolset", "as",  "ml.exe")
    end
    toolchain:set("toolset", "fcld",  "ifort.exe")
    toolchain:set("toolset", "fcsh",  "ifort.exe")
    toolchain:set("toolset", "ar",  "link.exe")
    toolchain:set("toolset", "ex",  "lib.exe")

    -- add ifort environments
    _add_ifortenv(toolchain, "PATH")
    _add_ifortenv(toolchain, "LIB")
    _add_ifortenv(toolchain, "INCLUDE")
    _add_ifortenv(toolchain, "LIBPATH")
end

-- load intel on linux
function _load_intel_on_linux(toolchain)

    -- set toolset
    toolchain:set("toolset", "fc", "ifort")
    toolchain:set("toolset", "fcld", "ifort")
    toolchain:set("toolset", "fcsh", "ifort")
    toolchain:set("toolset", "ar", "ar")

    -- add march flags
    local march
    if toolchain:is_arch("x86_64", "x64") then
        march = "-m64"
    elseif toolchain:is_arch("i386", "x86") then
        march = "-m32"
    end
    if march then
        toolchain:add("fcflags", march)
        toolchain:add("fcldflags", march)
        toolchain:add("fcshflags", march)
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

