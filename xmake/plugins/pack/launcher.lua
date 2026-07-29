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
-- Copyright (C) 2026-present, Xmake Open Source Community.
--
-- @author      karurochari
-- @file        launcher.lua
--

-- imports
import("core.base.option")
import("core.project.config")

-- Generate a shell script that sets runenvs and execs the binary with runargs.
-- Returns the script content as a string, or nil if no runenvs/runargs are set.
function generate(package, executable_path)
    local runenvs = package:get("runenvs") or {}
    local runargs = package:get("runargs") or {}
    if #runenvs == 0 and #runargs == 0 then
        return nil
    end
    local script = "#!/bin/sh\n"
    for idx, val in ipairs(runenvs) do
        if idx % 2 == 1 then
            script = script .. string.format('export %s="%s"\n', val, runenvs[idx + 1] or "")
        end
    end
    local args = ""
    for _, a in ipairs(runargs) do
        args = args .. " " .. a
    end
    script = script .. string.format('exec "%s"%s "$@"\n', executable_path, args)
    return script
end

-- Get the main executable path relative to installdir.
-- Returns binary name string.
function main_executable(package)
    local bindir = package:bindir() or "bin"
    for _, target in ipairs(package:targets()) do
        if target:is_binary() then
            return path.join(bindir, target:basename())
        end
    end
    -- fallback: search bindir
    local installdir = os.isdir(package:installdir()) and package:installdir() or package:install_rootdir()
    if installdir then
        local p = path.join(installdir, bindir)
        if os.isdir(p) then
            for _, file in ipairs(os.files(path.join(p, "*"))) do
                if os.isexec(file) then
                    return path.join(bindir, path.filename(file))
                end
            end
        end
    end
    return nil
end
