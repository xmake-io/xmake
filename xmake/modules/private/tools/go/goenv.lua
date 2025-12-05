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
-- @file        goenv.lua
--

-- imports
import("lib.detect.find_tool")

-- Map xmake platform to Go OS
function GOOS(plat)
    local goos_map = {
        windows = "windows",
        mingw = "windows",
        msys = "windows",
        cygwin = "windows",
        linux = "linux",
        macosx = "darwin",
        android = "android",
        ios = "ios",
        freebsd = "freebsd",
        netbsd = "netbsd",
        openbsd = "openbsd",
        dragonfly = "dragonfly",
        solaris = "solaris",
        aix = "aix",
        plan9 = "plan9"
    }
    return goos_map[plat]
end

-- Map xmake architecture to Go architecture
function GOARCH(arch)
    local goarch_map = {
        x86 = "386",
        i386 = "386",
        x64 = "amd64",
        x86_64 = "amd64",
        amd64 = "amd64",
        arm = "arm",
        armv7 = "arm",
        armv7s = "arm",
        arm64 = "arm64",
        aarch64 = "arm64",
        mips = "mips",
        mips64 = "mips64",
        mips64le = "mips64le",
        mipsle = "mipsle",
        ppc = "ppc",
        ppc64 = "ppc64",
        ppc64le = "ppc64le",
        riscv64 = "riscv64",
        s390x = "s390x",
        wasm = "wasm"
    }
    
    -- try direct match first
    if goarch_map[arch] then
        return goarch_map[arch]
    end
    
    -- try pattern matching for arm variants
    if arch:match("^arm") then
        if arch:match("64") or arch:match("aarch64") then
            return "arm64"
        else
            return "arm"
        end
    end
    
    -- try pattern matching for x86 variants
    if arch:match("^x86") or arch:match("^i386") or arch:match("^i686") then
        return "386"
    end
    
    if arch:match("^x64") or arch:match("^amd64") or arch:match("^x86_64") then
        return "amd64"
    end
    
    return nil
end

-- Get GOROOT from Go installation
function GOROOT(toolchain)
    local go = find_tool("go")
    if go then
        local gorootdir = try { 
            function() 
                return os.iorunv(go.program, {"env", "GOROOT"}, {envs = toolchain and toolchain:get("runenvs") or nil}) 
            end 
        }
        if gorootdir then
            return gorootdir:trim()
        end
    end
end
