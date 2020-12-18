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

-- define rule: driver
rule("wdk.driver")

    -- add rules
    add_deps("wdk.inf", "wdk.man", "wdk.mc", "wdk.mof", "wdk.tracewpp", "wdk.sign", "wdk.package.cab")

    -- after load
    after_load(function (target)

        -- load environment
        if target:rule("wdk.env.umdf") then
            import("load").driver_umdf(target)
        end
        if target:rule("wdk.env.kmdf") then
            import("load").driver_kmdf(target)
        end
        if target:rule("wdk.env.wdm") then
            import("load").driver_wdm(target)
        end
    end)

    -- after build
    after_build(function (target)

        -- imports
        import("core.project.config")

        -- copy redist files for kmdf
        if target:rule("wdk.env.kmdf") then

            -- get wdk
            local wdk = target:data("wdk")

            -- copy wdf redist dll libraries (WdfCoInstaller01011.dll, ..) to the target directory
            os.cp(path.join(wdk.sdkdir, "Redist", "wdf", config.arch(), "*.dll"), target:targetdir())
        end
    end)

-- define rule: binary
rule("wdk.binary")

    -- add rules
    add_deps("wdk.inf", "wdk.man", "wdk.mc", "wdk.mof", "wdk.tracewpp")

    -- after load
    after_load(function (target)

        -- set kind
        target:set("kind", "binary")

        -- add links
        target:add("links", "kernel32", "user32", "gdi32", "winspool", "comdlg32")
        target:add("links", "advapi32", "shell32", "ole32", "oleaut32", "uuid", "odbc32", "odbccp32", "setupapi")
    end)

-- define rule: static
rule("wdk.static")

    -- add rules
    add_deps("wdk.inf", "wdk.man", "wdk.mc", "wdk.mof", "wdk.tracewpp")

    -- after load
    after_load(function (target)

        -- set kind
        target:set("kind", "static")

        -- for kernel driver
        if target:rule("wdk.env.kmdf") or target:rule("wdk.env.wdm") then
            -- compile as kernel driver
            target:add("cxflags", "-kernel", {force = true})
        end
    end)

-- define rule: shared
rule("wdk.shared")

    -- add rules
    add_deps("wdk.inf", "wdk.man", "wdk.mc", "wdk.mof", "wdk.tracewpp")

    -- after load
    after_load(function (target)

        -- set kind
        target:set("kind", "shared")

        -- add links
        target:add("links", "kernel32", "user32", "gdi32", "winspool", "comdlg32")
        target:add("links", "advapi32", "shell32", "ole32", "oleaut32", "uuid", "odbc32", "odbccp32", "setupapi")
    end)
