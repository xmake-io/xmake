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
-- @file        filesync.lua
--

-- imports
import("core.base.object")

-- define module
local filesync = filesync or object()

-- init filesync
function filesync:init(rootdir, manifest_file)
    self._ROOTDIR = rootdir
    self._MANIFEST_FILE = manifest_file
end

-- get root directory
function filesync:rootdir()
    return self._ROOTDIR
end

-- get ignore files
function filesync:ignorefiles()
    local ignorefiles = self._IGNOREFILES
    if not ignorefiles then
        ignorefiles = {}
        self:_ignorefiles_load(ignorefiles)
        self._IGNOREFILES = ignorefiles
    end
    return ignorefiles
end

-- add ignore files
function filesync:ignorefiles_add(...)
    table.join2(self:ignorefiles(), ...)
end

-- get manifest
function filesync:manifest()
    local manifest = self._MANIFEST
    if not manifest then
        local manifest_file = self:manifest_file()
        if manifest_file and os.isfile(manifest_file) then
            manifest = io.load(manifest_file)
        end
        manifest = manifest or {}
        self._MANIFEST = manifest
    end
    return manifest
end

-- save manifest file
function filesync:manifest_save()
    local manifest_file = self:manifest_file()
    if manifest_file then
        io.save(manifest_file, self:manifest())
    end
end

-- get manifest file
function filesync:manifest_file()
    return self._MANIFEST_FILE
end

-- do snapshot, it will re-scan all and update to manifest file
function filesync:snapshot()
    local rootdir = self:rootdir()
    assert(rootdir and os.isdir(rootdir), "get snapshot %s failed, rootdir not found!", rootdir)
    local manifest = {}
    local manifest_old = self:manifest()
    local ignorefiles = self:ignorefiles()
    if ignorefiles then
        ignorefiles = "|" .. table.concat(ignorefiles, "|")
    end
    local count = 0
    for _, filepath in ipairs(os.files(path.join(rootdir, "**" .. ignorefiles))) do
        local fileitem = path.relative(filepath, rootdir)
        if fileitem then
            -- we should always use '/' in path key for supporting linux & windows
            -- https://github.com/xmake-io/xmake/issues/2488
            if is_host("windows") then
                fileitem = fileitem:gsub("\\", "/")
            end
            local manifest_info = manifest_old[fileitem]
            local mtime = os.mtime(filepath)
            if not manifest_info or not manifest_info.mtime or mtime > manifest_info.mtime then
                manifest[fileitem] = {sha256 = hash.sha256(filepath), mtime = mtime}
            else
                manifest[fileitem] = manifest_info
            end
            count = count + 1
        end
    end
    self._MANIFEST = manifest
    self:manifest_save()
    return manifest, count
end

-- update file
function filesync:update(fileitem, filepath, sha256)
    local mtime = os.mtime(filepath)
    local manifest = self:manifest()
    sha256 = sha256 or hash.sha256(filepath)
    manifest[fileitem] = {sha256 = sha256, mtime = mtime}
end

-- remove file
function filesync:remove(fileitem)
    local manifest = self:manifest()
    manifest[fileitem] = nil
end

-- load ignore files from .gitignore files
function filesync:_ignorefiles_load(ignorefiles)
    local rootdir = self:rootdir()
    local gitignore_files = os.files(path.join(rootdir, "**", ".gitignore"))
    if os.isfile(path.join(rootdir, ".gitignore")) then
        table.insert(gitignore_files, path.join(rootdir, ".gitignore"))
    end
    for _, gitignore_file in ipairs(gitignore_files) do
        local gitroot = path.directory(gitignore_file)
        local gitignore = io.open(gitignore_file, "r")
        for line in gitignore:lines() do
            line = line:trim()
            if #line > 0 and not line:startswith("#") then
                local filepath = path.join(gitroot, line)
                local pattern = path.relative(filepath, rootdir)
                if pattern then
                    if line:endswith(path.sep()) or os.isdir(line) then
                        table.insert(ignorefiles, path.join(pattern, "**"))
                    elseif os.isfile(line) then
                        table.insert(ignorefiles, pattern)
                    elseif line:find("*.", 1, true) then
                        table.insert(ignorefiles, (pattern:gsub("%*%.", "**.")))
                    else
                        table.insert(ignorefiles, pattern)
                        table.insert(ignorefiles, path.join(pattern, "**"))
                    end
                end
            end
        end
        gitignore:close()
    end
end

function main(rootdir, manifest_file)
    local instance = filesync()
    instance:init(rootdir, manifest_file)
    return instance
end
