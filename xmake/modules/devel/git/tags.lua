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
-- @file        tags.lua
--

-- imports
import("core.base.option")
import("ls_remote")

-- get all tags from url
--
-- @param url       the remote url, optional
--
-- @return          the tags
--
-- @code
--
-- import("devel.git")
--
-- local tags = git.tags(url)
--
-- @endcode
--
function main(url)
    return ls_remote("tags", url)
end
