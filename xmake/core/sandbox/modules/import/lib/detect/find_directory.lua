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
-- @file        find_directory.lua
--

-- define module
local sandbox_lib_detect_find_directory = sandbox_lib_detect_find_directory or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local table     = require("base/table")
local raise     = require("sandbox/modules/raise")
local vformat   = require("sandbox/modules/vformat")

-- find directory
--
-- @param name      the directory name
-- @param paths     the search paths (e.g. dirs, paths, winreg paths)
-- @param opt       the options, e.g. {suffixes = {"/aa", "/bb"}}
--
-- @return          the directory path
--
-- @code
--
-- local dir = find_directory("bin", { "/usr", "/usr/local"})
-- local dir = find_directory("xxx/test", { "/usr/include", "/usr/local/include/**"})
-- local dir = find_directory("xxx/test", { "$(env PATH)", "$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\XXXX;Name)"})
-- local dir = find_directory("xxx/test/dir*", { "$(env PATH)", function () return val("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\XXXX;Name"):match("\"(.-)\"") end})
--
-- @endcode
--
function sandbox_lib_detect_find_directory.main(name, paths, opt)

    -- init options
    opt = opt or {}

    -- init paths
    paths = table.wrap(paths)

    -- append suffixes to paths
    local suffixes = table.wrap(opt.suffixes)
    if #suffixes > 0 then
        local paths_new = {}
        for _, parent in ipairs(paths) do
            for _, suffix in ipairs(suffixes) do
                table.insert(paths_new, path.join(parent, suffix))
            end
        end
        paths = paths_new
    end

    -- find file
    for _, _path in ipairs(paths) do

        -- format path for builtin variables
        if type(_path) == "function" then
            local ok, results = sandbox.load(_path)
            if ok then
                _path = results or ""
            else
                raise(results)
            end
        else
            _path = vformat(_path)
        end

        -- find the first directory
        local results = os.dirs(path.join(_path, name), function (file, isdir) return false end)
        if results and #results > 0 then
            return results[1]
        end
    end
end

-- return module
return sandbox_lib_detect_find_directory
