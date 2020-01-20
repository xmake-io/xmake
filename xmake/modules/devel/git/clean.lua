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
-- @file        clean.lua
--

-- imports
import("main", { alias = "git" })

-- clean files
--
-- @param opt   the argument options
--
-- @code
--
-- import("devel.git")
-- 
-- git.clean()
-- git.clean({repodir = "/tmp/xmake", force = true})
--
-- @endcode
--

function main(...)

    local opt = { d = true }
    -- verbose?
    if not option.get("verbose") then
        opt.q = true
    end

    return git().clean(opt, ...)
end
