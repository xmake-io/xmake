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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        vs.lua
--

-- imports
import("impl.vs200x")
import("impl.vs201x")
import("impl.vsinfo")
import("core.project.config")

-- make factory
function make(version)

    if not version then
        version = tonumber(config.get("vs"))
        if not version then
            return function(outputdir)
                raise("invalid vs version, run `xmake f --vs=201x`")
            end
        end
    end

    -- get vs version info
    local info = vsinfo(version)
    if version < 2010 then
        return function(outputdir)
            vprint("using project kind vs%d", version)
            vs200x.make(outputdir, info)
        end
    else
        return function(outputdir)
            utils.warning("please use the new vs project generator, .e.g xmake project -k vsxmake")
            vprint("using project kind vs%d", version)
            vs201x.make(outputdir, info)
        end
    end
end
