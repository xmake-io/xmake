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
import("net.http")
import("devel.git")
import("utils.archive")

-- empty chars
function _emptychars()
    return "                               "
end

-- checkout codes from git
function _checkout(package, url, sourcedir)

    -- use previous source directory if exists
    local packagedir = path.join(sourcedir, package:name())
    if os.isdir(packagedir) and not option.get("force") then

        -- clean the previous build files
        git.clean({repodir = packagedir, force = true})
        return 
    end

    -- remove temporary directory
    os.rm(sourcedir .. ".tmp")

    -- download package from branches?
    packagedir = path.join(sourcedir .. ".tmp", package:name())
    if package:version_from("branches") then

        -- only shadow clone this branch 
        git.clone(url, {depth = 1, branch = package:version_str(), outputdir = packagedir})

    -- download package from tags or versions?
    else

        -- clone whole history and tags
        git.clone(url, {outputdir = packagedir})

        -- attempt to checkout the given version
        git.checkout(package:version_str(), {repodir = packagedir})
    end
 
    -- move to source directory
    os.rm(sourcedir)
    os.mv(sourcedir .. ".tmp", sourcedir)

    -- trace
    cprint("\r${yellow}  => ${clear}clone %s %s .. ${green}ok%s", url, package:version_str(), _emptychars())
end

-- download codes from ftp/http/https
function _download(package, url, sourcedir)

    -- get package file
    local packagefile = path.filename(url)

    -- the package file have been downloaded?
    local sha256 = package:sha256()
    if option.get("force") or not os.isfile(packagefile) or (sha256 and sha256 ~= hash.sha256(packagefile)) then

        -- attempt to remove package file first
        os.rm(packagefile)

        -- download package file
        http.download(url, packagefile)

        -- check hash
        if sha256 and sha256 ~= hash.sha256(packagefile) then
            raise("unmatched checksum!")
        end
    end

    -- extract package file
    os.rm(sourcedir .. ".tmp")
    archive.extract(packagefile, sourcedir .. ".tmp")
    
    -- move to source directory
    os.rm(sourcedir)
    os.mv(sourcedir .. ".tmp", sourcedir)

    -- trace
    cprint("\r${yellow}  => ${clear}download %s .. ${green}ok%s", url, _emptychars())
end

-- get sorted urls
function _urls(package)

    -- sort urls from the version source
    local urls = {{}, {}}
    for _, url in ipairs(package:urls()) do
        if git.checkurl(url) then
            table.insert(urls[1], url)
        else
            table.insert(urls[2], url)
        end
    end
    if package:version_from("tags", "branches") then
        return table.join(urls[1], urls[2]) 
    else
        return table.join(urls[2], urls[1])
    end
end

-- download the given package
function main(package)

    -- skip phony package without urls
    if #package:urls() == 0 then
        return
    end

    -- get working directory of this package
    local workdir = package:cachedir()

    -- ensure the working directory first
    os.mkdir(workdir)

    -- enter the working directory
    local oldir = os.cd(workdir)

    -- download package from urls
    local urls = _urls(package)
    for idx, url in ipairs(urls) do

        -- filter url
        url = package:filter():handle(url)

        -- download url
        local ok = try
        {
            function ()

                -- download package 
                local sourcedir = "source"
                if git.checkurl(url) then
                    _checkout(package, url, sourcedir)
                else
                    _download(package, url, sourcedir)
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
                    if git.checkurl(url) then
                        cprint("\r${yellow}  => ${clear}clone %s %s .. ${red}failed%s", url, package:version_str(), _emptychars())
                    else
                        cprint("\r${yellow}  => ${clear}download %s .. ${red}failed%s", url, _emptychars())
                    end

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

    -- leave working directory
    os.cd(oldir)
end


