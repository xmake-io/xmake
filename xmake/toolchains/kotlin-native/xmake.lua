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

toolchain("kotlin-native")
    set_kind("standalone")
    set_homepage("https://kotlinlang.org")
    set_description("The Kotlin Programming Language Compiler. ")

    set_toolset("kc",   "$(env KC)", "kotlinc-native")
    set_toolset("kcld", "$(env KC)", "kotlinc-native")
    set_toolset("kcsh", "$(env KC)", "kotlinc-native")
    set_toolset("kcar", "$(env KC)", "kotlinc-native")

    on_check(function (toolchain)
        import("lib.detect.find_tool")

        local paths = {}
        local runenvs = {}
        local java_home = os.getenv("JAVA_HOME")
        local pathenvs = os.getenv("PATH")
        if pathenvs then
            pathenvs = path.splitenv(pathenvs)
        else
            pathenvs = {}
        end
        for _, package in ipairs(toolchain:packages()) do
            local envs = package:envs()
            if envs then
                table.join2(paths, envs.PATH)
                table.join2(pathenvs, envs.PATH)
                if not java_home then
                    java_home = envs.JAVA_HOME
                end
            end
        end
        if not find_tool("java") then
            if #pathenvs > 0 then
                runenvs.PATH = path.joinenv(pathenvs)
            end
            if java_home then
                runenvs.JAVA_HOME = table.unwrap(java_home)
            end
        end
        if toolchain:bindir() then
            table.insert(paths, toolchain:bindir())
        end

        local kotlinc_native = find_tool("kotlinc-native", {paths = paths, envs = runenvs})
        if kotlinc_native and kotlinc_native.program then
            kotlinc_native = kotlinc_native.program
        end
        if kotlinc_native then
            if path.is_absolute(kotlinc_native) then
                local bindir = path.directory(kotlinc_native)
                toolchain:config_set("bindir", bindir)
                toolchain:config_set("sdkdir", path.directory(bindir))
                toolchain:config_set("runenvs", runenvs)
            end
            toolchain:configs_save()
            return true
        end
    end)

    on_load(function (toolchain)
        import("private.core.base.is_cross")

        -- bind runenvs for java
        local runenvs = toolchain:config("runenvs")
        if runenvs then
            for k, v in pairs(runenvs) do
                toolchain:add("runenvs", k, table.unpack(path.splitenv(v)))
            end
        end

        -- kotlinc-native -list-targets
        local target_plat = toolchain:plat()
        local target_arch = toolchain:arch()
        if target_plat and target_arch and is_cross(target_plat, target_arch) then
            if target_plat == "macosx" then
                target_plat = "macos"
            elseif target_plat == "iphoneos" then
                target_plat = "ios"
                local simulator = toolchain:config("appledev") == "simulator"
                if simulator then
                    target_plat = target_plat .. "_simulator"
                end
            elseif target_plat == "appletvos" then
                target_plat = "tvos"
                local simulator = toolchain:config("appledev") == "simulator"
                if simulator then
                    target_plat = target_plat .. "_simulator"
                end
            elseif target_plat == "harmony" then
                -- we need to port kotlin-native source code to add ohos_arm64 target support
                target_plat = "ohos"
            end
            if target_arch == "x86_64" then
                target_arch = "x64"
            elseif target_arch == "i386" then
                target_arch = "x86"
            elseif target_arch == "arm64-v8a" then
                target_arch = "arm64"
            elseif target_arch == "armeabi-v7a" then
                target_arch = "arm32"
            end
            local target = target_plat .. "_" .. target_arch
            toolchain:add("kcflags", {"-target", target})
        else
            toolchain:set("kcshflags", "")
            toolchain:set("kcldflags", "")
        end
    end)
