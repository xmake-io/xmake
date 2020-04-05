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
import("lib.detect.find_path")

-- deploy application package for macosx
function main(target, opt)

    -- trace progress info
    cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", opt.progress)
    if option.get("verbose") then
        cprint("${dim color.build.target}generating.qt.app %s.app", target:basename())
    else
        cprint("${color.build.target}generating.qt.app %s.app", target:basename())
    end

    -- get qt sdk
    local qt = target:data("qt")

    -- get macdeployqt
    local macdeployqt = path.join(qt.bindir, "macdeployqt")
    assert(os.isexec(macdeployqt), "macdeployqt not found!")

    -- generate target app 
    local target_app = path.join(target:targetdir(), target:basename() .. ".app")
    local target_contents = path.join(target_app, "Contents")
    os.tryrm(target_app)
    os.cp(target:targetfile(), path.join(target_contents, "MacOS", target:basename()))
    os.cp(path.join(os.programdir(), "scripts", "PkgInfo"), target_contents)

    -- TODO generate Info.plist and codesign

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
    os.vrunv(macdeployqt, argv)
end

