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
        -- os.exists will return false if symlink -> not found, but we need still remove this symlink
        if os.exists(filedir) or os.islink(filedir) then
            -- we cannot use os.tryrm, because we need raise exception if remove failed with `uninstall --admin`
            os.rm(filedir, {emptydirs = option.get("all") or opt.emptydir})
        end
    end
end
