--!A cross-toolchain build utility based on Lua
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
-- @file        check.lua
--

-- imports
import("core.project.config")
import("detect.sdks.find_mingw")

-- check the mingw toolchain
function main(toolchain)
    local mingw
    for _, package in ipairs(toolchain:packages()) do
        local installdir = package:installdir()
        if installdir and os.isdir(installdir) then
            mingw = find_mingw(installdir, {verbose = true, cross = toolchain:cross(), arch = toolchain:arch()})
            if mingw then
                break
            end
        end
    end
    if not mingw then
        mingw = find_mingw(toolchain:config("mingw") or config.get("mingw"), {
            verbose = true,
            bindir = toolchain:bindir(),
            cross = toolchain:cross(),
            msystem = toolchain:config("msystem"),
            arch = toolchain:arch()
        })
    end
    if mingw then
        local bindir = mingw.bindir or path.join(mingw.sdkdir, "bin")
        local cross = mingw.cross or ""
        local is_win = is_host("windows")
        local gcc = path.join(bindir, cross .. (is_win and "gcc.exe" or "gcc"))
        local clang = path.join(bindir, cross .. (is_win and "clang.exe" or "clang"))
        local use_clang = toolchain:config("clang")
        if use_clang then
            if not os.isexec(clang) then
                return false
            end
        elseif use_clang == false then
            if not os.isexec(gcc) then
                return false
            end
        elseif (not os.isexec(gcc) or (mingw.sdkdir and mingw.sdkdir:find("llvm-mingw", 1, true)))
            and os.isexec(clang) then
            toolchain:config_set("clang", true)
        end
        toolchain:config_set("mingw", mingw.sdkdir)
        toolchain:config_set("cross", mingw.cross)
        toolchain:config_set("bindir", mingw.bindir)
        return true
    end
end
