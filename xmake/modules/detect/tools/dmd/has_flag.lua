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

-- is linker?
function _islinker(flag, opt)
  
    -- the flag is "-L=<arg>" or "-L<arg>"?
    if flag:startswith("-L=") or flag:startswith("-L-") then
        return true
    end

    -- the tool kind is ld or sh?
    local toolkind = opt.toolkind or ""
    return toolkind == "ld" or toolkind == "sh" or toolkind:endswith("-ld") or toolkind:endswith("-sh")
end

-- attempt to check it from the argument list 
function _check_from_arglist(flag, opt, islinker)

    -- only for compiler
    if islinker then
        return 
    end

    -- make cache key
    local key = "detect.tools.dmd.has_flag"

    -- make flags key
    local flagskey = opt.program .. "_" .. (opt.programver or "")

    -- load cache
    local cacheinfo  = cache.load(key)

    -- get all flags from argument list
    local flags = cacheinfo[flagskey]
    if not flags then

        -- get argument list
        flags = {}
        local arglist = os.iorunv(opt.program, {"--help"})
        if arglist then
            for arg in arglist:gmatch("%s+(%-[%-%a%d]+)%s+") do
                flags[arg] = true
            end
        end

        -- save cache
        cacheinfo[flagskey] = flags
        cache.save(key, cacheinfo)
    end

    -- ok?
    return flags[flag]
end

-- try running to check flag
function _check_try_running(flag, opt, islinker)

    -- make an stub source file
    local sourcefile = path.join(os.tmpdir(), "detect", "dmd_has_flag.d")
    if not os.isfile(sourcefile) then
        io.writefile(sourcefile, "void main() {\n}")
    end

    -- init argv
    local argv = {flag, "-of" .. os.nuldev(), sourcefile}
    if not islinker then
        table.insert(argv, 1, "-c")
    end

    -- check it
    return try { function () os.runv(opt.program, argv); return true end }
end

-- has_flag(flag)?
-- 
-- @param opt   the argument options, .e.g {toolname = "", program = "", programver = "", toolkind = "[cc|cxx|ld|ar|sh|gc|rc|dc|mm|mxx]"}
--
-- @return      true or false
--
function main(flag, opt)

    -- is linker?
    local islinker = _islinker(flag, opt)

    -- attempt to check it from the argument list 
    if _check_from_arglist(flag, opt, islinker) then
        return true
    end

    -- try running to check it
    return _check_try_running(flag, opt, islinker)
end

