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
import("core.language.language")
import("core.base.hashset")
import("core.base.semver")
import("detect.sdks.find_cuda")

-- is linker?
function _islinker(flags, opt)

    -- the flags is "-Wl,<arg>" or "-Xlinker <arg>"?
    local flags_str = table.concat(flags, " ")
    if flags_str:startswith("-Wl,") or flags_str:startswith("-Xlinker ") then
        return true
    end

    -- the tool kind is ld or sh?
    local toolkind = opt.toolkind or ""
    return toolkind == "ld" or toolkind == "sh" or toolkind:endswith("ld") or toolkind:endswith("sh")
end

-- try running
function _try_running(program, argv, opt)
    local errors = nil
    return try { function () os.runv(program, argv, opt); return true end, catch { function (errs) errors = (errs or ""):trim() end }}, errors
end

-- attempt to check it from known flags
function _check_from_knownargs(flags, opt, islinker)
    local flag = flags[1]
    local known_flags = _g.known_flags
    if known_flags == nil then
        known_flags = hashset.from({"-O", "-O0", "-O1", "-O2", "-O3", "-Os", "-g"})
        _g.known_flags = known_flags
    end
    if known_flags:has(flag) then
        return true
    end
    if not islinker then
        if flag:startswith("-D") or
           flag:startswith("-U") or
           flag:startswith("-I") then
            return true
        end
    end
end

-- attempt to check it from the argument list
function _check_from_arglist(flags, opt, islinker)
    local key = "core.tools.gcc." .. (islinker and "has_ldflags" or "has_cflags")
    local flagskey = opt.program .. "_" .. (opt.programver or "")
    local allflags = detectcache:get2(key, flagskey)
    if not allflags then
        allflags = {}
        local arglist = try {function () return os.iorunv(opt.program, {islinker and "-Wl,--help" or "--help"}, {envs = opt.envs}) end}
        if arglist then
            for arg in arglist:gmatch("%s+(%-[%-%a%d]+)%s+") do
                allflags[arg] = true
            end
        end
        detectcache:set2(key, flagskey, allflags)
    end
    local flag = flags[1]
    if islinker and flag then
        if flag:startswith("-Wl,") then
            flag = flag:match("-Wl,(.-),") or flag:sub(5)
        end
    end
    return allflags[flag]
end

-- get extension
function _get_extension(opt)
    -- @note we need to detect extension for ndk/clang++.exe: warning: treating 'c' input as 'c++' when in C++ mode, this behavior is deprecated [-Wdeprecated]
    return (opt.program:endswith("++") or opt.flagkind == "cxxflags") and ".cpp" or (table.wrap(language.sourcekinds()[opt.toolkind or "cc"])[1] or ".c")
end

-- try running to check flags
function _check_try_running(flags, opt, islinker)

    -- make an stub source file
    local snippet = opt.snippet or "int main(int argc, char** argv)\n{return 0;}\n"
    local sourcefile = os.tmpfile("gcc_has_flags:" .. snippet) .. _get_extension(opt)
    if not os.isfile(sourcefile) then
        io.writefile(sourcefile, snippet)
    end

    -- check flags for linker
    local tmpfile = os.tmpfile()
    if islinker then
        return _try_running(opt.program, table.join(flags, "-o", tmpfile, sourcefile), opt)
    end

    -- check flags for clang cuda compiler
    if opt.toolkind == "cu" then
        local cuda_gpu_flags = false
        for _, flag in ipairs(flags) do
            if flag:startswith("--cuda-gpu-arch=") then
                cuda_gpu_flags = true
                break
            end
        end

        local args = table.join(flags, "-c", "-o", tmpfile, sourcefile)
        if not cuda_gpu_flags then
            local cuda = get_config("cuda")
            local cuda_sdk = find_cuda(cuda)
            local cuda_sdkver = cuda_sdk and cuda_sdk.version or "7.0"
            if cuda_sdkver and semver.compare(cuda_sdkver, "12.0") >= 0 then
                table.insert(args, 1, "--cuda-gpu-arch=sm_80")
            end
        end

        return _try_running(opt.program, args, opt)
    end

    -- check flags for compiler
    -- @note we cannot use os.nuldev() as the output file, maybe run failed for some flags, e.g. --coverage
    return _try_running(opt.program, table.join(flags, "-S", "-o", tmpfile, sourcefile), opt)
end

-- has_flags(flags)?
--
-- @param opt   the argument options, e.g. {toolname = "", program = "", programver = "", toolkind = "[cc|cxx|ld|ar|sh|gc|mm|mxx]"}
--
-- @return      true or false
--
function main(flags, opt)

    -- is linker?
    opt = opt or {}
    local islinker = _islinker(flags, opt)

    -- attempt to check it from the argument list
    if not opt.tryrun then
        if _check_from_knownargs(flags, opt, islinker) then
            return true
        end
        if _check_from_arglist(flags, opt, islinker) then
            return true
        end
    end

    -- try running to check it
    return _check_try_running(flags, opt, islinker)
end

