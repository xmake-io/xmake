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
-- @file        xmake.lua
--

-- define rule: environment
rule("wdk.env")

    -- before load
    on_load(function (target)

        -- imports
        import("os.winver", {alias = "os_winver"})
        import("core.project.config")
        import("detect.sdks.find_wdk")

        -- load wdk environment
        if not target:data("wdk") then

            -- find wdk
            local wdk = assert(find_wdk(nil, {verbose = true}), "WDK not found!")

            -- update the umdf sdk version from the xmake.lua
            local umdfver = target:values("wdk.umdf.sdkver")
            if umdfver then
                wdk.umdfver = umdfver
            end

            -- update the kmdf sdk version from the xmake.lua
            local kmdfver = target:values("wdk.kmdf.sdkver")
            if kmdfver then
                wdk.kmdfver = kmdfver
            end

            -- add defines for debug
            if is_mode("debug") then
                target:add("define", "DBG=1")
            end

            -- get winver name
            local winver = target:values("wdk.env.winver") or config.get("wdk_winver")

            -- get winver version
            local winver_version = os_winver.version(winver or "") or "0x0A00"

            -- get target version
            local target_version = os_winver.target_version(winver or "") or "0x0A00"

            -- get winnt version
            local winnt_version = os_winver.winnt_version(winver or "") or "0x0A00"

            -- get ntddi version
            local ntddi_version = os_winver.ntddi_version(winver or "") or "0x0A000000"

            -- add defines for winver
            target:add("defines", "_WIN32_WINNT=" .. winnt_version, "WINVER=" .. winver_version, "NTDDI_VERSION=" .. ntddi_version, "_NT_TARGET_VERSION=" .. target_version)

            -- set builtin version values
            target:values_set("wdk.env.winnt_version", winnt_version)
            target:values_set("wdk.env.ntddi_version", ntddi_version)
            target:values_set("wdk.env.winver_version", winver_version)
            target:values_set("wdk.env.target_version", target_version)

            -- save wdk
            target:data_set("wdk", wdk)
        end
    end)

-- define rule: umdf
rule("wdk.env.umdf")

    -- add rules
    add_deps("wdk.env")

    -- after load
    after_load(function (target)
        import("load").umdf(target)
    end)

-- define rule: kmdf
rule("wdk.env.kmdf")

    -- add rules
    add_deps("wdk.env")

    -- after load
    after_load(function (target)
        import("load").kmdf(target)
    end)

-- define rule: wdm
rule("wdk.env.wdm")

    -- add rules
    add_deps("wdk.env")

    -- after load
    after_load(function (target)
        import("load").wdm(target)
    end)
