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
-- @file        dynamic_debugging.lua
--
-- @see https://devblogs.microsoft.com/cppblog/cpp-dynamic-debugging-full-debuggability-for-optimized-builds/

-- imports
import("core.project.project")
import("core.tool.toolchain")
import("core.base.semver")

-- add dynamic debugging support
function main(target, sourcekind)
    -- check if dynamic debugging is enabled
    local enabled = target:policy("build.c++.dynamic_debugging")
    if enabled == nil then
        enabled = project.policy("build.c++.dynamic_debugging")
    end
    if not enabled then
        return
    end

    -- only support Windows platform
    if not target:is_plat("windows") then
        return
    end

    -- only support x64 architecture
    if not target:is_arch("x64", "x86_64") then
        wprint("C++ Dynamic Debugging only supports x64 architecture, current arch: %s", target:arch())
        return
    end

    -- check MSVC toolchain (only support cl, not clang-cl or clang)
    if not target:has_tool(sourcekind, "cl") then
        return
    end

    -- check MSVC version (requires 19.44+)
    local msvc = target:toolchain("msvc")
    if not msvc or not msvc:check() then
        wprint("MSVC toolchain not found for C++ Dynamic Debugging")
        return
    end

    local vcvars = msvc:config("vcvars")
    if not vcvars or not vcvars.VCToolsVersion then
        wprint("MSVC VCToolsVersion not found for C++ Dynamic Debugging")
        return
    end

    local version = vcvars.VCToolsVersion
    if not version or semver.compare(version, "19.44") < 0 then
        wprint("C++ Dynamic Debugging requires MSVC 19.44+, found: %s", version or "unknown")
        return
    end

    -- check incompatible optimizations
    local has_lto = target:policy("build.optimization.lto") or project.policy("build.optimization.lto")
    if has_lto then
        wprint("C++ Dynamic Debugging is incompatible with LTO, disabling LTO")
        target:set("policy", "build.optimization.lto", false)
    end

    -- check for /GL flag (added by optimize="smallest")
    local optimize = target:get("optimize")
    if optimize == "smallest" then
        wprint("C++ Dynamic Debugging is incompatible with optimize=\"smallest\" (which adds /GL flag), consider using optimize=\"fastest\" or optimize=\"faster\" instead")
    end

    -- get flag name for sourcekind (only support cc and cxx)
    local cflag = sourcekind == "cxx" and "cxxflags" or "cflags"

    -- add /dynamicdeopt compiler flag
    target:add(cflag, "/dynamicdeopt", {force = true})

    -- add /DYNAMICDEOPT linker flag
    target:add("ldflags", "/DYNAMICDEOPT", {force = true})
    target:add("shflags", "/DYNAMICDEOPT", {force = true})
end

