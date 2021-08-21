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
-- @file        json.lua
--

-- define module: json
local json  = json or {}
local cjson = cjson or {}

-- laod modules
local io    = require("base/io")
local utils = require("base/utils")

-- export null
json.null = cjson.null

-- decode json string to the lua table
--
-- @param jsonstr       the json string
-- @param opt           the options
--
-- @return              the lua table
--
function json.decode(jsonstr, opt)
    local ok, luatable_or_errors = utils.trycall(cjson.decode, nil, jsonstr)
    if not ok then
        return nil, string.format("decode json failed, %s", luatable_or_errors)
    end
    return luatable_or_errors
end

-- encode lua table to the json string
--
-- @param luatable      the lua table
-- @param opt           the options
--
-- @return              the json string
--
function json.encode(luatable, opt)
    local ok, jsonstr_or_errors = utils.trycall(cjson.encode, nil, luatable)
    if not ok then
        return nil, string.format("encode json failed, %s", jsonstr_or_errors)
    end
    return jsonstr_or_errors
end

-- load json file to the lua table
--
-- @param filepath      the json file path
-- @param opt           the options
--                      - encoding for io/file, e.g. utf8, utf16, utf16le, utf16be ..
--                      - continuation for io/read (concat string with the given continuation characters)
--
-- @return              the lua table
--
function json.loadfile(filepath, opt)
    local filedata, errors = io.readfile(filepath, opt)
    if not filedata then
        return nil, errors
    end
    local jsondata, other_errors = json.decode(filedata, opt)
    if not jsondata then
        return nil, other_errors .. "\nduring parsing json file \"" .. filepath .. "\"\nfile content: --[[\n" .. filedata .. "\n]]"
    end
    return jsondata
end

-- save lua table to the json file
--
-- @param filepath      the json file path
-- @param luatable      the lua table
-- @param opt           the options
--                      - encoding for io/file, e.g. utf8, utf16, utf16le, utf16be ..
--
-- @return              the json string
--
function json.savefile(filepath, luatable, opt)
    local jsonstr, errors = json.encode(luatable, opt)
    if not jsonstr then
        return false, errors
    end
    return io.writefile(filepath, jsonstr, opt)
end

-- return module: json
return json
