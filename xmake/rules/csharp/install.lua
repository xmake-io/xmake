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
-- @file        install.lua
--

import("core.base.option")
import("core.project.config")
import("core.tool.compiler")
import("modules.csharp_common", {rootdir = os.scriptdir(), alias = "csharp_common"})

function main(target, opt)
    local csprojfile = assert(csharp_common.find_or_generate_csproj(target), "target(%s): missing csharp .csproj file!", target:name())

    -- get dotnet program from compiler toolchain
    local compinst = compiler.load("cs", {target = target})
    local dotnet = compinst:program()

    local configuration = csharp_common.build_mode_to_configuration()
    local verbosity = option.get("diagnosis") and "diagnostic" or "quiet"

    -- publish to a directory under target autogendir
    local tmpdir = path.join(target:autogendir(), "publish")
    os.mkdir(tmpdir)

    local rid = csharp_common.get_runtime_identifier(target)
    local argv = {
        "publish", csprojfile,
        "--nologo",
        "--configuration", configuration,
        "--verbosity", verbosity,
        "--output", tmpdir
    }
    if rid and target:is_binary() then
        table.join2(argv, {"--runtime", rid})
    end
    os.vrunv(dotnet, argv, {curdir = path.directory(csprojfile), envs = compinst:runenvs()})

    -- copy published files to installdir
    local installdir = target:installdir()
    if target:is_binary() then
        installdir = target:installdir("bin")
    elseif target:is_static() or target:is_shared() then
        installdir = target:installdir("lib")
    end
    if installdir and #installdir > 0 then
        local install_abs = path.is_absolute(installdir) and installdir or path.absolute(installdir, os.projectdir())
        os.mkdir(install_abs)
        os.cp(path.join(tmpdir, "**"), install_abs, {rootdir = tmpdir})
    end

end
