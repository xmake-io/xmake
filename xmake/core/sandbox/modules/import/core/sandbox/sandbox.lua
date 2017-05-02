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
-- @file        sandbox.lua
--

-- define module
local sandbox_core_sandbox = sandbox_core_sandbox or {}

-- load modules
local sandbox   = require("sandbox/sandbox")
local raise     = require("sandbox/modules/raise")

-- enter interactive mode
function sandbox_core_sandbox.interactive()

    -- get the current sandbox instance
    local instance = sandbox.instance()
    if not instance then
        raise("cannot get sandbox instance!")
    end

    -- fork a new sandbox 
    instance, errors = instance:fork()
    if not instance then
        raise(errors)
    end

    -- bind sandbox environment
--    setfenv(0, instance._PUBLIC)

    -- enter interactive mode with this new sandbox
    sandbox.interactive(instance._PUBLIC) 
end

-- return module
return sandbox_core_sandbox
