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
-- @file        android.lua
--

-- imports
import("core.theme.theme")
import("core.base.option")
import("core.base.semver")
import("core.project.config")
import("core.project.depend")
import("core.tool.toolchain")
import("lib.detect.find_file")
import("utils.progress")

-- escape path
function _escape_path(p)
    return os.args(p, {escape = true})
end

-- deploy application package for android
function main(target, opt)

    -- get ndk toolchain
    local toolchain_ndk = toolchain.load("ndk", {plat = target:plat(), arch = target:arch()})

    -- get target apk path
    local target_apk = path.join(target:targetdir(), target:basename() .. ".apk")

    -- need re-generate this apk?
    local targetfile = target:targetfile()
    local dependfile = target:dependfile(target_apk)
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(dependfile)}) then
        return
    end

    -- trace progress info
    progress.show(opt.progress, "${color.build.target}generating.qt.app %s.apk", target:basename())

    -- get qt sdk
    local qt = target:data("qt")

    -- get ndk
    local ndk = path.translate(assert(toolchain_ndk:config("ndk"), "cannot get NDK!"))
    local ndk_sdkver = assert(toolchain_ndk:config("ndk_sdkver"), "cannot get the sdk version of NDK!")

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
    if not os.isexec(androiddeployqt) and qt.bindir_host then
        androiddeployqt = path.join(qt.bindir_host, "androiddeployqt" .. (is_host("windows") and ".exe" or ""))
    end
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
    local android_sdkdir = path.translate(assert(toolchain_ndk:config("android_sdk"), "please run `xmake f --android_sdk=xxx` to set the android sdk directory!"))

    -- get android build-tools version
    local android_build_toolver = assert(toolchain_ndk:config("build_toolver"), "please run `xmake f --build_toolver=xxx` to set the android build-tools version!")

    -- get qt sdk version
    local qt_sdkver = config.get("qt_sdkver")
    if qt_sdkver then
        qt_sdkver = try { function () return semver.new(qt_sdkver) end}
    end

    -- get the target architecture
    local target_archs =
    {
        ["armv5te"]     = "armeabi"       -- deprecated
    ,   ["armv7-a"]     = "armeabi-v7a"   -- deprecated
    ,   ["armeabi"]     = "armeabi"
    ,   ["armeabi-v7a"] = "armeabi-v7a"
    ,   ["arm64-v8a"]   = "arm64-v8a"
    ,   i386            = "x86"
    ,   x86_64          = "x86_64"
    ,   mips            = "mips"          -- removed in ndk r71
    ,   mips64          = "mips64"        -- removed in ndk r71
    }
    local target_arch = assert(target_archs[config.arch()], "unsupport target arch(%s)!", config.arch())

    -- install target to android-build/libs first
    if qt_sdkver and qt_sdkver:ge("5.14") then
        -- we need copy target to android-build/libs/armeabi/libxxx_armeabi.so after Qt 5.14.0
        os.cp(target:targetfile(), path.join(android_buildir, "libs", target_arch, "lib" .. target:basename() .. "_" .. target_arch .. ".so"))
    else
        os.cp(target:targetfile(), path.join(android_buildir, "libs", target_arch, path.filename(target:targetfile())))
    end

    -- get stdcpp path
    local stdcpp_path = path.join(ndk, "sources/cxx-stl/llvm-libc++/libs", target_arch, "libc++_shared.so")
    if qt_sdkver and qt_sdkver:ge("5.14") then
        local ndk_sysroot = assert(toolchain_ndk:config("ndk_sysroot"), "NDK sysroot directory not found!")
        stdcpp_path = path.join(ndk_sysroot, "usr", "lib")
    end

    -- get toolchain version
    local ndk_toolchains_ver = toolchain_ndk:config("ndk_toolchains_ver") or "4.9"

    -- generate android-deployment-settings.json file
    local android_deployment_settings = path.join(workdir, "android-deployment-settings.json")
    local settings_file = io.open(android_deployment_settings, "w")
    if settings_file then
        settings_file:print('{')
        settings_file:print('   "description": "This file is generated by qmake to be read by androiddeployqt and should not be modified by hand.",')
        settings_file:print('   "qt": "%s",', _escape_path(qt.sdkdir))
        settings_file:print('   "sdk": "%s",', _escape_path(android_sdkdir))
        settings_file:print('   "ndk": "%s",', _escape_path(ndk))
        settings_file:print('   "sdkBuildToolsRevision": "%s",', android_build_toolver)
        settings_file:print('   "toolchain-prefix": "llvm",')
        settings_file:print('   "tool-prefix": "llvm",')
        settings_file:print('   "toolchain-version": "%s",', ndk_toolchains_ver)
        settings_file:print('   "stdcpp-path": "%s",', _escape_path(stdcpp_path))
        settings_file:print('   "ndk-host": "%s",', ndk_host)
        settings_file:print('   "target-architecture": "%s",', target_arch)
        settings_file:print('   "qml-root-path": "%s",', _escape_path(os.projectdir()))
        -- for 6.2.x
        local qmlimportscanner = path.join(qt.libexecdir, "qmlimportscanner")
        if not os.isexec(qmlimportscanner) and qt.libexecdir_host then
            qmlimportscanner = path.join(qt.libexecdir_host, "qmlimportscanner")
        end
        if os.isexec(qmlimportscanner) then
            settings_file:print('   "qml-importscanner-binary": "%s",', _escape_path(qmlimportscanner))
        end
        -- for 6.3.x
        local rcc = path.join(qt.bindir, "rcc")
        if not os.isexec(rcc) and qt.bindir_host then
            rcc = path.join(qt.bindir_host, "rcc")
        end
        if os.isexec(rcc) then
            settings_file:print('   "rcc-binary": "%s",', _escape_path(rcc))
        end
        local platformplugin = find_file("libplugins_platforms_qtforandroid_" .. target_arch .. "*", path.join(qt.sdkdir, "plugins", "platforms"))
        if platformplugin then
            settings_file:print('   "deployment-dependencies": {"%s":"%s"},', target_arch, _escape_path(platformplugin))
        end

        local minsdkversion = target:values("qt.android.minsdkversion")
        if minsdkversion then
            settings_file:print('    "android-min-sdk-version": "%s",', tostring(minsdkversion))
        end
        local targetsdkversion = target:values("qt.android.targetsdkversion")
        if targetsdkversion then
            settings_file:print('    "android-target-sdk-version": "%s",', tostring(targetsdkversion))
        end
        settings_file:print('   "useLLVM": true,')
        if qt_sdkver and qt_sdkver:ge("5.14") then
            -- @see https://codereview.qt-project.org/c/qt-creator/qt-creator/+/287145
            local triples =
            {
                ["armv5te"]     = "arm-linux-androideabi"   -- deprecated
            ,   ["armv7-a"]     = "arm-linux-androideabi"   -- deprecated
            ,   ["armeabi"]     = "arm-linux-androideabi"   -- removed in ndk r17
            ,   ["armeabi-v7a"] = "arm-linux-androideabi"
            ,   ["arm64-v8a"]   = "aarch64-linux-android"
            ,   i386            = "i686-linux-android"      -- deprecated
            ,   x86             = "i686-linux-android"
            ,   x86_64          = "x86_64-linux-android"
            ,   mips            = "mips-linux-android"      -- removed in ndk r17
            ,   mips64          = "mips64-linux-android"    -- removed in ndk r17
            }
            settings_file:print('   "architectures": {"%s":"%s"},', target_arch, triples[target_arch])
            settings_file:print('   "application-binary": "%s"', target:basename())
        else
            settings_file:print('   "application-binary": "%s"', _escape_path(target:targetfile()))
        end
        settings_file:print('}')
        settings_file:close()
    end
    if option.get("verbose") and option.get("diagnosis") then
        io.cat(android_deployment_settings)
    end

    -- do deploy
    local argv = {"--input", android_deployment_settings,
                  "--output", android_buildir,
                  "--jdk", java_home,
                  "--gradle", "--no-gdbserver"}
    if option.get("verbose") and option.get("diagnosis") then
        table.insert(argv, "--verbose")
    end

    -- add user flags
    local user_flags = target:values("qt.deploy.flags") or {}
    if user_flags then
        argv = table.join(argv, user_flags)
    end

    os.vrunv(androiddeployqt, argv)

    -- output apk
    os.cp(path.join(android_buildir, "build", "outputs", "apk", "debug", "android-build-debug.apk"), target_apk)

    -- show apk output path
    vprint("the apk output path: %s", target_apk)

    -- update files and values to the dependent file
    dependinfo.files = {targetfile}
    depend.save(dependinfo, dependfile)
end

