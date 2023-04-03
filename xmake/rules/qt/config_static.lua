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
-- @author      ruki, jingkaimori
-- @file        config_static.lua
--

-- imports
import("core.base.semver")

function main(target)
    -- get qt sdk version
    local qt = target:data("qt")
    local qt_sdkver = nil
    if qt.sdkver then
        qt_sdkver = semver.new(qt.sdkver)
    else
        raise("Qt SDK version not found, please run `xmake f --qt_sdkver=xxx` to set it.")
    end

    -- @see
    -- https://github.com/xmake-io/xmake/issues/1047
    -- https://github.com/xmake-io/xmake/issues/2791
    local QtPlatformSupport
    if qt_sdkver:ge("6.0") then
        QtPlatformSupport = nil
    elseif qt_sdkver:ge("5.9") then
        QtPlatformSupport = "QtPlatformCompositorSupport"
    else
        QtPlatformSupport = "QtPlatformSupport"
    end

    -- load some basic plugins and frameworks
    local plugins = {}
    local frameworks = {}
    if target:is_plat("macosx") then
        plugins.QCocoaIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"qcocoa", "cups"}}
        table.insert(frameworks, "QtWidgets")
        if QtPlatformSupport then
            table.insert(frameworks, QtPlatformSupport)
        end
    elseif target:is_plat("windows") then
        plugins.QWindowsIntegrationPlugin = {linkdirs = "plugins/platforms", links = {is_mode("debug") and "qwindowsd" or "qwindows"}}
        table.join2(frameworks, "QtPrintSupport", "QtWidgets")
        if QtPlatformSupport then
            table.insert(frameworks, QtPlatformSupport)
        end
    elseif target:is_plat("wasm") then
        plugins.QWasmIntegrationPlugin = {linkdirs = "plugins/platforms", links = {"qwasm"}}
        if qt_sdkver:ge("6.0") then
            table.join2(frameworks, "QtOpenGL")
        else
            table.join2(frameworks, "QtEventDispatcherSupport", "QtFontDatabaseSupport", "QtEglSupport")
        end
    end
    return frameworks, plugins, qt_sdkver
end