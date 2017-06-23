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
-- @file        has_flags.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- has this flag?
function _has_flag(name, flag, opt)

    -- find tool program and version first
    opt.version = true
    local tool = find_tool(name, opt)
    if not tool then
        return false
    end

    -- init tool
    opt.toolname   = tool.name
    opt.program    = tool.program
    opt.programver = tool.version

    -- init cache and key
    local key     = tool.program .. "_" .. (tool.version or "") .. "_" .. (opt.toolkind or "") .. "_" .. flag
    local results = _g._RESULTS or {}
    
    -- get result from the cache first
    local result = results[key]
    if result ~= nil then
        return result
    end

    -- detect.tools.xxx.has_flag(flag, opt)?
    if os.isfile(path.join(os.programdir(), "modules", "detect", "tools", tool.name, "has_flag.lua")) then
        local hasflag = import("detect.tools." .. tool.name .. ".has_flag")
        if hasflag then
            result = hasflag(flag, opt)
        end
    else
        result = try { function () os.runv(tool.program, {flag}); return true end }
    end

    -- trace
    if option.get("verbose") or opt.verbose then
        cprint("checking for the flags %s ... %s", flag, ifelse(result, "${green}ok", "${red}no"))
    end

    -- save result to cache
    results[key] = ifelse(result, result, false)
    _g._RESULTS = results

    -- ok?
    return result
end

-- has the given flags for the current tool?
--
-- @param name      the tool name
-- @param flags     the flags
-- @param opt       the argument options, .e.g {verbose = false, program = "", toolkind = "[cc|cxx|ld|ar|sh|gc|rc|dc|mm|mxx]"}
--
-- @return          true or false
--
-- @code
-- local ok = has_flags("clang", "-g")
-- local ok = has_flags("clang", {"-g", "-O0"}, {program = "xcrun -sdk macosx clang"})
-- local ok = has_flags("clang", "-g", {toolkind = "cxx"})
-- @endcode
--
function main(name, flags, opt)

    -- init options
    opt = opt or {}

    -- has all flags?
    for _, flag in ipairs(flags) do
        if not _has_flag(name, flag, opt) then
            return false
        end
    end

    -- ok
    return true
end
