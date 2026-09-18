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

-- shell variables expanded at runtime by the launcher
local runtime_vars = {
    "HERE",
    "PREFIX"
}

-- quote a shell argument with single quotes
function _sh_quote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- quote a value for /bin/sh, keeping $HERE/$PREFIX expandable and escaping
-- everything else, e.g. "$HERE/usr/share" becomes "$HERE"'/usr/share'
function _sh_quote_value(s)
    s = tostring(s or "")
    local parts = {}
    local literal_start = 1
    local i = 1
    while i <= #s do
        if s:sub(i, i) == "$" then
            local name = nil
            local stop = nil
            local braced = s:match("^%${(%w+)}", i)
            if braced then
                name = braced
                stop = i + #braced + 2
            else
                local plain = s:match("^%$(%w+)", i)
                if plain then
                    name = plain
                    stop = i + #plain
                end
            end
            if name and table.contains(runtime_vars, name) then
                if i > literal_start then
                    table.insert(parts, _sh_quote(s:sub(literal_start, i - 1)))
                end
                table.insert(parts, string.format('"%s"', s:sub(i, stop)))
                literal_start = stop + 1
                i = stop + 1
            else
                i = i + 1
            end
        else
            i = i + 1
        end
    end
    if literal_start <= #s then
        table.insert(parts, _sh_quote(s:sub(literal_start)))
    end
    return #parts > 0 and table.concat(parts) or "''"
end

-- generate a launcher script exporting runenvs and execing the binary with
-- runargs, or nil if none are set
function generate(package, executable_path)
    local runenvs = package:get("runenvs") or {}
    local runargs = package:get("runargs") or {}
    if #runenvs == 0 and #runargs == 0 then
        return nil
    end
    local script = "#!/bin/sh\n"
    for idx, val in ipairs(runenvs) do
        if idx % 2 == 1 then
            script = script .. string.format("export %s=%s\n", val, _sh_quote_value(runenvs[idx + 1] or ""))
        end
    end
    local args = ""
    for _, a in ipairs(runargs) do
        args = args .. " " .. _sh_quote_value(a)
    end
    script = script .. string.format('exec "%s"%s "$@"\n', executable_path, args)
    return script
end

-- get the main executable path relative to prefixdir, e.g. "bin/foo"
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

-- get the info to install a launcher wrapper for deb/srpm, where the wrapper
-- takes the name of the real binary ("<name>-real"); nil if there is nothing
-- to wrap
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
