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
-- @file        download_resources.lua
--

-- imports
import("core.base.option")
import("core.package.package", {alias = "core_package"})
import("lib.detect.find_file")
import("net.http")
import("utils.archive")

-- download resources
function _download(package, resource_name, resource_url, resource_hash)

    -- trace
    vprint("downloading resource(%s: %s) to %s-%s ..", resource_name, resource_url, package:name(), package:version_str())

    -- get the resource file
    local resource_file = assert(package:resourcefile(resource_name), "invalid resource file!")

    -- ensure lower hash
    if resource_hash then
        resource_hash = resource_hash:lower()
    end

    -- the package file have been downloaded?
    local cached = true
    if option.get("force") or not os.isfile(resource_file) or resource_hash ~= hash.sha256(resource_file) then

        -- no cached
        cached = false

        -- attempt to remove the previous file first
        os.tryrm(resource_file)

        -- download or copy the resource file
        local localfile = find_file(path.filename(resource_file), core_package.searchdirs())
        if localfile and os.isfile(localfile) then
            -- we can use local resource from the search directories directly if network is too slow
            os.cp(localfile, resource_file)
        elseif resource_url:find(string.ipattern("https-://")) or resource_url:find(string.ipattern("ftps-://")) then
            http.download(resource_url, resource_file)
        else
            raise("invalid resource url(%s)", resource_url)
        end

        -- check hash
        if resource_hash and resource_hash ~= hash.sha256(resource_file) then
            raise("resource(%s): unmatched checksum!", resource_url)
        end
    end

    -- extract the resource file
    local resourcedir = package:resourcedir(resource_name)
    local resourcedir_tmp = resourcedir .. ".tmp"
    os.tryrm(resourcedir_tmp)
    if archive.extract(resource_file, resourcedir_tmp) then
        os.tryrm(resourcedir)
        os.mv(resourcedir_tmp, resourcedir)
    else
        os.tryrm(resourcedir_tmp)
    end
end

-- download all resources of the given package
function main(package)

    -- no resources?
    local resources = package:resources()
    if not resources then
        return
    end

    -- download all resources
    for name, resourceinfo in pairs(resources) do
        -- we use wrap to support urls table and only get the first url now
        -- TODO maybe we will download resource from the multiple urls in the future
        _download(package, name, table.wrap(resourceinfo.url)[1], resourceinfo.sha256)
    end
end
