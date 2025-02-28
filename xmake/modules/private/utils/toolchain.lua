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
-- @file        toolchain.lua
--
import("core.base.semver")
import("core.tool.linker")
import("core.tool.compiler")
import("core.language.language")

-- is the compatible with the host?
function is_compatible_with_host(name)
    if is_host("linux", "macosx", "bsd") then
        if name:startswith("clang") or name:startswith("gcc") or name == "llvm" then
            return true
        end
    elseif is_host("windows") then
        if name == "msvc" or name == "llvm" or name == "clang-cl" then
            return true
        end
    end
end

-- get vs toolset version, e.g. v143, v144, ..
function get_vs_toolset_ver(vs_toolset)
    local toolset_ver
    if vs_toolset then
        local verinfo = semver.new(vs_toolset)
        toolset_ver = "v" .. verinfo:major() .. (tostring(verinfo:minor()):sub(1, 1) or "0")

        -- @see https://github.com/xmake-io/xmake/pull/5176
        if toolset_ver and toolset_ver == "v144" and verinfo:ge("14.40") and verinfo:lt("14.50") then
            toolset_ver = "v143"
        end
    end
    return toolset_ver
end

-- map compiler flags for package
function map_compflags_for_package(package, langkind, name, values)
    -- @note we need to patch package:sourcekinds(), because it wiil be called nf_runtime for gcc/clang
    package.sourcekinds = function (self)
        local sourcekind = language.langkinds()[langkind]
        return sourcekind
    end
    local flags = compiler.map_flags(langkind, name, values, {target = package})
    package.sourcekinds = nil
    return flags
end

-- map linker flags for package
function map_linkflags_for_package(package, targetkind, sourcekinds, name, values)
    -- @note we need to patch package:sourcekinds(), because it wiil be called nf_runtime for gcc/clang
    package.sourcekinds = function (self)
        return sourcekinds
    end
    local flags = linker.map_flags(targetkind, sourcekinds, name, values, {target = package})
    package.sourcekinds = nil
    return flags
end

