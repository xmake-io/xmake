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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        macosx.lua
--

-- imports
import("core.theme.theme")
import("core.base.option")
import("core.project.config")
import("core.project.depend")
import("lib.detect.find_path")
import("private.utils.progress")

-- save Info.plist
function _save_info_plist(target, info_plist_file)

    local name = target:basename()
    io.writefile(info_plist_file, string.format([[<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>BuildMachineOSBuild</key>
	<string>18G95</string>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>%s</string>
	<key>CFBundleExecutable</key>
	<string>%s</string>
	<key>CFBundleIdentifier</key>
	<string>org.example.%s</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>%s</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1.0.0</string>
	<key>LSMinimumSystemVersion</key>
	<string>%s</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>]], name, name, name, name, get_config("target_minver_macosx") or (macos.version():major() .. "." .. macos.version():minor())))
end

-- deploy application package for macosx
function main(target, opt)

    -- need re-generate this app?
    local target_app = path.join(target:targetdir(), target:basename() .. ".app")
    local targetfile = target:targetfile()
    local dependfile = target:dependfile(target_app)
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(dependfile)}) then
        return
    end

    -- trace progress info
    progress.show(opt.progress, "${color.build.target}generating.qt.app %s.app", target:basename())

    -- get qt sdk
    local qt = target:data("qt")

    -- get macdeployqt
    local macdeployqt = path.join(qt.bindir, "macdeployqt")
    assert(os.isexec(macdeployqt), "macdeployqt not found!")

    -- generate target app
    local target_contents = path.join(target_app, "Contents")
    os.tryrm(target_app)
    os.cp(target:targetfile(), path.join(target_contents, "MacOS", target:basename()))
    os.cp(path.join(os.programdir(), "scripts", "PkgInfo"), target_contents)

    -- generate Info.plist
    _save_info_plist(target, path.join(target_contents, "Info.plist"))

    -- find qml directory
    local qmldir = nil
    for _, sourcebatch in pairs(target:sourcebatches()) do
        if sourcebatch.rulename == "qt.qrc" then
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                qmldir = find_path("*.qml", path.directory(sourcefile))
                if qmldir then
                    break
                end
            end
        end
    end

    -- do deploy
    local argv = {target_app, "-always-overwrite"}
    if option.get("diagnosis") then
        table.insert(argv, "-verbose=3")
    elseif option.get("verbose") then
        table.insert(argv, "-verbose=1")
    else
        table.insert(argv, "-verbose=0")
    end
    if qmldir then
        table.insert(argv, "-qmldir=" .. qmldir)
    end
    local codesign_identity = target:values("xcode.codesign_identity") or get_config("xcode_codesign_identity")
    if codesign_identity then
        -- e.g. "Apple Development: waruqi@gmail.com (T3NA4MRVPU)"
        table.insert(argv, "-codesign=" .. codesign_identity)
    end
    os.vrunv(macdeployqt, argv)

    -- update files and values to the dependent file
    dependinfo.files = {targetfile}
    depend.save(dependinfo, dependfile)
end

