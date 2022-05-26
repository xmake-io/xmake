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
import("net.http")
import("net.proxy")
import("devel.git")

-- check sha256
function _check_sha256(patch_hash, patch_file)
    local ok = (patch_hash == hash.sha256(patch_file))
    if not ok and is_host("windows") then
        -- `git pull` maybe will replace lf to crlf in the patch text automatically on windows.
        -- so we need attempt to fix this sha256
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
function _patch(package, patch_url, patch_hash)

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
    if option.get("force") or not os.isfile(patch_file) or not _check_sha256(patch_hash, patch_file) then

        -- no cached
        cached = false

        -- attempt to remove the previous file first
        os.tryrm(patch_file)

        -- download the patch file
        if patch_url:find(string.ipattern("https-://")) or patch_url:find(string.ipattern("ftps-://")) then
            http.download(patch_url, patch_file)
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

    -- apply the patch file
    git.apply(patch_file)
end

-- patch the given package
function main(package)

    -- we need not patch it if we use the precompiled artifacts to install package
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
        _patch(package, patchinfo.url, patchinfo.sha256)
    end
end
