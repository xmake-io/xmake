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
-- @file        unzip.lua
--

-- imports
import("core.base.option")

-- init it
function init(shellname)

    -- save name
    _g.shellname = shellname or "unzip"
end

-- extract the archived file
function extract(archivefile, outputdir)

    -- check 
    assert(archivefile)

    -- init argv
    local argv = {}
    if option.get("verbose") then
        table.insert(argv, "-q")
    end
    table.insert(argv, archivefile)

    -- ensure output directory
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- init temporary directory
    local tmpdir = path.join(os.tmpdir(), hash.uuid())
    os.tryrm(tmpdir)
    os.mkdir(tmpdir)

    -- extract to tmpdir first
    table.insert(argv, "-d")
    table.insert(argv, tmpdir)

    -- unzip it
    os.vrunv(_g.shellname, argv)

    -- select the first root directory and strip it (may be discard some root files)
    for _, dir in ipairs(os.dirs(path.join(tmpdir, "*"))) do
        if path.filename(dir) ~= "__MACOSX" then
            for _, filedir in ipairs(os.filedirs(path.join(dir, "*"))) do
                local p, e = filedir:find(dir, 1, true)
                if p and e then
                    os.mv(filedir, path.join(outputdir, filedir:sub(e + 1)))
                end
            end
            break
        end
    end

    -- remove tmpdir
    os.tryrm(tmpdir)
end

-- check the given flags 
function check(flags)

    -- check it
    os.run("%s --help", _g.shellname)
end
