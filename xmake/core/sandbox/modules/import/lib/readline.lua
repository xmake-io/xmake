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
-- @author      TitanSnow
-- @file        readline.lua
--

local sandbox_readline = sandbox_readline or {}

-- check feature readline
if not os.versioninfo().features.readline then
    os.raise("readline not included")
end

-- inherit some builtin interfaces
sandbox_readline.readline = readline.readline
sandbox_readline.get_history_state = readline.get_history_state
sandbox_readline.add_history = readline.add_history
sandbox_readline.clear_history = readline.clear_history

-- return module
return sandbox_readline
