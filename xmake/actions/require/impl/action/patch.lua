--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        patch.lua
--

-- imports
import("lib.detect.find_tool")
import("core.base.option")
import("net.http")

-- download patch file
function _dowload_patch_file(package, patch_url, patch_hash)
        
    -- get the patch file
    local patch_file = path.join(os.tmpdir(), "patches", package:name(), package:version_str(), path.filename(patch_url))

    -- the package file have been downloaded?
    local cached = true
    if option.get("force") or not os.isfile(patch_file) or patch_hash ~= hash.sha256(patch_file) then

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
        if patch_hash and patch_hash ~= hash.sha256(patch_file) then
            raise("patch(%s): unmatched checksum!", patch_url)
        end
    end
    return patch_file
end

-- apply patch file
function _apply_patch_file(package, patch, patch_file)
    os.vrunv(patch.program, {"-p1", "-t", "-i", patch_file})
end

-- do patch
function _patch(package, patch, patch_url, patch_hash)

    -- trace
    vprint("patching %s to %s-%s ..", patch_url, package:name(), package:version_str())

    -- download the patch file
    local patch_file = _dowload_patch_file(package, patch_url, patch_hash)

    -- apply the patch file
    _apply_patch_file(package, patch, patch_file)
end

-- patch the given package
function main(package)

    -- no patches?
    local patches = package:patches()
    if not patches then
        return
    end

    -- find patch tool
    local patch = assert(find_tool("patch"), "patch not found!")

    -- do all patches
    for _, patchinfo in ipairs(patches) do
        _patch(package, patch, patchinfo[1], patchinfo[2])
    end
end
