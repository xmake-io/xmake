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
-- @file        sanitizer.lua
--

-- imports
import("core.project.project")
import("lib.detect.find_tool")
import("core.base.semver")
import("core.project.config")

function _get_clang_resource_dir()
    local clang = "clang" -- TODO: use target:xxx get clang?
    local outdata = os.iorunv(clang, {"--print-resource-dir"})
    return outdata:trim()
end

-- add build sanitizer
function _add_build_sanitizer(target, sourcekind, checkmode)
    -- add cflags
    local _, cc = target:tool(sourcekind)
    local flagnames = {
        cc = "cflags",
        cxx = "cxxflags",
        mm = "mflags",
        mxx = "mxflags"
    }
    local flagname = flagnames[sourcekind]
    if flagname and target:has_tool(sourcekind, "cl", "clang", "clangxx", "clang_cl", "gcc", "gxx") then
        target:add(flagname, "-fsanitize=" .. checkmode, {force = true})
    end

    if target:is_plat("windows") then
        -- msvc does not have an fsanitize linker flag, so the 'link' tool is excluded
        if not target:has_tool("ld", "link") then
            -- TODO: Add MTd/MDd support when clang asan support it
            -- @see https://devblogs.microsoft.com/cppblog/msvc-address-sanitizer-one-dll-for-all-runtime-configurations/
            assert(target:is_arch("x64"), "asan only support x64")

            local runtime
            if not target:runtimes() then
                runtime = config.get("vs_runtime")
            end

            local kind
            if runtime == "MD" or target:has_runtime("MD") then
                kind = "dynamic"
            elseif runtime == "MT" or target:has_runtime("MT") then
                kind = "static"
            else
                os.raise("asan only support MD/MT runtime")
            end

            local libdir = path.join(_get_clang_resource_dir(), "lib/windows")
            local thunk = path.join(libdir, format("clang_rt.asan_%s_runtime_thunk-x86_64.lib", kind))
            local driver = target:has_tool("ld", "lld-link", "link") and "" or "-Wl,"
            local flags = {
                path.unix(path.join(libdir, "clang_rt.asan_dynamic-x86_64.lib")),
                driver .. "/WHOLEARCHIVE:" .. path.unix(thunk),
                driver .. "/INFERASANLIBS:NO",
            }
            target:add("ldflags", flags, {force = true})
            target:add("shflags", flags, {force = true})
        end
    else
        if target:has_tool("ld", "clang", "clangxx", "gcc", "gxx") then
            target:add("ldflags", "-fsanitize=" .. checkmode, {force = true})
            target:add("shflags", "-fsanitize=" .. checkmode, {force = true})
        end
    end
end

function main(target, sourcekind)
    local sanitizer = false
    for _, checkmode in ipairs({"address", "thread", "memory", "leak", "undefined"}) do
        local enabled = target:policy("build.sanitizer." .. checkmode)
        if enabled == nil then
            enabled = project.policy("build.sanitizer." .. checkmode)
        end
        if enabled then
            _add_build_sanitizer(target, sourcekind, checkmode)
            sanitizer = true
        end
    end

    if sanitizer then
        -- enable the debug symbols for sanitizer
        if not target:get("symbols") then
            target:set("symbols", "debug")
        end

        -- we need to load runenvs for msvc
        -- @see https://github.com/xmake-io/xmake/issues/4176
        if target:is_plat("windows") and target:is_binary() then
            if target:has_tool("cxx", "clang", "clang_cl") then
                target:add("runenvs", "PATH", path.join(_get_clang_resource_dir(), "lib/windows"))
            else
                local msvc = target:toolchain("msvc")
                if msvc then
                    local envs = msvc:runenvs()
                    local vscmd_ver = envs and envs.VSCMD_VER
                    if vscmd_ver and semver.match(vscmd_ver):ge("17.7") then
                        local cl = assert(find_tool("cl", {envs = envs}), "cl not found!")
                        target:add("runenvs", "PATH", path.directory(cl.program))
                    end
                end
            end
        end
    end
end

