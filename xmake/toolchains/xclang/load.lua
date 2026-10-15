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
-- @file        load.lua
--

import("target", {rootdir = os.scriptdir(), alias = "get_target"})

function main(toolchain)
    local target = get_target(toolchain)
    assert(target, "unsupported xclang platform/architecture: %s/%s", toolchain:plat(), toolchain:arch())

    -- Always select a target, including native builds: clang's default ABI may differ.
    local flag = "--target=" .. target
    for _, name in ipairs({"cxflags", "mxflags", "asflags", "ldflags", "shflags"}) do
        toolchain:add(name, flag)
    end

    -- Keep all tools in the same distribution, even when another LLVM is on PATH.
    local bindir = toolchain:bindir()
    local tools = {cc = "clang", cxx = "clang++", mxx = "clang++", mm = "clang", as = "clang",
                   ld = "clang++", sh = "clang++", ar = "llvm-ar", ranlib = "llvm-ranlib",
                   strip = "llvm-strip", objcopy = "llvm-objcopy",
                   dlltool = "llvm-dlltool", dsymutil = "dsymutil"}
    for name, program in pairs(tools) do
        toolchain:set("toolset", name, path.join(bindir, program))
    end
    toolchain:set("toolset", "cpp", os.args({path.join(bindir, "clang")}) .. " -E")
    if toolchain:is_plat("mingw") then
        toolchain:set("toolset", "mrc", path.join(bindir, "llvm-windres"))
        toolchain:add("mrcflags", flag)
    elseif toolchain:is_plat("windows") then
        toolchain:set("toolset", "mrc", path.join(bindir, "llvm-rc"))
    end
    if toolchain:is_plat("windows") then
        toolchain:set("runtimes", "MT", "MTd", "MD", "MDd")
    else
        toolchain:set("runtimes", "c++_static")
    end
    if is_host("windows") then
        toolchain:add("runenvs", "PATH", bindir)
    end
end
