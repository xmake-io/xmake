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
-- @file        windbg.lua
--

-- init it
function init(shellname)

    -- save name
    _g.shellname = shellname or "windbg"

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- run the debugged program with arguments
function run(shellname, argv)

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, shellname)

    -- run it
    os.execv(_g.shellname, argv)
end

-- check the given flags 
function check(flags)
end
