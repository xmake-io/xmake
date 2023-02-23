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
-- @file        url_filename.lua
--

-- get raw filename
function raw_filename(url)
    local urlpath = url:split('?', {plain = true})[1]
    return path.filename(urlpath)
end

-- get filename from github name mangling
function github_filename(url)
    local reponame = url:match("^https://github.com/[^/]-/([^/]-)/archive/")
    if reponame then
        local filename = raw_filename(url)
        if filename:find("^v%d") then
            filename = filename:match("^v(.+)")
        end
        return reponame .. "-" .. filename
    end
end

-- get filename from url
function main(url)
    return raw_filename(url)
end
