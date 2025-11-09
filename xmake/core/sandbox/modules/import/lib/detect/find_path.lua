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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        find_path.lua
--

-- define module
local sandbox_lib_detect_find_path = sandbox_lib_detect_find_path or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local profiler  = require("base/profiler")
local raise     = require("sandbox/modules/raise")
local vformat   = require("sandbox/modules/vformat")
local xmake     = require("base/xmake")

-- expand search paths
function sandbox_lib_detect_find_path._expand_paths(paths)
    local results = {}
    for _, _path in ipairs(table.wrap(paths)) do
        if type(_path) == "function" then
            local ok, result_or_errors = sandbox.load(_path)
            if ok then
                _path = result_or_errors or ""
            else
                raise(result_or_errors)
            end
        else
            _path = vformat(_path)
        end
        for _, _s_path in ipairs(table.wrap(_path)) do
            _s_path = tostring(_s_path)
            if #_s_path > 0 then
                table.insert(results, _s_path)
            end
        end
    end
    return results
end

-- normalize suffixes
function sandbox_lib_detect_find_path._normalize_suffixes(suffixes)
    local results = {}
    for _, suffix in ipairs(table.wrap(suffixes)) do
        suffix = tostring(suffix)
        if #suffix > 0 then
            table.insert(results, suffix)
        end
    end
    return results
end

-- find the given file path or directory
function sandbox_lib_detect_find_path._find(filedir, name)

    -- find the first path
    local results = os.filedirs(path.join(filedir, name), function (file, isdir) return false end)
    if results and #results > 0 then
        local filepath = results[1]
        if filepath then
            -- we need to translate name first, https://github.com/xmake-io/xmake-repo/issues/1315
	    local p = filepath:lastof(path.pattern(path.translate(name)))
            if p then
                filepath = path.translate(filepath:sub(1, p - 1))
                if os.isdir(filepath) then
                    return filepath
                else
                    return path.directory(filepath)
                end
            end
        end

    end
end

-- find from directories list
function sandbox_lib_detect_find_path._find_from_directories(name, directories, suffixes)
    local results
    suffixes = table.wrap(suffixes)
    directories = table.wrap(directories)
    if #suffixes > 0 then
        for _, directory in ipairs(directories) do
            for _, suffix in ipairs(suffixes) do
                local filedir = path.join(directory, suffix)
                results = sandbox_lib_detect_find_path._find(filedir, name)
                if results then
                    return results
                end
            end
        end
    else
        for _, directory in ipairs(directories) do
            results = sandbox_lib_detect_find_path._find(directory, name)
            if results then
                return results
            end
        end
    end
end

-- find path
--
-- @param name      the path name
-- @param paths     the search paths (e.g. dirs, paths, winreg paths)
-- @param opt       the options, e.g. {suffixes = {"/aa", "/bb"}}
--
-- @return          the path
--
-- @code
--
-- local p = find_path("include/test.h", { "/usr", "/usr/local"})
--  -> /usr/local ("/usr/local/include/test.h")
--
-- local p = find_path("include/*.h", { "/usr", "/usr/local/**"})
-- local p = find_path("lib/xxx", { "$(env PATH)", "$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\XXXX;Name)"})
-- local p = find_path("lib/xxx", { "$(env PATH)", function () return val("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\XXXX;Name"):match("\"(.-)\"") end})
--
-- @endcode
--
function sandbox_lib_detect_find_path.main(name, paths, opt)

    -- init options
    opt = opt or {}

    profiler:enter("find_path", name)
    local suffixes = sandbox_lib_detect_find_path._normalize_suffixes(opt.suffixes)
    local directories = sandbox_lib_detect_find_path._expand_paths(paths)

    if opt.async and xmake.in_main_thread() then
        local result, _ = os._async_task().find_path(name, directories, {suffixes = suffixes})
        profiler:leave("find_path", name)
        return result
    end

    local results = sandbox_lib_detect_find_path._find_from_directories(name, directories, suffixes)
    profiler:leave("find_path", name)
    return results
end

-- return module
return sandbox_lib_detect_find_path
