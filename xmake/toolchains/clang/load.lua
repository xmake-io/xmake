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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        xmake.lua
--

import("detect.sdks.find_vstudio")
import("detect.sdks.find_mingw")
import("core.project.config")

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
        if name == "INCLUDE" or name == "LIB" then
            toolchain:add("runenvs", name, table.concat(path.splitenv(new), ";"))
        else
            toolchain:add("runenvs", name, table.unwrap(path.splitenv(new)))
        end
    end
end

function main(toolchain, suffix)
    import("core.base.option")
    import("core.project.project")

    if project.policy("build.optimization.lto") then
        toolchain:set("toolset", "ar",  "llvm-ar" .. suffix)
        toolchain:set("toolset", "ranlib",  "llvm-ranlib" .. suffix)
    end

    local march
    if toolchain:is_arch("x86_64", "x64", "arm64") then
        march = "-m64"
    elseif toolchain:is_arch("i386", "x86", "i686") then
        march = "-m32"
    end
    if march then
        toolchain:add("cxflags", march)
        toolchain:add("mxflags", march)
        toolchain:add("asflags", march)
        toolchain:add("ldflags", march)
        toolchain:add("shflags", march)
    end
    if toolchain:is_plat("windows") then
        toolchain:add("runtimes", "MT", "MTd", "MD", "MDd")
    end

    local host_arch = os.arch()
    local target_arch = toolchain:arch()

    if host_arch == target_arch then
        -- Early exit: prevents further configuration of this toolchain
        return
    elseif option.get("verbose") then
        cprint("${bright yellow}cross compiling from %s to %s", host_arch, target_arch)
    end

    local target
    if toolchain:is_arch("x86_64", "x64") then
        target = "x86_64"
    elseif toolchain:is_arch("i386", "x86", "i686") then
        target = "i686"
    elseif toolchain:is_arch("arm64", "aarch64") then
        target = "aarch64"
    elseif toolchain:is_arch("arm") then
        target = "armv7"
    end

    if toolchain:is_plat("windows") then
        target = target .. "-windows-msvc"

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

        if is_host("linux") then
            toolchain:add("ldflags", "-fuse-ld=lld-link" .. suffix)
            toolchain:add("shflags", "-fuse-ld=lld-link" .. suffix)
        end
    elseif toolchain:is_plat("mingw") then
        target = target .. "-w64-windows-gnu"
    elseif toolchain:is_plat("linux") then
        target = target .. "-linux-gnu"
    end

    if target then
        toolchain:add("cxflags", "--target=" .. target)
        toolchain:add("asflags", "--target=" .. target)
        toolchain:add("ldflags", "--target=" .. target)
        toolchain:add("shflags", "--target=" .. target)
    end
end
