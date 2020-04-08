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
-- @file        build_file.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.project.depend")

-- build *.xcassets file
function _build_xcassets_file(target, sourcefile, opt)
    -- TODO
end

-- build *.storyboard file
function _build_storyboard_file(target, sourcefile, opt)

    -- get xcode sdk directory
    local xcode_sdkdir = assert(get_config("xcode"), "xcode not found!")
    local xcode_usrdir = path.join(xcode_sdkdir, "Contents", "Developer", "usr")

    -- get base.lproj
    local base_lproj = path.join(target:autogendir(), "rules", "xcode", "storyboard", "Base.lproj")

    -- get app resources directory
    local resourcesdir = target:data("xcode.app.resourcesdir")

    -- need re-compile it?
    local dependfile = target:dependfile(sourcefile)
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(dependfile)}) then
        return 
    end
    
    -- trace progress info
    cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", opt.progress)
    if option.get("verbose") then
        cprint("${dim color.build.object}compiling.xcode.storyboard %s", sourcefile)
    else
        cprint("${color.build.object}compiling.xcode.storyboard %s", sourcefile)
    end

    -- do compile
    local argv = {"--errors", "--warnings", "--notices", "--auto-activate-custom-fonts", "--output-format", "human-readable-text"}
    if is_plat("macosx") then
        table.insert(argv, "--target-device")
        table.insert(argv, "mac")
    end
    table.insert(argv, "--minimum-deployment-target")
    table.insert(argv, get_config("target_minver"))
    table.insert(argv, "--compilation-directory")
    table.insert(argv, base_lproj)
    table.insert(argv, sourcefile)
    os.vrunv(path.join(xcode_usrdir, "bin", "ibtool"), argv, {envs = {XCODE_DEVELOPER_USR_PATH = xcode_usrdir}})

    -- do link
    argv = {"--errors", "--warnings", "--notices", "--auto-activate-custom-fonts", "--output-format", "human-readable-text"}
    if is_plat("macosx") then
        table.insert(argv, "--target-device")
        table.insert(argv, "mac")
    end
    table.insert(argv, "--minimum-deployment-target")
    table.insert(argv, get_config("target_minver"))
    table.insert(argv, "--link")
    table.insert(argv, resourcesdir)
    table.insert(argv, path.join(base_lproj, path.filename(sourcefile) .. "c"))
    os.vrunv(path.join(xcode_usrdir, "bin", "ibtool"), argv, {envs = {XCODE_DEVELOPER_USR_PATH = xcode_usrdir}})

    -- update files and values to the dependent file
    dependinfo.files = {sourcefile}
    depend.save(dependinfo, dependfile)
end

-- main entry
function main (target, sourcefile, opt)
    if sourcefile:endswith(".xcassets") then
        _build_xcassets_file(target, sourcefile, opt)
    elseif sourcefile:endswith(".storyboard") then
        _build_storyboard_file(target, sourcefile, opt)
    end
end
