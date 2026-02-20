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
-- @file        find_gcc.lua
--

-- imports
import("lib.detect.find_program")
import("lib.detect.find_programver")
import("core.cache.detectcache")

-- check gcc/gigabyte signature
function check_gcc_gigabyte(program)
    local filepath = program
    if path.is_absolute(filepath) then
        filepath = path.translate(filepath)
    end
    -- we only check signature for gcc.exe
    if not filepath:lower():endswith("gcc.exe") then
        return
    end
    if os.isfile(filepath) then
        local signer = nil
        if winos.file_signature then
            signer = winos.file_signature(filepath)
        end
        if signer and signer.signer_name then
            local signer_name = signer.signer_name:upper()
            if signer_name:find("GIGA-BYTE", 1, true) then
                return true
            end
        end
    end
end

-- check gigabyte gcc
-- avoid gcc.exe signed by GIGA-BYTE
-- @see https://github.com/xmake-io/xmake/issues/5629
function _check_gcc_on_windows(program, opt)
    opt = opt or {}
    if path.is_absolute(program) then
        if check_gcc_gigabyte(program) then
            raise("gcc.exe signed by GIGA-BYTE is not allowed!")
        end
    else
        local paths = path.splitenv(vformat("$(env PATH)"))
        if paths then
            for _, p in ipairs(paths) do
                local prog = path.join(p, program)
                if os.isfile(prog) and check_gcc_gigabyte(prog) then
                    raise("gcc.exe signed by GIGA-BYTE is not allowed!")
                end
            end
        end
    end
    return os.runv(program, {"--version"}, {envs = opt.envs, shell = opt.shell})
end

-- detect whether the current gcc compiler is clang
function check_clang(program, opt)
    local is_clang = false
    local cachekey = "find_gcc_versioninfo_" .. program
    local versioninfo = detectcache:get(cachekey)
    if versioninfo == nil then
        versioninfo = os.iorunv(program, {"--version"}, {envs = opt.envs})
        detectcache:set(cachekey, versioninfo)
    end
    if versioninfo and versioninfo:find("clang", 1, true) then
        is_clang = true
    end
    return is_clang
end

-- find gcc
--
-- @param opt   the argument options, e.g. {version = true}
--
-- @return      program, version
--
-- @code
--
-- local gcc = find_gcc()
-- local gcc, version, hintname = find_gcc({program = "xcrun -sdk macosx gcc", version = true})
--
-- @endcode
--
function main(opt)
    opt = opt or {}
    if is_host("windows") then
        opt.check = _check_gcc_on_windows
    else
        opt.norunfile = true
    end
    local program = find_program(opt.program or "gcc", opt)
    local version = nil
    if program and opt.version then
        version = find_programver(program, opt)
    end

    local is_clang = false
    if program and is_host("macosx") then
        is_clang = check_clang(program, opt)
    end
    return program, version, (is_clang and "clang" or "gcc")
end
