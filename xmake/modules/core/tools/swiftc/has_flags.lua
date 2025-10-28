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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        has_flags.lua
--

-- imports
import("core.cache.detectcache")

-- try running
function _try_running(...)
    local argv = {...}
    local errors = nil
    return try { function () os.runv(table.unpack(argv)); return true end, catch { function (errs) errors = (errs or ""):trim() end }}, errors
end

-- attempt to check it from the argument list
function _check_from_arglist(flags, opt)

    -- only one flag?
    if #flags > 1 then
        return
    end

    -- make cache key
    local key = "core.tools.swiftc.has_flags"

    -- make allflags key
    local flagskey = opt.program .. "_" .. (opt.programver or "")

    -- get all allflags from argument list
    local allflags = detectcache:get2(key, flagskey)
    if not allflags then

        -- get argument list
        allflags = {}
        local arglist = os.iorunv(opt.program, {"--help"})
        if arglist then
            for arg in arglist:gmatch("%s+(%-[%-%a%d]+)%s+") do
                allflags[arg] = true
            end
        end

        -- save cache
        detectcache:set2(key, flagskey, allflags)
    end
    return allflags[flags[1]]
end

-- try running to check flags
function _check_try_running(flags, opt)

    -- make an stub source file
    local sourcefile = path.join(os.tmpdir(), "detect", "swiftc_has_flags.swift")
    if not os.isfile(sourcefile) then
        io.writefile(sourcefile, "")
    end

    -- check it
    local objectfile = os.tmpfile() .. ".o"
    local ok, errors = _try_running(opt.program, table.join(flags, "-o", objectfile, sourcefile))
    if errors and not errors:match("unknown argument") then
        ok = true
        errors = nil
    end

    -- remove files
    os.tryrm(objectfile)

    -- ok?
    return ok, errors
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

