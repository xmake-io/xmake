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
-- @file        patch_sources.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("net.http")
import("net.proxy")
import("devel.git")
import("utils.archive")

-- check sha256
function _check_sha256(patch_hash, patch_file)
    local ok = (patch_hash == hash.sha256(patch_file))
    if not ok then
        -- `git pull` maybe will replace lf to crlf in the patch text automatically on windows.
        -- so we need to attempt to fix this sha256
        --
        -- @see
        -- https://github.com/xmake-io/xmake-repo/pull/67
        -- https://stackoverflow.com/questions/1967370/git-replacing-lf-with-crlf
        --
        local tmpfile = os.tmpfile(patch_file)
        os.cp(patch_file, tmpfile)
        local content = io.readfile(tmpfile, {encoding = "binary"})
        content = content:gsub('\r\n', '\n')
        io.writefile(tmpfile, content, {encoding = "binary"})
        ok = (patch_hash == hash.sha256(tmpfile))
        os.rm(tmpfile)
    end
    return ok
end

-- do patch
function _patch(package, patchinfo)
    local patch_url = patchinfo.url
    local patch_hash = patchinfo.sha256
    local patch_extra = patchinfo.extra or {}

    -- trace
    patch_url = proxy.mirror(patch_url) or patch_url
    vprint("patching %s to %s-%s ..", patch_url, package:name(), package:version_str())

    -- get the patch file
    local patch_file = path.join(os.tmpdir(), "patches", package:name(), package:version_str(), (path.filename(patch_url):gsub("%?.+$", "")))

    -- ensure lower hash
    if patch_hash then
        patch_hash = patch_hash:lower()
    end

    -- the package file have been downloaded?
    local cached = true
    if not os.isfile(patch_file) or not _check_sha256(patch_hash, patch_file) then

        -- no cached
        cached = false

        -- attempt to remove the previous file first
        os.tryrm(patch_file)

        -- download the patch file
        if patch_url:find(string.ipattern("https-://")) or patch_url:find(string.ipattern("ftps-://")) then
            http.download(patch_url, patch_file, {
                insecure = global.get("insecure-ssl"),
                headers = package:policy("package.download.http_headers")})
        else
            -- copy the patch file
            if os.isfile(patch_url) then
                os.cp(patch_url, patch_file)
            else
                local scriptdir = package:scriptdir()
                if scriptdir and os.isfile(path.join(scriptdir, patch_url)) then
                    os.cp(path.join(scriptdir, patch_url), patch_file)
                else
                    raise("patch(%s): not found!", patch_url)
                end
            end
        end

        -- check hash
        if patch_hash and not _check_sha256(patch_hash, patch_file) then
            raise("patch(%s): unmatched checksum!", patch_url)
        end
    end

    -- is archive file? we need extract it first
    local extension = archive.extension(patch_file)
    if extension and #extension > 0 then
        local patchdir = patch_file .. ".dir"
        local patchdir_tmp = patchdir .. ".tmp"
        os.tryrm(patchdir_tmp)
        local errors
        local ok = try {
            function() 
                archive.extract(patch_file, patchdir_tmp)
                return true 
            end,
            catch {
                function (errs)
                    if errs then
                        errors = tostring(errs)
                    end
                end
            }
        }
        if ok then
            os.tryrm(patchdir)
            os.mv(patchdir_tmp, patchdir)
        else
            os.tryrm(patchdir_tmp)
            os.tryrm(patchdir)
            raise(errors or string.format("cannot extract %s", patch_file))
        end

        -- apply patch files
        for _, file in ipairs(os.files(path.join(patchdir, "**"))) do
            vprint("applying patch %s", file)
            git.apply(file, {reverse = patch_extra.reverse})
        end
    else
        -- apply single plain patch file
        vprint("applying patch %s", patch_file)
        git.apply(patch_file, {reverse = patch_extra.reverse})
    end
end

-- patch the given package
function main(package)

    -- we don't need to patch it if we use the precompiled artifacts to install package
    if package:is_precompiled() then
        return
    end

    -- no patches?
    local patches = package:patches()
    if not patches then
        return
    end

    -- do all patches
    for _, patchinfo in ipairs(patches) do
        _patch(package, patchinfo)
    end
end
