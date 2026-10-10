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
import("core.language.language")
import("core.cache.global_detectcache")
import("core.tools.cl.check_knownargs")
import("private.tools.vstool")

-- attempt to check it from the argument list
function _check_from_arglist(flags, opt)
    local key = "core.tools.cl.has_flags"
    local flagskey = opt.program .. "_" .. (opt.programver or "")
    local allflags = global_detectcache:get2(key, flagskey)
    if not allflags then
        allflags = {}
        -- @see https://github.com/xmake-io/xmake/issues/7610
        local arglist = vstool.iorunv(opt.program, {"-?"}, {envs = opt.envs})
        if arglist then
            for arg in arglist:gmatch("(/[%-%a%d]+)%s+") do
                allflags[arg:gsub("/", "-")] = true
            end
        end
        global_detectcache:set2(key, flagskey, allflags)
        global_detectcache:save()
    end
    return allflags[flags[1]:gsub("/", "-")]
end

-- get extension
function _get_extension(opt)
    return opt.flagkind == "cxxflags" and ".cpp" or (table.wrap(language.sourcekinds()[opt.toolkind or "cc"])[1] or ".c")
end

-- get command-line diagnostics which indicate that the flags were not accepted
--
-- when vstool.iorunv enables VS_UNICODE_OUTPUT, cl will write all its diagnostics
-- (including the D9002 warning for unknown flags, whose exit code is still 0) to
-- stdout instead of stderr, so we only need to check outdata here. and the hard
-- errors (non-zero exit) will be raised by vstool.iorunv and handled by the catch.
--
-- Dxxxx are command-line diagnostics. Ordinary compiler warnings (Cxxxx), such as
-- C5072 for ASan without debug information, do not imply that the flags are unsupported.
-- Match diagnostic codes instead of localized warning text or filename suffixes.
-- The source filename echo has no diagnostic code and is ignored automatically.
-- A real diagnostic ending with the source filename must still be checked.
--
-- e.g.
--   cl_has_flags_xxx.c                                            -> ignore filename echo
--   cl : warning C5072: ASAN enabled without debug information    -> accept ordinary warning
--   cl : Command line warning D9025 : overriding '/W3' with '/W4' -> accept option override
--   cl : Command line warning D9002 : ignoring unknown option ... -> reject unknown option
--   cl : Command line warning D9027 : source file ... ignored     -> reject ignored input
--
-- @see https://github.com/xmake-io/xmake/issues/7822
function _get_output(outdata)
    -- These command-line warnings still accept the options: overrides, scope notices,
    -- rebuild fallback, deprecation and recommended replacements.
    -- @see https://learn.microsoft.com/en-us/cpp/error-messages/tool-errors/command-line-errors-d8000-through-d9999
    local accepted = {D9025 = true, D9026 = true, D9028 = true, D9035 = true, D9036 = true}
    local output = {}
    for _, line in ipairs((outdata or ""):split("\n", {plain = true})) do
        line = line:rtrim()
        local diagnostic = line:match("%f[%w](D%d%d%d%d)%s*:")
        if diagnostic and not accepted[diagnostic] then
            table.insert(output, line)
        end
    end
    return #output > 0 and table.concat(output, "\n") or nil
end

-- try running to check flags
function _check_try_running(flags, opt)

    -- make an stub source file
    local snippet = opt.snippet or "int main(int argc, char** argv)\n{return 0;}\n"
    local sourcefile = os.tmpfile("cl_has_flags:" .. snippet) .. _get_extension(opt)
    if not os.isfile(sourcefile) then
        io.writefile(sourcefile, snippet)
    end

    -- check it
    local errors = nil
    return try  {   function ()
                        local tmpdir = os.tmpdir()
                        local nuldev = os.nuldev()
                        local tmpfile
                        if not is_host("windows") then
                            tmpfile = os.tmpfile()
                            nuldev = tmpfile
                        end
                        local outdata = vstool.iorunv(opt.program, table.join("-c", "-nologo", flags, "-Fo" .. nuldev, sourcefile),
                                            {envs = opt.envs, curdir = tmpdir}) -- we need to switch to tmpdir to avoid generating some tmp files, e.g. /Zi -> vc140.pdb
                        if tmpfile then
                            os.tryrm(tmpfile)
                        end
                        local errs = _get_output(outdata)
                        if errs then
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
    if not opt.tryrun then
        if check_knownargs(flags) then
            return true
        end
        if _check_from_arglist(flags, opt) then
            return true
        end
    end

    -- try running to check it
    return _check_try_running(flags, opt)
end
