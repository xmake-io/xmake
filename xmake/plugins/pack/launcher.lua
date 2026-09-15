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

-- quote a shell argument with single quotes
function _sh_quote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Generate a shell script that sets runenvs and execs the binary with runargs.
-- Returns the script content as a string, or nil if no runenvs/runargs are set.
--
-- The executable_path may contain shell variables (e.g. $PREFIX, ${HERE}) that
-- must be expanded at runtime, so it is kept in double quotes while the user
-- supplied env values and args are single quoted.
function generate(package, executable_path)
    local runenvs = package:get("runenvs") or {}
    local runargs = package:get("runargs") or {}
    if #runenvs == 0 and #runargs == 0 then
        return nil
    end
    local script = "#!/bin/sh\n"
    for idx, val in ipairs(runenvs) do
        if idx % 2 == 1 then
            script = script .. string.format("export %s=%s\n", val, _sh_quote(runenvs[idx + 1] or ""))
        end
    end
    local args = ""
    for _, a in ipairs(runargs) do
        args = args .. " " .. _sh_quote(a)
    end
    script = script .. string.format('exec "%s"%s "$@"\n', executable_path, args)
    return script
end

-- Get the main executable path relative to the prefixdir.
-- e.g. "bin/foo", or nil if no executable was found.
function main_executable(package)
    local bindir = package:get("bindir") or "bin"
    for _, target in ipairs(package:targets()) do
        if target:is_binary() then
            return path.join(bindir, target:basename())
        end
    end
    -- fallback: search the installed bindir
    local installdir = package:installdir()
    if os.isdir(installdir) then
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

-- Get the info needed to install a same-name launcher wrapper for linux
-- package formats (deb/srpm), where the wrapper must take the name of the real
-- binary. Returns nil when no runenvs/runargs are set or no binary is found.
--
-- The real binary is renamed to "<name>-real" and the wrapper is written into
-- the package build dir, so formats can append install commands to move the
-- real binary and install the wrapper in its place.
function launcher_info(package)
    local launcher_exe = main_executable(package)
    if not launcher_exe then
        return nil
    end
    local runenvs = package:get("runenvs") or {}
    local runargs = package:get("runargs") or {}
    if #runenvs == 0 and #runargs == 0 then
        return nil
    end
    local bindir = path.directory(launcher_exe) or "."
    local exename = path.filename(launcher_exe)
    local real_rel = path.join(bindir, exename .. "-real")
    -- the wrapper is installed under /usr (deb) or %{_exec_prefix} (srpm)
    local exec_path = path.join("/usr", real_rel)
    local wrapperfile = path.join(package:builddir(), "launcher")
    io.writefile(wrapperfile, generate(package, exec_path))
    os.vrunv("chmod", {"+x", wrapperfile})
    return {
        launcher_exe = launcher_exe,
        real_rel = real_rel,
        exec_path = exec_path,
        wrapperfile = path.absolute(wrapperfile)
    }
end
