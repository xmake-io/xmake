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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: qt static library
rule("qt.static")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", "static")
    end)

    -- after load
    after_load(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

-- define rule: qt shared library
rule("qt.shared")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", "shared")
    end)

    -- after load
    after_load(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

-- define rule: qt console
rule("qt.console")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", "binary")
    end)

    -- after load
    after_load(function (target)
        import("load")(target, {frameworks = {"QtCore"}})
    end)

-- define rule: qt application
rule("qt.application")

    -- add rules
    add_deps("qt.qrc", "qt.ui", "qt.moc")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        target:set("kind", is_plat("android") and "shared" or "binary")
    end)

    -- after load
    after_load(function (target)

        -- load common flags to target
        import("load")(target, {frameworks = {"QtGui", "QtQml", "QtNetwork", "QtCore"}})

        -- add -subsystem:windows for windows platform
        if is_plat("windows") then
            target:add("defines", "_WINDOWS")
            target:add("ldflags", "-subsystem:windows", "-entry:mainCRTStartup", {force = true})
        elseif is_plat("mingw") then
            target:add("ldflags", "-Wl,-subsystem:windows", {force = true})
        end
    end)

    -- after build for android
    after_build("android", function (target, opt)

        -- imports
        import("core.theme.theme")
        import("core.base.option")
        import("core.project.config")

        -- get target apk path
        local target_apk = path.join(path.directory(target:targetfile()), target:basename() .. ".apk")

        -- trace progress info
        cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", opt.progress)
        if option.get("verbose") then
            cprint("${dim color.build.target}generating.qt.app %s.apk", target:basename())
        else
            cprint("${color.build.target}generating.qt.app %s.apk", target:basename())
        end

        -- get qt sdk
        local qt = target:data("qt")

        -- get ndk
        local ndk = path.translate(assert(config.get("ndk"), "cannot get NDK!"))
        local ndk_sdkver = assert(config.get("ndk_sdkver"), "cannot get the sdk version of NDK!")

        -- get ndk host
        local ndk_host = os.host() .. "-" .. os.arch()
        if is_host("windows") then
            ndk_host = os.arch() == "x64" and "windows-x86_64" or "windows-x86"
        elseif is_host("macosx") then
            ndk_host = "darwin-x86_64"
        elseif is_host("linux") then
            ndk_host = "linux-x86_64"
        end

        -- get androiddeployqt
        local androiddeployqt = path.join(qt.bindir, "androiddeployqt" .. (is_host("windows") and ".exe" or ""))
        assert(os.isexec(androiddeployqt), "androiddeployqt not found!")

        -- get working directory
        local workdir = path.join(config.buildir(), ".qt", "app", "android", target:name())

        -- get android-build directory
        local android_buildir = path.join(workdir, "android-build")

        -- get android platform
        local android_platform = "android-" .. tostring(ndk_sdkver)

        -- get java home
        local java_home = assert(os.getenv("JAVA_HOME"), "please set $JAVA_HOME environment variable first!")

        -- get android sdk directory
        local android_sdkdir = path.translate(assert(config.get("android_sdk"), "please run `xmake f --android_sdk=xxx` to set the android sdk directory!"))

        -- get android build-tools version
        local android_build_toolver = assert(config.get("build_toolver"), "please run `xmake f --build_toolver=xxx` to set the android build-tools version!")

        -- get the target architecture
        local target_archs = 
        {
            ["armv5te"]     = "armeabi"
        ,   ["armv7-a"]     = "armeabi-v7a"
        ,   ["arm64-v8a"]   = "arm64-v8a"
        ,   i386            = "x86"
        ,   x86_64          = "x86_64"
        ,   mips            = "mips"
        ,   mips64          = "mips64"
        }
        local target_arch = assert(target_archs[config.arch()], "unsupport target arch(%s)!", config.arch())

        -- install target to android-build/libs first
        os.cp(target:targetfile(), path.join(android_buildir, "libs", target_arch, path.filename(target:targetfile())))

        -- get stdcpp path
        local stdcpp_path = path.join(ndk, "sources/cxx-stl/llvm-libc++/libs", target_arch, "libc++_shared.so")

        -- get toolchain version
        local ndk_toolchains_ver = config.get("ndk_toolchains_ver") or "4.9"

        -- generate android-deployment-settings.json file
        local android_deployment_settings = path.join(workdir, "android-deployment-settings.json")
        io.writefile(android_deployment_settings, format([[
        {
           "description": "This file is generated by qmake to be read by androiddeployqt and should not be modified by hand.",
           "qt": "%s",
           "sdk": "%s",
           "ndk": "%s",
           "sdkBuildToolsRevision": "%s",
           "toolchain-prefix": "llvm",
           "tool-prefix": "llvm",
           "toolchain-version": "%s",
           "ndk-host": "%s",
           "target-architecture": "%s",
           "qml-root-path": "%s",
           "stdcpp-path": "%s",
           "useLLVM": true,
           "application-binary": "%s"
        }]], qt.sdkdir, android_sdkdir, ndk, android_build_toolver, ndk_toolchains_ver, ndk_host, target_arch, os.projectdir(), stdcpp_path, target:targetfile()))

        -- do deploy
        local argv = {"--input", android_deployment_settings,
                      "--output", android_buildir,
                      "--android-platform", android_platform,
                      "--jdk", java_home,
                      "--gradle", "--no-gdbserver"}
        os.vrunv(androiddeployqt, argv)

        -- output apk
        os.cp(path.join(android_buildir, "build", "outputs", "apk", "debug", "android-build-debug.apk"), target_apk)

        -- show apk output path
        vprint("the apk output path: %s", target_apk)
    end)

    -- on install for android
    on_install("android", function (target, opt)

        -- get target apk path
        local target_apk = path.join(path.directory(target:targetfile()), target:basename() .. ".apk")
        assert(os.isfile(target_apk), "apk not found, please build %s first!", target:name())

        -- show install info
        print("installing %s ..", target_apk)

        -- get android sdk directory
        local android_sdkdir = path.translate(assert(get_config("android_sdk"), "please run `xmake f --android_sdk=xxx` to set the android sdk directory!"))

        -- get adb
        local adb = path.join(android_sdkdir, "platform-tools", "adb" .. (is_host("windows") and ".exe" or ""))
        if not os.isexec(adb) then
            adb = "adb"
        end

        -- install apk to device
        os.execv(adb, {"install", "-r", target_apk})
    end)
