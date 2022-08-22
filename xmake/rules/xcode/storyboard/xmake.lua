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

-- define rule
rule("xcode.storyboard")

    -- support add_files("*.storyboard")
    set_extensions(".storyboard")

    -- build *.storyboard
    on_build_file(function (target, sourcefile, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.depend")
        import("core.tool.toolchain")
        import("utils.progress")

        -- get xcode sdk directory
        local xcode_sdkdir = assert(get_config("xcode"), "xcode not found!")
        local xcode_usrdir = path.join(xcode_sdkdir, "Contents", "Developer", "usr")

        -- get base.lproj
        local base_lproj = path.join(target:autogendir(), "rules", "xcode", "storyboard", "Base.lproj")

        -- get resources directory
        local resourcesdir = assert(target:data("xcode.bundle.resourcesdir"), "resources directory not found!")

        -- need re-compile it?
        local dependfile = target:dependfile(sourcefile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(dependfile)}) then
            return
        end

        -- trace progress info
        progress.show(opt.progress, "${color.build.object}compiling.xcode.$(mode) %s", sourcefile)

        -- clear Base.lproj first
        os.tryrm(base_lproj)

        -- do compile
        local target_minver = nil
        local toolchain_xcode = toolchain.load("xcode", {plat = target:plat(), arch = target:arch()})
        if toolchain_xcode then
            target_minver = toolchain_xcode:config("target_minver")
        end
        local argv = {"--errors", "--warnings", "--notices", "--auto-activate-custom-fonts", "--output-format", "human-readable-text"}
        if target:is_plat("macosx") then
            local xcode = target:toolchain("xcode")
            if xcode and xcode:config("appledev") == "catalyst" then
                table.insert(argv, "--platform")
                table.insert(argv, "macosx")
                table.insert(argv, "--target-device")
                table.insert(argv, "ipad")
            else
                table.insert(argv, "--target-device")
                table.insert(argv, "mac")
            end
        elseif target:is_plat("iphoneos") then
            table.insert(argv, "--target-device")
            table.insert(argv, "iphone")
            table.insert(argv, "--target-device")
            table.insert(argv, "ipad")
        else
            assert("unknown device!")
        end
        if target_minver then
            table.insert(argv, "--minimum-deployment-target")
            table.insert(argv, target_minver)
        end
        table.insert(argv, "--compilation-directory")
        table.insert(argv, base_lproj)
        table.insert(argv, sourcefile)
        os.vrunv(path.join(xcode_usrdir, "bin", "ibtool"), argv, {envs = {XCODE_DEVELOPER_USR_PATH = xcode_usrdir}})

        -- do link
        argv = {"--errors", "--warnings", "--notices", "--auto-activate-custom-fonts", "--output-format", "human-readable-text"}
        if target:is_plat("macosx") then
            table.insert(argv, "--target-device")
            table.insert(argv, "mac")
        end
        if target_minver then
            table.insert(argv, "--minimum-deployment-target")
            table.insert(argv, target_minver)
        end
        table.insert(argv, "--link")
        table.insert(argv, resourcesdir)
        table.insert(argv, path.join(base_lproj, path.filename(sourcefile) .. "c"))
        os.vrunv(path.join(xcode_usrdir, "bin", "ibtool"), argv, {envs = {XCODE_DEVELOPER_USR_PATH = xcode_usrdir}})

        -- update files and values to the dependent file
        dependinfo.files = {sourcefile}
        depend.save(dependinfo, dependfile)
    end)
