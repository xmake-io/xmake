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
-- @file        installcmd.lua
--

import("csharp_common")

function main(target, batchcmds, opt)
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

    local install_abs
    local argv = {
        "publish", csprojfile,
        "--nologo",
        "--configuration", configuration,
        "--verbosity", verbosity
    }
    if install_path and #install_path > 0 then
        install_abs = path.is_absolute(install_path) and install_path or path.absolute(install_path, os.projectdir())
        table.join2(argv, {"--output", install_abs})
    end

    local rid = csharp_common.get_runtime_identifier(target)
    if rid and target:is_binary() then
        table.join2(argv, {"--runtime", rid})
    end
    csharp_common.append_target_flags(target, argv)

    batchcmds:show_progress(opt.progress, "${color.build.target}publishing.csharp.$(mode) %s", target:name())
    if install_abs then
        batchcmds:mkdir(install_abs)
    end
    batchcmds:vrunv(dotnet, argv, csharp_common.get_dotnet_runopt(csprojfile))
end
