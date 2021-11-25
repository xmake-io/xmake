--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        has_flags.lua
--

-- imports
import("core.cache.detectcache")
import("core.language.language")

-- attempt to check it from the argument list
function _check_from_arglist(flags, opt)

    -- only one flag?
    if #flags > 1 then
        return
    end

    -- make cache key
    local key = "detect.tools.rc.has_flags"

    -- make allflags key
    local flagskey = opt.program .. "_" .. (opt.programver or "")

    -- get all allflags from argument list
    local allflags = detectcache:get2(key, flagskey)
    if not allflags then

        -- get argument list
        allflags = {}
        local arglist = os.iorunv(opt.program, {"-?"}, {envs = opt.envs})
        if arglist then
            for arg in arglist:gmatch("(/[%-%a%d]+)%s+") do
                allflags[arg:gsub("/", "-")] = true
            end
        end

        -- save cache
        detectcache:set2(key, flagskey, allflags)
        detectcache:save()
    end
    return allflags[flags[1]:gsub("/", "-")]
end

-- has_flags(flags)?
--
-- @param opt   the argument options, e.g. {toolname = "", program = "", programver = ""}
--
-- @return      true or false
--
function main(flags, opt)
    return _check_from_arglist(flags, opt)
end

