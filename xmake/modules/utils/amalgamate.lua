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
-- @file        amalgamate.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")

-- the options
local options =
{
    {'o', "outputdir", "kv",  nil, "Set the output directory."},
    {nil, "target",    "v",  nil,  "The target name."         }
}

-- generate amalgamate code
--
-- https://github.com/xmake-io/xmake/issues/1438
--
function main(...)

    -- parse arguments
    local argv = table.pack(...)
    local args = option.parse(argv, options, "Generate amalgamate code."
                                           , ""
                                           , "Usage: xmake l utils.amalgamate [options]")
end
