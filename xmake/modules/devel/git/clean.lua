--!The Make-like Build Utility based on Lua
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
-- @file        clean.lua
--

-- imports
import("core.base.option")
import("detect.tools.find_git")

-- clean files
--
-- @param opt   the argument options
--
-- @code
--
-- import("devel.git")
-- 
-- git.clean()
-- git.clean({repodir = "/tmp/xmake", force = true})
--
-- @endcode
--
function main(opt)

    -- find git
    local program = find_git()
    if not program then
        return 
    end

    -- init argv
    local argv = {"clean", "-d"}

    -- verbose?
    if not option.get("verbose") then
        table.insert(argv, "-q")
    end

    -- force?
    if opt.force then
        table.insert(argv, "-f")
    end

    -- enter repository directory
    local oldir = nil
    if opt.repodir then
        oldir = os.cd(opt.repodir)
    end

    -- clean it
    os.vrunv(program, argv)

    -- leave repository directory
    if oldir then
        os.cd(oldir)
    end
end
