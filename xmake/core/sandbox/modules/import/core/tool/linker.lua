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
-- @file        linker.lua
--

-- define module
local sandbox_core_tool_linker = sandbox_core_tool_linker or {}

-- load modules
local platform  = require("platform/platform")
local linker    = require("tool/linker")
local raise     = require("sandbox/modules/raise")

-- make command for linking target file
function sandbox_core_tool_linker.linkcmd(targetkind, sourcekinds, objectfiles, targetfile, opt)
 
    -- get the linker instance
    local instance, errors = linker.load(targetkind, sourcekinds)
    if not instance then
        raise(errors)
    end

    -- make command
    return instance:linkcmd(objectfiles, targetfile, opt)
end

-- make link flags for the given target
function sandbox_core_tool_linker.linkflags(targetkind, sourcekinds, opt)

    -- get the linker instance
    local instance, errors = linker.load(targetkind, sourcekinds)
    if not instance then
        raise(errors)
    end

    -- make flags
    return instance:linkflags(opt)
end

-- link target file
function sandbox_core_tool_linker.link(targetkind, sourcekinds, objectfiles, targetfile, opt)
 
    -- get the linker instance
    local instance, errors = linker.load(targetkind, sourcekinds)
    if not instance then
        raise(errors)
    end

    -- link it
    local ok, errors = instance:link(objectfiles, targetfile, opt)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_tool_linker
