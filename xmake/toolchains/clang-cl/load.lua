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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("detect.sdks.find_vstudio")

-- add the given vs environment
function _add_vsenv(toolchain, name)

    -- get vcvars
    local vcvars = toolchain:config("vcvars")
    if not vcvars then
        return
    end

    -- get the paths for the vs environment
    local new = vcvars[name]
    if new then
        toolchain:add("runenvs", name, table.unwrap(path.splitenv(new)))
    end
end

-- main entry
function main(toolchain)

    -- set toolset
    toolchain:set("toolset", "cc",  "clang-cl.exe")
    toolchain:set("toolset", "cxx", "clang-cl.exe")
    toolchain:set("toolset", "mrc", "rc.exe")
    if toolchain:is_arch("x64") then
        toolchain:set("toolset", "as",  "ml64.exe")
    else
        toolchain:set("toolset", "as",  "ml.exe")
    end
    toolchain:set("toolset", "ld",  "link.exe")
    toolchain:set("toolset", "sh",  "link.exe")
    toolchain:set("toolset", "ar",  "link.exe")

    -- add vs environments
    local expect_vars = {"PATH", "LIB", "INCLUDE", "LIBPATH"}
    for _, name in ipairs(expect_vars) do
        _add_vsenv(toolchain, name)
    end
    for _, name in ipairs(find_vstudio.get_vcvars()) do
        if not table.contains(expect_vars, name:upper()) then
            _add_vsenv(toolchain, name)
        end
    end

    local march
    if toolchain:is_arch("x86_64", "x64") then
        march = "-m64"
    elseif toolchain:is_arch("i386", "x86") then
        march = "-m32"
    end
    if march then
        toolchain:add("cxflags", march)
        toolchain:add("mxflags", march)
        toolchain:add("asflags", march)
    end
end

