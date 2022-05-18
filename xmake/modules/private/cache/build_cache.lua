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
-- @file        build_cache.lua
--

-- imports
import("core.project.config")

-- is enabled?
function enabled()
    local build_cache = _g.build_cache
    if build_cache == nil then
        build_cache = config.get("ccache") or false
        _g.build_cache = build_cache
    end
    return build_cache or false
end

-- get cache key
function cachekey(program, cppfile, cppflags, envs)
    local items = {program}
    table.join2(items, cppflags)
    table.sort(items)
    table.insert(items, hash.sha256(cppfile))
    if envs then
        for k, v in pairs(table.orderpairs(envs)) do
            table.insert(items, k)
            table.insert(items, v)
        end
    end
    return (hash.uuid(table.concat(items, "")):gsub("-", "")):lower()
end

-- get cache root directory
function rootdir()
    return path.join(config.buildir(), ".cache")
end

-- clean cached files
function clean()
    os.rm(rootdir())
end

-- get hit rate
function hitrate()
    local hit_count = (_g.hit_count or 0)
    local total_count = (_g.total_count or 0)
    if total_count > 0 then
        return hit_count * 100 / total_count
    end
    return 0
end

-- get object file
function get(cachekey)
    _g.total_count = (_g.total_count or 0) + 1
    local objectfile_cached = path.join(rootdir(), cachekey:sub(1, 2):lower(), cachekey)
    if os.isfile(objectfile_cached) then
        _g.hit_count = (_g.hit_count or 0) + 1
        return objectfile_cached
    end
end

-- put object file
function put(cachekey, objectfile)
    local objectfile_cached = path.join(rootdir(), cachekey:sub(1, 2):lower(), cachekey)
    os.cp(objectfile, objectfile_cached)
end
