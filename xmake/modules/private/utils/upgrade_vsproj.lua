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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        upgrade_vsproj.lua
--

-- imports
import("core.base.option")

-- the options
local options = {
    {nil, "vs",              "kv", nil, "Set the vs version. (default: latest)."     }
,   {nil, "vs_toolset",      "kv", nil, "Set the vs toolset."                        }
,   {nil, "vs_sdkver",       "kv", nil, "Set the vs sdk version."                    }
,   {nil, "vs_projectfiles", "vs", nil, "Set the solution or project files."         }
}

-- upgrade vs project file
function upgrade(projectfile, opt)
    opt = opt or {}
end

-- https://github.com/xmake-io/xmake/issues/3871
function main(...)
    local argv = {...}
    local opt  = option.parse(argv, options, "Upgrade all the vs project files."
                                           , ""
                                           , "Usage: xmake l private.utils.upgrade_vsproj [options]")

    for _, projectfile in ipairs(opt.vs_projectfiles) do
        upgrade(projectfile, opt)
    end
end
