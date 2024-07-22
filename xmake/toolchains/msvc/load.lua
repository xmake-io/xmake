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
import("core.base.semver")
import("core.project.config")
import("detect.sdks.find_vstudio")

-- add the given vs environment
function _add_vsenv(toolchain, name, curenvs)

    -- get vcvars
    local vcvars = toolchain:config("vcvars")
    if not vcvars then
        return
    end

    -- get the paths for the vs environment
    local new = vcvars[name]
    if new then
        -- fix case naming conflict for cmake/msbuild between the new msvc envs and current environment, if we are running xmake in vs prompt.
        -- @see https://github.com/xmake-io/xmake/issues/4751
        for k, c in pairs(curenvs) do
            if name:lower() == k:lower() and name ~= k then
                name = k
                break
            end
        end
        toolchain:add("runenvs", name, table.unwrap(path.splitenv(new)))
    end
end

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
    local expect_vars = {"PATH", "LIB", "INCLUDE", "LIBPATH"}
    local curenvs = os.getenvs()
    for _, name in ipairs(expect_vars) do
        _add_vsenv(toolchain, name, curenvs)
    end
    for _, name in ipairs(find_vstudio.get_vcvars()) do
        if not table.contains(expect_vars, name:upper()) then
            _add_vsenv(toolchain, name, curenvs)
        end
    end

    -- check and add vs_binary_output env
    local vs = toolchain:config("vs")
    if vs and semver.is_valid(vs) and semver.compare(vs, "2005") < 0 then
        toolchain:add("runenvs", "VS_BINARY_OUTPUT", "1")
    end
end

