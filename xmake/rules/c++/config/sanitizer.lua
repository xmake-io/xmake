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
import("private.utils.toolchain", {alias = "toolchain_utils"})

function _get_clang_asan_library_dir(target)
    local toolchain = target:toolchain("clang-cl") or target:toolchain("clang")
    return path.join(toolchain_utils.get_llvm_resourcedir(toolchain), "lib/windows")
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

    -- add ldflags and shflags
    -- msvc does not have an fsanitize linker flag, so the 'link' tool is excluded
    if target:has_tool("ld", "clang", "clangxx", "gcc", "gxx") then
        target:add("ldflags", "-fsanitize=" .. checkmode, {force = true})
        target:add("shflags", "-fsanitize=" .. checkmode, {force = true})
    end

    if target:is_plat("windows") and checkmode == "address" and not target:has_tool("cxx", "cl") then
        assert(target:has_runtime("MD", "MT"), "clang asan only support MD/MT runtime on windows")

        local ldflags = {}
        if target:has_tool("ld", "clang", "clangxx") then
            if target:has_runtime("MT") then
                table.insert(ldflags, "-D_MT")
            elseif target:has_runtime("MD") then
                table.join2(ldflags, {"-D_MT", "-D_DLL"})
            end
        else
            -- cmake unsupported use clang++ as linker with clang-cl compiler, so we keep using lld-link/link as linker
            -- @see https://gitlab.kitware.com/cmake/cmake/-/issues/26430
            local kind
            if target:has_runtime("MD") then
                kind = "dynamic"
            elseif target:has_runtime("MT") then
                kind = "static"
            end

            local libdir = _get_clang_asan_library_dir(target)
            local driver = target:has_tool("ld", "lld_link", "link") and "" or "-Wl,"
            local thunk = path.join(libdir, string.format("clang_rt.asan_%s_runtime_thunk-x86_64.lib", kind))
            table.join2(ldflags, {
                path.unix(path.join(libdir, "clang_rt.asan_dynamic-x86_64.lib")),
                driver .. "/WHOLEARCHIVE:" .. path.unix(thunk),
                driver .. "/INFERASANLIBS:NO",
            })
        end
        target:add("ldflags", ldflags, {force = true})
        target:add("shflags", ldflags, {force = true})
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
            if target:has_tool("cxx", "cl") then
                local msvc = target:toolchain("msvc")
                if msvc then
                    local envs = msvc:runenvs()
                    local vscmd_ver = envs and envs.VSCMD_VER
                    if vscmd_ver and semver.match(vscmd_ver):ge("17.7") then
                        local cl = assert(find_tool("cl", {envs = envs}), "cl not found!")
                        target:add("runenvs", "PATH", path.directory(cl.program))
                    end
                end
            else
                target:add("runenvs", "PATH", _get_clang_asan_library_dir(target))
            end
        end
    end
end

