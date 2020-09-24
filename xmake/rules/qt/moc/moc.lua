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
-- @file        moc.lua
--

-- make flags from target
function _make_flags_from_target(target)
    local flags = {}
    for _, define in ipairs(target:get("defines")) do
        table.insert(flags, "-D" .. define)
    end
    for _, includedir in ipairs(target:get("includedirs")) do
        table.insert(flags, "-I" .. os.args(includedir))
    end
    for _, frameworkdir in ipairs(target:get("frameworkdirs")) do
        table.insert(flags, "-F" .. os.args(frameworkdir))
    end
    return flags
end

-- make flags
function _make_flags(target)

    -- attempt to get flags from cache first
    local key = target:name()
    local cache = _g._FLAGS or {}
    if cache[key] then
        return cache[key]
    end

    -- make flags
    local flags = _make_flags_from_target(target)

    -- save flags to cache
    cache[key] = flags
    _g._FLAGS = cache

    -- done
    return flags
end

-- generate c++ source file from header file with Q_OBJECT
function generate(target, headerfile_moc, sourcefile_moc)

    -- get moc
    local moc = assert(target:data("qt.moc"), "moc not found!")

    -- ensure the parent directory of source file
    local sourcefile_dir = path.directory(sourcefile_moc)
    if not os.isdir(sourcefile_dir) then
        os.mkdir(sourcefile_dir)
    end

    -- generate c++ source file for moc
    os.vrunv(moc, table.join(_make_flags(target), headerfile_moc, "-o", sourcefile_moc))
end
