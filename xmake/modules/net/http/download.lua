--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        download.lua
--

-- imports
import("core.base.option")
import("detect.tools.find_curl")
import("detect.tools.find_wget")

-- download url using curl
function _curl_download(program, url, outputfile)

    -- set basic arguments
    local argv = {}
    if option.get("verbose") then
        table.insert(argv, "-SL")
    else
        table.insert(argv, "-fsSL")
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

    -- clone it
    os.vrunv(program, argv)
end

-- download url using wget
function _wget_download(program, url, outputfile)

    -- ensure output directory
    local argv = {url}
    local outputdir = path.directory(outputfile)
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- set outputfile
    table.insert(argv, "-O")
    table.insert(argv, outputfile)

    -- clone it
    os.vrunv(program, argv)
end

-- download url
--
-- @param url           the input url
-- @param outputfile    the output file
--
--
function main(url, outputfile)

    -- init output file
    outputfile = outputfile or path.filename(url)
    
    -- attempt to download url using curl first
    local program = find_curl()
    if program then
        return _curl_download(program, url, outputfile)
    end

    -- download url using wget
    program = find_wget()
    if program then
        return _wget_download(program, url, outputfile)
    end
end
