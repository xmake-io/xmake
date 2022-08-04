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
import("core.language.language")
import("core.cache.global_detectcache")

-- attempt to check it from the argument list
function _check_from_arglist(flags, opt)
    local key = "detect.tools.cl.has_flags"
    local flagskey = opt.program .. "_" .. (opt.programver or "")
    local allflags = global_detectcache:get2(key, flagskey)
    if not allflags then
        allflags = {}
        local arglist = os.iorunv(opt.program, {"-?"}, {envs = opt.envs})
        if arglist then
            for arg in arglist:gmatch("(/[%-%a%d]+)%s+") do
                allflags[arg:gsub("/", "-")] = true
            end
        end
        global_detectcache:set2(key, flagskey, allflags)
        global_detectcache:save()
    end
    local flag = flags[1]:gsub("/", "-")
    if flag:startswith("-D") or flag:startswith("-I") then
        return true
    end
    return allflags[flag]
end

-- get extension
function _get_extension(opt)
    return opt.flagkind == "cxxflags" and ".cpp" or (table.wrap(language.sourcekinds()[opt.toolkind or "cc"])[1] or ".c")
end

-- try running to check flags
function _check_try_running(flags, opt)

    -- make an stub source file
    local tmpdir = path.join(os.tmpdir(), "detect")
    local sourcefile = path.join(tmpdir, "cl_has_flags" .. _get_extension(opt))
    if not os.isfile(sourcefile) then
        io.writefile(sourcefile, "int main(int argc, char** argv)\n{return 0;}")
    end

    -- check it
    local errors = nil
    return try  {   function ()
                        local _, errs = os.iorunv(opt.program, table.join("-c", "-nologo", flags, "-Fo" .. os.nuldev(), sourcefile),
                                            {envs = opt.envs, curdir = tmpdir}) -- we need switch to tmpdir to avoid generating some tmp files, e.g. /Zi -> vc140.pdb
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
    opt = opt or {}
    if not opt.tryrun and _check_from_arglist(flags, opt) then
        return true
    end

    -- try running to check it
    return _check_try_running(flags, opt)
end

