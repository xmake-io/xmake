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
-- @file        has_flag.lua
--

-- imports
import("lib.detect.cache")

-- attempt to check it from the argument list 
function _check_from_arglist(flag, opt)

    -- make cache key
    local key = "detect.tools.ar.has_flag"

    -- make flags key
    local flagskey = opt.program .. "_" .. (opt.programver or "")

    -- load cache
    local cacheinfo  = cache.load(key)

    -- get all flags from argument list
    local flags = cacheinfo[flagskey]
    if not flags then

        -- get argument list
        flags = {}
        local arglist = nil
        try 
        { 
            function () os.iorunv(opt.program, {"--help"}) end,
            catch 
            { 
                function (errors) arglist = errors end
            }
        }
        if arglist then
            local found = false
            for arg in arglist:gmatch("%-r %[%-(%a+)%]") do
                arg:gsub("%a", function (ch) flags["-" .. ch] = true; flags["-r" .. ch] = true; flags["-" .. ch .. "r"] = true end)
                found = true
            end
            if found then
                flags["-r"] = true
            end
        end

        -- save cache
        cacheinfo[flagskey] = flags
        cache.save(key, cacheinfo)
    end

    -- ok?
    return flags[flag]
end

-- has_flag(flag)?
-- 
-- @param opt   the argument options, .e.g {toolname = "", program = "", programver = "", toolkind = "[cc|cxx|ld|ar|sh|gc|rc|dc|mm|mxx]"}
--
-- @return      true or false
--
function main(flag, opt)
    return _check_from_arglist(flag, opt) 
end

