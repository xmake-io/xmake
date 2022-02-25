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
import("core.cache.global_detectcache")
import("lib.detect.find_tool")

-- try running
function _try_running(program, argv, opt)
    local errors = nil
    return try { function () os.runv(program, argv, opt); return true end, catch { function (errs) errors = (errs or ""):trim() end }}, errors
end

-- attempt to check it from the argument list
function _check_from_arglist(flags, opt)
    local key = "detect.tools.link.has_flags"
    local flagskey = opt.program .. "_" .. (opt.programver or "")
    local allflags = global_detectcache:get2(key, flagskey)
    if not allflags then
        allflags = {}
        local arglist = nil
        try {
            function () os.runv(opt.program, {"-?"}, {envs = opt.envs}) end,
            catch {
                function (errors) arglist = errors end
            }
        }
        if arglist then
            for arg in arglist:gmatch("(/[%-%a%d]+)%s+") do
                allflags[arg:gsub("/", "-"):lower()] = true
            end
        end
        global_detectcache:set2(key, flagskey, allflags)
        global_detectcache:save()
    end
    local flag = flags[1]:gsub("/", "-"):lower()
    return allflags[flag]
end

-- try running to check flags
function _check_try_running(flags, opt)

    -- make an stub source file
    local flags_str = table.concat(flags, " "):lower()
    local winmain = flags_str:find("subsystem:windows")
    local sourcefile = path.join(os.tmpdir(), "detect", (winmain and "winmain_" or "") .. "link_has_flags.c")
    if not os.isfile(sourcefile) then
        if winmain then
            io.writefile(sourcefile, "int WinMain(void* instance, void* previnst, char** argv, int argc)\n{return 0;}")
        else
            io.writefile(sourcefile, "int main(int argc, char** argv)\n{return 0;}")
        end
    end

    -- compile the source file
    local objectfile = os.tmpfile() .. ".obj"
    local binaryfile = os.tmpfile() .. ".exe"
    local cl = find_tool("cl")
    if cl then
        os.runv(cl.program, {"-c", "-nologo", "-Fo" .. objectfile, sourcefile}, {envs = opt.envs})
    end

    -- try link it
    local ok, errors = _try_running(opt.program, table.join(flags, "-nologo", "-out:" .. binaryfile, objectfile), {envs = opt.envs})
    os.tryrm(objectfile)
    os.tryrm(binaryfile)
    return ok, errors
end

-- ignore some flags
function _ignore_flags(flags)
    local results = {}
    for _, flag in ipairs(flags) do
        flag = flag:lower()
        if not flag:find("[%-/]def:.+%.def") and not flag:find("[%-/]export:") then
            table.insert(results, flag)
        end
    end
    return results
end

-- has_flags(flags)?
--
-- @param opt   the argument options, e.g. {toolname = "", program = "", programver = "", toolkind = "[cc|cxx|ld|ar|sh|gc|rc|dc|mm|mxx]"}
--
-- @return      true or false
--
function main(flags, opt)

    -- ignore some flags
    flags = _ignore_flags(flags)
    if #flags == 0 then
        return true
    end

    -- attempt to check it from the argument list
    if _check_from_arglist(flags, opt) then
        return true
    end

    -- try running to check it
    return _check_try_running(flags, opt)
end

