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
-- @file        clean.lua
--

import("target.action.clean", {alias = "_do_clean_target"})
local csharp_common = import("csharp_common", {anonymous = true})

function main(target, opt)
    _do_clean_target(target)

    local targetfile = target:targetfile()
    if targetfile then
        os.tryrm(target:dependfile(targetfile))
    end
    os.tryrm(target:targetdir())

    -- also remove the bin/obj folders next to the .csproj file
    local csprojfile = csharp_common.find_csproj(target)
    if csprojfile then
        local csprojdir = path.directory(csprojfile)
        os.tryrm(path.join(csprojdir, "bin"))
        os.tryrm(path.join(csprojdir, "obj"))
    end
end
