--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.project.config")

-- load it
function main()

    -- init flags
    local arch = config.get("arch")
    if arch:startswith("arm64") then
        _g.cxflags      = {}
        _g.asflags      = {}
        _g.ldflags      = {"-llog"}
        _g.shflags      = {"-llog"}
        _g.cxxflags     = {}
    else
        _g.cxflags      = { "-march=" .. arch, "-mthumb"}
        _g.asflags      = { "-march=" .. arch, "-mthumb"}
        _g.ldflags      = { "-march=" .. arch, "-llog", "-mthumb"}
        _g.shflags      = { "-march=" .. arch, "-llog", "-mthumb"}
        _g.cxxflags     = {}
    end

    -- init cxflags for the target kind: binary 
    _g.binary           = { cxflags = {"-fPIE", "-pie"} }

    -- add flags for the sdk directory of ndk
    local ndk = config.get("ndk")
    local ndk_sdkver = config.get("ndk_sdkver")
    if ndk and ndk_sdkver then

        -- get ndk sdk directory
        local ndk_sdkdir = path.translate(format("%s/platforms/android-%d", ndk, ndk_sdkver)) 

        -- add sysroot
        if arch:startswith("arm64") then
            insert(_g.cxflags, format("--sysroot=%s/arch-arm64", ndk_sdkdir))
            insert(_g.asflags, format("--sysroot=%s/arch-arm64", ndk_sdkdir))
            insert(_g.ldflags, format("--sysroot=%s/arch-arm64", ndk_sdkdir))
            insert(_g.shflags, format("--sysroot=%s/arch-arm64", ndk_sdkdir))
        else
            insert(_g.cxflags, format("--sysroot=%s/arch-arm", ndk_sdkdir))
            insert(_g.asflags, format("--sysroot=%s/arch-arm", ndk_sdkdir))
            insert(_g.ldflags, format("--sysroot=%s/arch-arm", ndk_sdkdir))
            insert(_g.shflags, format("--sysroot=%s/arch-arm", ndk_sdkdir))
        end

        -- add "-fPIE -pie" to ldflags
        insert(_g.ldflags, "-fPIE")
        insert(_g.ldflags, "-pie")

        -- only for c++ stl
        local toolchains_ver = config.get("toolchains_ver")
        if toolchains_ver then

            -- get c++ stl sdk directory
            local cxxstl_sdkdir = path.translate(format("%s/sources/cxx-stl/gnu-libstdc++/%s", ndk, toolchains_ver)) 

            -- the toolchains archs
            local toolchains_archs = 
            {
                ["armv5te"]     = "armeabi"
            ,   ["armv6"]       = "armeabi"
            ,   ["armv7-a"]     = "armeabi-v7a"
            ,   ["armv8-a"]     = "armeabi-v7a"
            ,   ["arm64-v8a"]   = "arm64-v8a"
            }

            -- add search directories for c++ stl
            insert(_g.cxxflags, format("-I%s/include", cxxstl_sdkdir))
            if toolchains_archs[arch] then
                insert(_g.cxxflags, format("-I%s/libs/%s/include", cxxstl_sdkdir, toolchains_archs[arch]))
                insert(_g.ldflags, format("-L%s/libs/%s", cxxstl_sdkdir, toolchains_archs[arch]))
                insert(_g.shflags, format("-L%s/libs/%s", cxxstl_sdkdir, toolchains_archs[arch]))
                insert(_g.ldflags, format("-lgnustl_static"))
                insert(_g.shflags, format("-lgnustl_static"))
            end
        end
    end

    -- init targets for rust
    local targets = 
    {
        ["armv5te"]     = "arm-linux-androideabi"
    ,   ["armv6"]       = "arm-linux-androideabi"
    ,   ["armv7-a"]     = "arm-linux-androideabi"
    ,   ["armv8-a"]     = "arm-linux-androideabi"
    ,   ["arm64-v8a"]   = "aarch64-linux-android"
    }

    -- init flags for rust
    _g.rcflags       = { "--target=" .. targets[arch] }
    _g["rc-shflags"] = { "-C linker=" .. config.get("sh"), "-C link-args=\"" .. (table.concat(_g.shflags, " "):gsub("%-march=.-%s", "")) .. "\"" }
    _g["rc-ldflags"] = { "-C linker=" .. config.get("ld"), "-C link-args=\"" .. (table.concat(_g.ldflags, " "):gsub("%-march=.-%s", "")) .. "\"" }

    -- ok
    return _g
end


