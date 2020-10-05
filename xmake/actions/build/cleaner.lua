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
-- @file        cleaner.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.base.process")
import("core.project.config")
import("core.project.project")
import("core.package.package")
import("core.platform.platform")
import("core.platform.environment")

-- clean up temporary files once a day
function cleanup()

    -- has been cleaned up today?
    local markfile = path.join(os.tmpdir(), "cleanup", os.date("%y%m%d") .. ".mark")
    if os.isfile(markfile) then
        return
    end

    -- mark as posted first, avoid to post it repeatly
    io.writefile(markfile, "ok")

    -- init argument list
    local argv = {"lua", path.join(os.scriptdir(), "cleaner.lua")}
    for _, name in ipairs({"root", "file", "project", "diagnosis", "verbose", "quiet", "yes", "confirm"}) do
        local value = option.get(name)
        if type(value) == "string" then
            table.insert(argv, "--" .. name .. "=" .. value)
        elseif value then
            table.insert(argv, "--" .. name)
        end
    end

    -- try to post it in background
    try
    {
        function ()
            process.openv("xmake", argv, {stdout = path.join(os.tmpdir(), "cleaner.log")}, {detach = true}):close()
        end
    }
end

-- the main function
function main()

    -- clean up the temporary files at last 30 days, @see os.tmpdir()
    local parentdir = path.directory(os.tmpdir())
    for day = 1, 30 do
        local tmpdir = path.join(parentdir, os.date("%y%m%d", os.time() - day * 24 * 3600))
        if os.isdir(tmpdir) then
            print("cleanup %s ..", tmpdir)
            os.tryrm(tmpdir)
        end
    end

    -- clean up the temporary files of project at last 30 days, @see project.tmpdir()
    if os.isfile(os.projectfile()) then
        local parentdir = path.directory(project.tmpdir())
        for day = 1, 30 do
            local tmpdir = path.join(parentdir, os.date("%y%m%d", os.time() - day * 24 * 3600))
            if os.isdir(tmpdir) then
                print("cleanup %s ..", tmpdir)
                os.tryrm(tmpdir)
            end
        end
    end

    -- clean up the previous month package cache files, @see package.cachedir()
    local cachedir = path.join(global.directory(), "cache", "packages", os.date("%y%m", os.time() - 31 * 24 * 3600))
    if os.isdir(cachedir) and cachedir ~= package.cachedir() then
        print("cleanup %s ..", cachedir)
        os.tryrm(cachedir)
    end
end
