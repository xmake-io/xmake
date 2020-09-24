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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        has_flags.lua
--

-- imports
import("lib.detect.cache")

-- attempt to check it from the argument list
function _check_from_arglist(flags, opt)

    -- only one flag?
    if #flags > 1 then
        return
    end

    -- make cache key
    local key = "detect.tools.ml.has_flags"

    -- make allflags key
    local flagskey = opt.program .. "_" .. (opt.programver or "")

    -- load cache
    local cacheinfo  = cache.load(key)

    -- get all allflags from argument list
    local allflags = cacheinfo[flagskey]
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
        cacheinfo[flagskey] = allflags
        cache.save(key, cacheinfo)
    end

    -- ok?
    return allflags[flags[1]:gsub("/", "-")]
end

-- try running to check flags
function _check_try_running(flags, opt)

    -- make an stub source file
    local sourcefile = path.join(os.tmpdir(), "detect", "ml_has_flags.asm")
    if not os.isfile(sourcefile) then
        io.writefile(sourcefile, ".code\nend")
    end

    -- check it
    local errors = nil
    return try  {   function ()
                        local _, errs = os.iorunv(opt.program, table.join("-c", "-nologo", flags, "-Fo" .. os.nuldev(), sourcefile), {envs = opt.envs})
                        if errs and #errs:trim() > 0 then
                            return false, errs
                        end
                        return true
                    end,
                    catch { function (errs) errors = errs end }
                }, errors
end

-- has_flags(flags)?
--
-- @param opt   the argument options, e.g. {toolname = "", program = "", programver = "", toolkind = "[cc|cxx|ld|ar|sh|gc|rc|dc|mm|mxx]"}
--
-- @return      true or false
--
function main(flags, opt)

    -- attempt to check it from the argument list
    if _check_from_arglist(flags, opt) then
        return true
    end

    -- try running to check it
    return _check_try_running(flags, opt)
end

