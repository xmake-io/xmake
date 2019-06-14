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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        download.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- download url using curl
function _curl_download(tool, url, outputfile)

    -- set basic arguments
    local argv = {}
    if option.get("verbose") then
        table.insert(argv, "-SL")
    else
        table.insert(argv, "-fsSL")
    end

    -- set user-agent
    local user_agent = os.user_agent()
    if user_agent then
        if tool.version then
            user_agent = user_agent .. " curl/" .. tool.version
        end
        table.insert(argv, "-A")
        table.insert(argv, user_agent)
    end

    -- set url
    table.insert(argv, url)

    -- ensure output directory
    local outputdir = path.directory(outputfile)
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- set outputfile
    table.insert(argv, "-o")
    table.insert(argv, outputfile)

    -- download it
    os.vrunv(tool.program, argv)
end

-- download url using wget
function _wget_download(tool, url, outputfile)

    -- ensure output directory
    local argv = {url}
    local outputdir = path.directory(outputfile)
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- set user-agent
    local user_agent = os.user_agent()
    if user_agent then
        if tool.version then
            user_agent = user_agent .. " wget/" .. tool.version
        end
        table.insert(argv, "-U")
        table.insert(argv, user_agent)
    end

    -- set outputfile
    table.insert(argv, "-O")
    table.insert(argv, outputfile)

    -- download it
    os.vrunv(tool.program, argv)
end

-- download url
--
-- @param url           the input url
-- @param outputfile    the output file
--
--
function main(url, outputfile)

    -- init output file
    outputfile = outputfile or path.filename(url):gsub("%?.+$", "")
    
    -- attempt to download url using curl first
    local tool = find_tool("curl", {version = true})
    if tool then
        return _curl_download(tool, url, outputfile)
    end

    -- download url using wget
    tool = find_tool("wget", {version = true})
    if tool then
        return _wget_download(tool, url, outputfile)
    end
end
