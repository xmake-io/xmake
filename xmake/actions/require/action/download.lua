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
import("core.tool.unarchiver")
import("core.tool.downloader")

-- checkout codes from git
function _checkout(package, url)

    -- trace
    cprintf("${yellow}  => ${clear}cloning %s %s .. ", url, package:version())
    if option.get("verbose") then
        print("")
    end

    -- attempt to remove source directory first
    os.tryrm("source")

    -- create a clone task
    local task = function ()

        -- from branches?
        if package:verfrom() == "branches" then

            -- only shadow clone this branch 
            git.clone(url, {depth = 1, branch = package:version(), outputdir = "source"})

        -- from tags or versions?
        else

            -- clone whole history and tags
            git.clone(url, {outputdir = "source"})

            -- attempt to checkout the given version
            git.checkout(package:version(), {repodir = "source"})
        end
    end

    -- download package file
    if option.get("verbose") then
        task()
    else
        process.asyncrun(task)
    end

    -- trace
    cprint("${green}ok")
end

-- download codes from ftp/http/https
function _download(package, url)

    -- trace
    cprintf("${yellow}  => ${clear}downloading %s .. ", url)
    if option.get("verbose") then
        print("")
    end

    -- get package file
    local packagefile = path.filename(url)

    -- the package file have been downloaded?
    local sha256 = package:sha256()
    if option.get("force") or not os.isfile(packagefile) or (sha256 and sha256 ~= hash.sha256(packagefile)) then

        -- attempt to remove package file first
        os.tryrm(packagefile)

        -- create a download task
        local task = function ()
            downloader.download(url, packagefile)
        end

        -- download package file
        if option.get("verbose") then
            task()
        else
            process.asyncrun(task)
        end

        -- check hash
        if sha256 and sha256 ~= hash.sha256(packagefile) then
            raise("unmatched checksum!")
        end
    end

    -- attempt to remove source directory first
    os.tryrm("source")

    -- extract package file
    unarchiver.extract(packagefile, "source")
    
    -- trace
    cprint("${green}ok")
end

-- download the given package
function main(package)

    -- download package from url or mirror
    local urls = package:urls()
    for idx, url in ipairs(urls) do

        -- filter url
        url = package:filter():handle(url)

        -- download url
        local ok = try
        {
            function ()

                -- download package 
                if git.checkurl(url) then
                    _checkout(package, url)
                else
                    _download(package, url)
                end

                -- ok
                return true
            end,
            catch 
            {
                function (errors)

                    -- verbose?
                    if option.get("verbose") and errors then
                        cprint("${bright red}error: ${clear}%s", errors)
                    end

                    -- trace
                    cprint("${red}failed")

                    -- failed? break it
                    if idx == #urls then
                        raise("download failed!")
                    end
                end
            }
        }

        -- ok? break it
        if ok then break end
    end
end

