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
-- @file        unlink.lua
--

-- imports
import("core.base.task")
import("core.base.option")
import("impl.package")
import("impl.repository")
import("impl.environment")

-- show the given package info
function main(requires)

    -- no requires?
    if not requires then
        return 
    end

    -- enter environment 
    environment.enter()

    -- pull all repositories first if not exists
    if not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- get extra info
    local extra =  option.get("extra")
    local extrainfo = nil
    if extra then
        local tmpfile = os.tmpfile() .. ".lua"
        io.writefile(tmpfile, "{" .. extra .. "}")
        extrainfo = io.load(tmpfile)
        os.tryrm(tmpfile)
    end

    -- init requires extra info
    local requires_extra = {}
    if extrainfo then
        for _, require_str in ipairs(requires) do
            requires_extra[require_str] = extrainfo
        end
    end

    -- unlink packages
    local packages = package.unlink_packages(requires, {requires_extra = requires_extra})
    for _, instance in ipairs(packages) do
        print("unlink: %s%s ok!", instance:name(), instance:version_str() and ("-" .. instance:version_str()) or "")
    end

    -- leave environment
    environment.leave()
end

