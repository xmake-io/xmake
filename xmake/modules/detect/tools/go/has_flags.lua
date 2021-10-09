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

-- is linker?
function _islinker(flags, opt)

    -- the tool kind is gcld or gcsh?
    local toolkind = opt.toolkind or ""
    return toolkind:endswith("ld") or toolkind:endswith("sh")
end

-- try running
function _try_running(...)

    local argv = {...}
    local errors = nil
    return try { function () os.runv(table.unpack(argv)); return true end, catch { function (errs) errors = (errs or ""):trim() end }}, errors
end

-- attempt to check it from the argument list
function _check_from_arglist(flags, opt, islinker)

    -- only for compiler
    if islinker or #flags > 1 then
        return
    end

    -- make cache key
    local key = "detect.tools.go.has_flags"

    -- make flags key
    local flagskey = opt.program .. "_" .. (opt.programver or "")

    -- get all flags from argument list
    local allflags = detectcache:get2(key, flagskey)
    if not allflags then

        -- attempt to get argument list from the error info (help menu)
        allflags = {}
        try
        {
            function () os.runv(opt.program, {"tool", "compile", "--help"}) end,
            catch
            {
                function (errors)
                    local arglist = errors
                    if arglist then
                        for arg in arglist:gmatch("%s+(%-[%-%a%d]+)%s+") do
                            allflags[arg] = true
                        end
                    end
                end
            }
        }

        -- save cache
        detectcache:set2(key, flagskey, allflags)
        detectcache:save()
    end
    return allflags[flags[1]]
end

-- try running to check flags
function _check_try_running(flags, opt, islinker)

    -- make an stub source file
    local sourcefile = path.join(os.tmpdir(), "detect", "go_has_flags.go")
    local objectfile = path.join(os.tmpdir(), "detect", "go_has_flags.o")
    local targetfile = path.join(os.tmpdir(), "detect", "go_has_flags.bin")
    if not os.isfile(sourcefile) then
        io.writefile(sourcefile, "package main\nfunc main() {\n}")
    end

    -- check flags for linker
    if islinker then

        -- compile a object file first
        if not os.isfile(objectfile) and not _try_running(opt.program, table.join("tool", "compile", "-o", objectfile, sourcefile)) then
            return false
        end

        -- check it
        return _try_running(opt.program, table.join("tool", "link", flags, "-o", targetfile, objectfile))
    end

    -- check flags for compiler
    return _try_running(opt.program, table.join("tool", "compile", flags, "-o", objectfile, sourcefile))
end

-- has_flags(flags)?
--
-- @param opt   the argument options, e.g. {toolname = "", program = "", programver = "", toolkind = "[cc|cxx|ld|ar|sh|gc|mm|mxx]"}
--
-- @return      true or false
--
function main(flags, opt)

    -- is linker?
    local islinker = _islinker(flags, opt)

    -- attempt to check it from the argument list
    if _check_from_arglist(flags, opt, islinker) then
        return true
    end

    -- try running to check it
    return _check_try_running(flags, opt, islinker)
end

