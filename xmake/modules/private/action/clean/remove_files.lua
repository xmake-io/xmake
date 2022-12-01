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
-- @file        remove_files.lua
--

-- imports
import("core.base.option")

-- remove the given files or (empty) directories
function main(filedirs, opt)
    opt = opt or {}
    for _, filedir in ipairs(filedirs) do
        os.tryrm(filedir)
        if option.get("all") or opt.emptydir then
            -- remove it if the parent directory is empty
            local parentdir = path.directory(filedir)
            while parentdir and os.isdir(parentdir) and os.emptydir(parentdir) do
                os.tryrm(parentdir)
                parentdir = path.directory(parentdir)
            end
        end
    end
end
