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
-- @file        install.lua
--

import("csharp_common")

function main(target, opt)
    local function _q(arg)
        arg = tostring(arg)
        if arg:find("[%s\"]") then
            arg = "\"" .. arg:gsub("\"", "\\\"") .. "\""
        end
        return arg
    end

    local csprojfile = assert(csharp_common.find_csproj(target), "target(%s): missing csharp .csproj file!", target:name())
    local dotnet = csharp_common.get_dotnet_program(target)
    local configuration = csharp_common.build_mode_to_configuration()
    local verbosity = csharp_common.get_dotnet_verbosity()

    local install_path = target:installdir()
    if target:is_binary() then
        install_path = target:installdir("bin")
    elseif target:is_static() or target:is_shared() then
        install_path = target:installdir("lib")
    end
    if not install_path or #install_path == 0 then
        return
    end

    local install_abs = path.is_absolute(install_path) and install_path or path.absolute(install_path, os.projectdir())
    os.mkdir(install_abs)

    local rid = csharp_common.get_runtime_identifier(target)
    local argv = {
        "publish", csprojfile,
        "--nologo",
        "--configuration", configuration,
        "--verbosity", verbosity,
        "--output", install_abs
    }
    if rid and target:is_binary() then
        table.join2(argv, {"--runtime", rid})
    end
    csharp_common.append_target_flags(target, argv)

    local runopt = csharp_common.get_dotnet_runopt(csprojfile)
    if os.vrunv then
        os.vrunv(dotnet, argv, runopt)
    elseif os.runv then
        os.runv(dotnet, argv, runopt)
    elseif os.execv then
        os.execv(dotnet, argv, runopt)
    elseif os.vrun then
        local cmd = _q(dotnet)
        for _, arg in ipairs(argv) do
            cmd = cmd .. " " .. _q(arg)
        end
        os.vrun(cmd, runopt)
    elseif os.run then
        local cmd = _q(dotnet)
        for _, arg in ipairs(argv) do
            cmd = cmd .. " " .. _q(arg)
        end
        os.run(cmd, runopt)
    else
        local targetdir = target:targetdir()
        if targetdir and os.isdir(targetdir) then
            os.cp(path.join(targetdir, "**"), install_abs, {rootdir = targetdir})
        end
    end

    if target:is_binary() then
        local targetdir = target:targetdir()
        if targetdir and os.isdir(targetdir) then
            os.cp(path.join(targetdir, "**"), install_abs, {rootdir = targetdir})
        end
    end
end
