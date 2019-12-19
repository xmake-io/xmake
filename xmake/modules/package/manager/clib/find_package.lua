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
-- @author      Adel Vilkov (aka RaZeR-RBI)
-- @file        find_package.lua
--

-- imports
import("core.base.option")
import("core.project.config")

function main(name, opt)
    -- check if a package marker file with install directory exists
    local cache_dir = path.join(config.directory(), "clib", "cache", "packages")
    local marker_filename = string.gsub(name, "%/", "=")
    local marker_path = path.join(cache_dir, marker_filename)
    dprint("looking for marker file for %s at %s", name, marker_path)

    if not os.isfile(marker_path) then
        dprint("no marker file found for %s", name)
        return
    end

    dprint("found marker file for %s", name)
    return io.load(marker_path)
end
