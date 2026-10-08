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
-- @file        check.lua
--

import("lib.detect.find_tool")
import("target", {rootdir = os.scriptdir(), alias = "get_target"})

function main(toolchain)
    local paths = {}
    local bindir = toolchain:bindir()
    local sdkdir = toolchain:sdkdir()
    if bindir then
        table.insert(paths, bindir)
    elseif sdkdir then
        table.insert(paths, path.join(sdkdir, "bin"))
    else
        for _, package in ipairs(toolchain:packages()) do
            local installdir = package:installdir()
            if installdir then
                table.insert(paths, path.join(installdir, "bin"))
            end
            local envs = package:envs()
            if envs then
                table.join2(paths, envs.PATH)
            end
        end
    end

    -- Locate the SDK manager instead of accepting an unrelated system clang.
    local xclang
    if #paths > 0 then
        for _, dir in ipairs(paths) do
            local program = path.join(path.absolute(dir), is_host("windows") and "xclang.exe" or "xclang")
            if os.isfile(program) then
                xclang = find_tool("xclang", {program = program, force = true})
                if xclang then
                    break
                end
            end
        end
    else
        xclang = find_tool("xclang", {force = true})
    end
    if not xclang then
        return false
    end
    bindir = path.directory(xclang.program)
    local clang = path.join(bindir, is_host("windows") and "clang.exe" or "clang")
    if not os.isfile(clang) then
        return false
    end
    local target = get_target(toolchain)
    if not target or not os.isfile(path.join(bindir, target .. ".cfg")) then
        wprint("unsupported xclang target: %s/%s", toolchain:plat(), toolchain:arch())
        return false
    end
    toolchain:config_set("bindir", bindir)
    toolchain:config_set("sdkdir", path.directory(bindir))
    return true
end
