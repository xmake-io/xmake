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
-- @file        environment.lua
--

-- imports
import("core.project.config")
import("core.project.global")

-- enter the given environment
function _enter(name)

    -- get vcvarsall
    local vcvarsall = config.get("__vcvarsall") or global.get("__vcvarsall")
    if not vcvarsall then
        return 
    end

    -- get vs environment for the current arch
    local vsenv = vcvarsall[config.get("arch") or ""] or {}

    -- get the pathes for the vs environment
    local old = nil
    local new = vsenv[name]
    if new then

        -- get the current pathes
        old = os.getenv(name) or ""

        -- append the current pathes
        new = new .. ";" .. old

        -- update the pathes for the environment
        os.setenv(name, new)
    end

    -- return the previous environment
    return old
end

-- leave the given environment
function _leave(name, old)

    -- restore the previous environment
    if old then 
        os.setenv(name, old)
    end
end

-- enter the toolchains environment (vs)
function _enter_toolchains()

    _g.pathes    = _enter("path")
    _g.libs      = _enter("lib")
    _g.includes  = _enter("include")
    _g.libpathes = _enter("libpath")
end

-- leave the toolchains environment (vs)
function _leave_toolchains()

    _leave("path",      _g.pathes)
    _leave("lib",       _g.libs)
    _leave("include",   _g.includes)
    _leave("libpath",   _g.libpathes)
end

-- enter the toolchains environment (vs)
function enter(name)

    -- the maps
    local maps = {toolchains = _enter_toolchains}
    
    -- enter it
    local func = maps[name]
    if func then
        func()
    end
end

-- leave the toolchains environment (vs)
function leave(name)

    -- the maps
    local maps = {toolchains = _leave_toolchains}
    
    -- leave it
    local func = maps[name]
    if func then
        func()
    end
end
