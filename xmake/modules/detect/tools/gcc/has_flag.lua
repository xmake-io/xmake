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
import("core.language.language")

-- is linker?
function _islinker(flag, opt)
  
    -- the flag is "-Wl,<arg>" or "-Xlinker <arg>"?
    if flag:startswith("-Wl,") or flag:startswith("-Xlinker ") then
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
    local key = "detect.tools.gcc.has_flag"

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

    -- check flag for linker
    if islinker then

        -- get extension
        local extension = table.wrap(language.sourcekinds()[opt.toolkind or "cc"])[1] or ".c"

        -- make an stub source file
        local sourcefile = path.join(os.tmpdir(), "detect", "gcc_has_flag" .. extension)
        if not os.isfile(sourcefile) then
            io.writefile(sourcefile, "int main(int argc, char** argv)\n{return 0;}")
        end

        -- check it
        return try { function () os.runv(opt.program, {flag, "-o", os.nuldev(), sourcefile}); return true end }
    end

    -- get language
    local lang = "c"
    if opt.toolkind and (opt.toolkind == "cxx" or opt.toolkind == "mxx") then
        lang = "c++"
    end
    
    -- check flag for compiler
    return try { function () os.runv(opt.program, {flag, "-S", "-o", os.nuldev(), "-x" .. lang, os.nuldev()}); return true end }
end

-- has_flag(flag)?
-- 
-- @param opt   the argument options, .e.g {toolname = "", program = "", programver = "", toolkind = "[cc|cxx|ld|ar|sh|gc|mm|mxx]"}
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

