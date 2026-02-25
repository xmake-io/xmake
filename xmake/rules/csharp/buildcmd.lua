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
-- @file        buildcmd.lua
--

import("csharp_common")

function main(target, batchcmds, opt)
    local csprojfile = assert(csharp_common.find_csproj(target), "target(%s): missing csharp .csproj file!", target:name())
    local dotnet = csharp_common.get_dotnet_program(target)
    local configuration = csharp_common.build_mode_to_configuration()
    local verbosity = csharp_common.get_dotnet_verbosity()
    local command = target:is_binary() and "publish" or "build"
    local argv = {
        command, csprojfile,
        "--nologo",
        "--configuration", configuration,
        "--verbosity", verbosity
    }

    local targetdir = target:targetdir()
    local targetdirabs
    if targetdir then
        targetdirabs = path.is_absolute(targetdir) and targetdir or path.absolute(targetdir, os.projectdir())
        table.join2(argv, {"--output", targetdirabs})
    end

    local rid = csharp_common.get_runtime_identifier(target)
    if rid and target:is_binary() then
        table.join2(argv, {"--runtime", rid})
    end
    csharp_common.append_target_flags(target, argv)

    batchcmds:show_progress(opt.progress, "${color.build.target}building.csharp.$(mode) %s", target:name())
    if targetdirabs then
        batchcmds:mkdir(targetdirabs)
    end
    batchcmds:vrunv(dotnet, argv, csharp_common.get_dotnet_runopt(csprojfile))

    local targetfile = target:targetfile()
    if targetfile then
        local sourcefiles = target:sourcefiles()
        batchcmds:add_depfiles(sourcefiles)
        batchcmds:set_depmtime(os.mtime(targetfile))
        batchcmds:set_depcache(target:dependfile(targetfile))
    end
end
