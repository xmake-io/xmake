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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.project.config")
import("private.utils.toolchain", {alias = "toolchain_utils"})

-- main entry
function main(toolchain)

    -- set toolset
    toolchain:set("toolset", "cc",  "cl.exe")
    toolchain:set("toolset", "cxx", "cl.exe")
    toolchain:set("toolset", "mrc", "rc.exe")
    if toolchain:is_arch("x86") then
        toolchain:set("toolset", "as",  "ml.exe")
    elseif toolchain:is_arch("arm64", "arm64ec") then
        toolchain:set("toolset", "as",  "armasm64_msvc@armasm64.exe")
    elseif toolchain:is_arch("arm.*") then
        toolchain:set("toolset", "as",  "armasm_msvc@armasm.exe")
    else
        toolchain:set("toolset", "as",  "ml64.exe")
    end
    toolchain:set("toolset", "ld",  "link.exe")
    toolchain:set("toolset", "sh",  "link.exe")
    toolchain:set("toolset", "ar",  "link.exe")

    -- init flags
    if toolchain:is_arch("arm64ec") then
        toolchain:add("cxflags", "/arm64EC")
    end

    -- add vs environments
    toolchain_utils.add_vsenvs(toolchain)

    -- check and add vs_binary_output env
    local vs = toolchain:config("vs")
    if vs and semver.is_valid(vs) and semver.compare(vs, "2005") < 0 then
        toolchain:add("runenvs", "VS_BINARY_OUTPUT", "1")
    end
end

