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
-- @author      wuzhenqing
-- @file        has_flags.lua
--

-- Note: This module is derived from gcc/has_flags.lua with modifications
-- for Ascend C specific source kinds (.asc, .aicpu) and --npu-arch handling.
-- Inherit cannot be used here because xmake's tool module inheritance does
-- not support overriding individual local functions.

-- imports
import("core.cache.detectcache")
import("core.language.language")

-- is linker?
function _islinker(flags, opt)

    -- the flags is "-Wl,<arg>" or "-Xlinker <arg>"?
    local flags_str = table.concat(flags, " ")
    if flags_str:startswith("-Wl,") or
       flags_str:startswith("-Xlinker ") then
        return true
    end

    -- the tool kind is ld or sh?
    local toolkind = opt.toolkind or ""
    return toolkind == "ld" or
           toolkind == "sh" or
           toolkind == "ascld" or
           toolkind == "ascsh" or
           toolkind:endswith("-ld") or
           toolkind:endswith("-sh") or
           toolkind:endswith("ld") or
           toolkind:endswith("sh")
end

-- try running
function _try_running(program, argv, opt)
    local errors = nil
    return try {
        function ()
            os.runv(program, argv, opt)
            return true
        end,
        catch {
            function (errs)
                errors = (errs or ""):trim()
            end
        }
    }, errors
end

-- get source kind
function _get_sourcekind(opt, islinker)
    if not islinker then
        local toolkind = opt.toolkind or "asc"
        if language.sourcekinds()[toolkind] then
            return toolkind
        end
    end
    return "asc"
end

function _map_sourcekind(sourcekind)
    local map = {cxx = "c++"}
    return map[sourcekind] or sourcekind
end

-- get extension
function _get_extension(sourcekind)
    return table.wrap(language.sourcekinds()[sourcekind])[1] or ".asc"
end

-- has npu arch?
function _has_npu_arch(flags)
    for _, flag in ipairs(flags) do
        if flag:startswith("--npu-arch=") then
            return true
        end
    end
end

-- attempt to check it from the argument list
function _check_from_arglist(flags, opt, islinker)
    local flag = flags[1]
    if not flag then
        return false
    end

    -- check for the builtin flag=value
    if flag:startswith("--npu-arch=") then
        return true
    end

    -- check from the `--help` menu, only for compile flags
    if islinker or #flags > 1 then
        return
    end

    local key = "core.tools.bisheng.has_flags"
    local flagskey = opt.program .. "_" .. (opt.programver or "")
    local allflags = detectcache:get2(key, flagskey)
    if not allflags then
        allflags = {}
        local arglist = try {function () return os.iorunv(opt.program, {"--help"}, {envs = opt.envs}) end}
        if arglist then
            for arg in arglist:gmatch("%s+(%-[%-%a%d]+)%s+") do
                allflags[arg] = true
            end
        end
        detectcache:set2(key, flagskey, allflags)
    end
    return allflags[flag]
end

-- try running to check flags
function _check_try_running(flags, opt, islinker)
    local snippet = opt.snippet or
        "int main(int argc, char** argv)\n{return 0;}\n"
    local sourcekind = _get_sourcekind(opt, islinker)
    local sourcefile = os.tmpfile("bisheng_has_flags") ..
        _get_extension(sourcekind)
    if not os.isfile(sourcefile) then
        io.writefile(sourcefile, snippet)
    end

    local args = table.join("-o", os.tmpfile(), sourcefile)
    if not islinker then
        table.insert(args, 1, "-c")
    end
    if sourcekind == "asc" and not _has_npu_arch(flags) then
        sourcekind = "c++"
    end
    sourcekind = _map_sourcekind(sourcekind)
    table.insert(args, 1, sourcekind)
    table.insert(args, 1, "-x")
    return _try_running(opt.program, table.join(flags, args), opt)
end

function _has_flags(flags, opt)
    opt = opt or {}
    local islinker = _islinker(flags, opt)
    if not opt.tryrun and _check_from_arglist(flags, opt, islinker) then
        return true
    end
    return _check_try_running(flags, opt, islinker)
end

function main(...)
    return _has_flags(...)
end
