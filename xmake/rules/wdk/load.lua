--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.project.config")
import("lib.detect.find_path")

-- load for umdf
function _load_for_umdf(target, wdk, arch, kind)

    -- add defines
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "_WIN32_WINNT=0x0A00", "WINVER=0x0A00", "WINNT=1", "NTDDI_VERSION=0x0A000004", "_WINDLL")
    target:add("defines", "UMDF_VERSION_MINOR=15", "UMDF_VERSION_MAJOR=2", "UMDF_USING_NTSTATUS")
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    end

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "um"))
    local includedir = find_path("wdf.h", path.join(wdk.includedir, "wdf", "umdf", "**"))
    if includedir then
        target:add("includedirs", includedir)
    end

    -- add link directories
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "um", arch))
    for _, dir in ipairs(os.dirs(path.join(wdk.libdir, "wdf", "umdf", arch, "*"))) do
        target:add("linkdirs", dir)
        break
    end

    -- add links
    if kind == "shared" then
        target:add("links", "WdfDriverStubUm")
    end
    target:add("links", "ntdll", "OneCoreUAP", "mincore", "ucrt")
    target:add("ldflags", "-NODEFAULTLIB:kernel32.lib", "-NODEFAULTLIB:user32.lib", "-NODEFAULTLIB:libucrt.lib", {force = true})
end

-- load for kmdf
function _load_for_kmdf(target, opt)
end

-- the main entry
function main(target, opt)

    -- init options
    opt = opt or {}

    -- get wdk
    local wdk = target:data("wdk")

    -- get arch
    local arch = config.arch()

    -- set kind
    if opt.kind then
        target:set("kind", opt.kind)
    end

    -- load for umdf
    if opt.mode == "umdf" then
        _load_for_umdf(target, wdk, arch, opt.kind)
    end

    -- load for kmdf
    if opt.mode == "kmdf" then
        _load_for_kmdf(target, wdk, arch, opt.kind)
    end
end
