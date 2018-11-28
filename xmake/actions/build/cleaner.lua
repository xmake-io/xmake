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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        cleaner.lua
--

-- imports
import("core.base.option")
import("core.project.config")
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
    for _, name in ipairs({"root", "file", "project", "diagnosis", "verbose", "quiet", "yes"}) do
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
            local proc = process.openv("xmake", argv, path.join(os.tmpdir(), "cleaner.log"))
            if proc ~= nil then
                process.close(proc)
            end
        end
    }
end

-- the main function
function main()

    -- clean up the temporary files at last 30 days
    local parentdir = path.directory(os.tmpdir())
    for day = 1, 30 do
        local tmpdir = path.join(parentdir, os.date("%y%m%d", os.time() - day * 24 * 3600))
        if os.isdir(tmpdir) then
            print("cleanup %s ..", tmpdir)
            os.tryrm(tmpdir)
        end
    end
end
