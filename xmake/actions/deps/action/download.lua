--!The Make-like download Utility based on Lua
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
import("core.tool.git")
import("core.tool.downloader")

-- checkout codes from git
function _checkout(package, url)

    -- TODO
    -- cache checkouted files
        
    -- from branches?
    if package:verfrom() == "branches" then

        -- only shadow clone this branch 
        git.clone(url, {verbose = option.get("verbose"), depth = 1, branch = package:version(), outputdir = "source"})

    -- from tags or versions?
    else

        -- clone whole history and tags
        git.clone(url, {verbose = option.get("verbose"), outputdir = "source"})

        -- attempt to checkout the given version
        git.checkout(package:version(), {verbose = option.get("verbose"), repodir = "source"})
    end
end

-- download codes from ftp/http/https
function _download(package, url)

    -- TODO
    -- cache downloaded file
        
    -- get package file
    local packagefile = path.filename(url)

    -- download package file
    downloader.download(url, packagefile, {verbose = option.get("verbose")})

    -- extract package file
    -- TODO
end

-- download the given package
function main(package)

    -- get url
    local url = package:filter():handle(package:get("url"))

    -- trace
    print("downloading %s-%s: %s ..", package:name(), package:version(), url)

    -- download package using git?
    if git.checkurl(url) then
        _checkout(package, url)
    else
        _download(package, url)
    end
end

