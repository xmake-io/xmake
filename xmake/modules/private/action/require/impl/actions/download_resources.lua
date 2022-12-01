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
-- @file        download_resources.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.package.package", {alias = "core_package"})
import("lib.detect.find_file")
import("lib.detect.find_directory")
import("net.http")
import("net.proxy")
import("devel.git")
import("utils.archive")

-- checkout resources
function _checkout(package, resource_name, resource_url, resource_revision)

    -- trace
    resource_url = proxy.mirror(resource_url) or resource_url
    vprint("cloning resource(%s: %s) to %s-%s ..", resource_name, resource_revision, package:name(), package:version_str())

    -- get the resource directory
    local resourcedir = assert(package:resourcefile(resource_name), "invalid resource directory!")

    -- use previous resource directory if exists
    if os.isdir(resourcedir) and not option.get("force") then
        -- clean the previous build files
        git.clean({repodir = resourcedir, force = true, all = true})
        -- reset the previous modified files
        git.reset({repodir = resourcedir, hard = true})
        if os.isfile(path.join(resourcedir, ".gitmodules")) then
            git.submodule.clean({repodir = resourcedir, force = true, all = true})
            git.submodule.reset({repodir = resourcedir, hard = true})
        end
        return
    end

    -- we can use local package from the search directories directly if network is too slow
    local localdir = find_directory(path.filename(resourcedir), core_package.searchdirs())
    if localdir and os.isdir(localdir) then
        git.clean({repodir = localdir, force = true, all = true})
        git.reset({repodir = localdir, hard = true})
        if os.isfile(path.join(localdir, ".gitmodules")) then
            git.submodule.clean({repodir = localdir, force = true, all = true})
            git.submodule.reset({repodir = localdir, hard = true})
        end
        os.cp(localdir, resourcedir)
        return
    end

    -- remove temporary directory
    os.rm(resourcedir)

    -- we need enable longpaths on windows
    local longpaths = package:policy("platform.longpaths")

    -- clone whole history and tags
    git.clone(resource_url, {longpaths = longpaths, outputdir = resourcedir})

    -- attempt to checkout the given version
    git.checkout(resource_revision, {repodir = resourcedir})

    -- update all submodules
    if os.isfile(path.join(resourcedir, ".gitmodules")) then
        git.submodule.update({init = true, recursive = true, longpaths = longpaths, repodir = resourcedir})
    end
end

-- download resources
function _download(package, resource_name, resource_url, resource_hash)

    -- trace
    resource_url = proxy.mirror(resource_url) or resource_url
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
            http.download(resource_url, resource_file, {insecure = global.get("insecure-ssl")})
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
        raise("cannot extract %s", resource_file)
    end
end

-- download all resources of the given package
function main(package)

    -- we need not download it if we use the precompiled artifacts to install package
    if package:is_precompiled() then
        return
    end

    -- no resources?
    local resources = package:resources()
    if not resources then
        return
    end

    -- download all resources
    for name, resourceinfo in pairs(resources) do
        if git.checkurl(resourceinfo.url) then
            _checkout(package, name, resourceinfo.url, resourceinfo.sha256)
        else
            _download(package, name, resourceinfo.url, resourceinfo.sha256)
        end
    end
end
