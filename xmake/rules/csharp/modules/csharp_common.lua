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
-- @author      JassJam
-- @file        csharp_common.lua
--

import("core.base.option")
import("core.project.config")
import("csproj_generator", {rootdir = os.scriptdir(), alias = "generate_csproj"})

function _is_csharp_target(target)
    if target:rule("csharp") then
        return true
    end
    for _, sourcefile in ipairs(target:sourcefiles()) do
        local ext = path.extension(sourcefile):lower()
        if ext == ".cs" or ext == ".csproj" then
            return true
        end
    end
    return false
end

function _generated_csproj_path(target)
    local targetkey = target:fullname():replace("::", path.sep())
    local csprojdir = path.join(config.directory(), "rules", "csharp", targetkey, target:plat(), target:arch())
    local csprojname = target:name() .. ".csproj"
    return path.join(csprojdir, csprojname)
end

function _map_rid_arch(arch)
    arch = (arch or ""):lower()
    if arch == "x64" or arch == "x86_64" or arch == "amd64" then
        return "x64"
    elseif arch == "x86" or arch == "i386" then
        return "x86"
    elseif arch == "arm64" then
        return "arm64"
    elseif arch == "arm" or arch == "armv7" then
        return "arm"
    elseif arch == "riscv64" then
        return "riscv64"
    end
    return nil
end

function find_csproj(target)
    local csproj = target:data("csharp.csproj")
    if csproj then
        return csproj
    end
    for _, sourcefile in ipairs(target:sourcefiles()) do
        if path.extension(sourcefile):lower() == ".csproj" then
            local csprojabs = path.is_absolute(sourcefile) and sourcefile or path.absolute(sourcefile, os.projectdir())
            if os.isfile(csprojabs) then
                return csprojabs
            end
        end
    end
    return nil
end

function find_or_generate_csproj(target, opt)
    opt = opt or {}
    local csproj = find_csproj(target)
    local generated = target:data("csharp.csproj.generated")
    local generated_with_deps = target:data("csharp.csproj.generated.with_deps")

    -- prefer existing source .csproj directly
    if csproj and not generated then
        return csproj
    end

    -- generated .csproj in memory cache
    if csproj and generated then
        if opt.skip_deps or generated_with_deps then
            return csproj
        end
    end

    if not _is_csharp_target(target) then
        return nil
    end

    local csprojfile = csproj or _generated_csproj_path(target)
    local generated_now = false

    -- in load phase (skip_deps), reuse existing generated file to avoid
    -- touching mtime and causing unnecessary rebuilds.
    if not (opt.skip_deps and os.isfile(csprojfile)) then
        generate_csproj(target, csprojfile, table.join(opt, {
            is_csharp_target = _is_csharp_target,
            find_or_generate_csproj = find_or_generate_csproj
        }))
        generated_now = true
    end

    target:data_set("csharp.csproj", csprojfile)
    target:data_set("csharp.csproj.generated", true)
    if opt.skip_deps then
        -- keep this conservative in load phase: build/install phase will
        -- generate a deps-enabled project if needed, and content checks avoid
        -- unnecessary rewrites.
        if generated_now or generated_with_deps == nil then
            target:data_set("csharp.csproj.generated.with_deps", false)
        end
    else
        target:data_set("csharp.csproj.generated.with_deps", true)
    end
    return csprojfile
end

function build_mode_to_configuration()
    local mode
    if type(get_config) == "function" then
        mode = get_config("mode")
    end
    if not mode and type(is_mode) == "function" then
        if is_mode("debug") then
            mode = "debug"
        elseif is_mode("release") then
            mode = "release"
        end
    end
    mode = mode or "release"
    local mode_lower = mode:lower()
    if mode_lower == "debug" then
        return "Debug"
    elseif mode_lower == "release" then
        return "Release"
    end
    return mode:sub(1, 1):upper() .. mode:sub(2)
end

function get_runtime_identifier(target)
    local rid = target:values("csharp.runtime_identifier")
    if type(rid) == "table" then
        rid = rid[1]
    end
    if rid and #rid > 0 then
        return rid
    end
    local arch = _map_rid_arch(target:arch())
    if not arch then
        return nil
    end
    local plat = target:plat()
    if plat == "windows" or plat == "mingw" or plat == "msys" or plat == "cygwin" then
        return "win-" .. arch
    elseif plat == "linux" then
        return "linux-" .. arch
    elseif plat == "macosx" then
        return "osx-" .. arch
    end
    return nil
end

