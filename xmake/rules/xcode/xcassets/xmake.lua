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
rule("xcode.xcassets")

    -- support add_files("*.xcassets")
    set_extensions(".xcassets")

    -- build *.xcassets
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

        -- get resources directory
        local resourcesdir = assert(target:data("xcode.bundle.resourcesdir"), "resources directory not found!")

        -- need re-compile it?
        local dependfile = target:dependfile(sourcefile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(dependfile)}) then
            return
        end

        -- ensure resources directory exists
        if not os.isdir(resourcesdir) then
            os.mkdir(resourcesdir)
        end

        -- trace progress info
        progress.show(opt.progress, "${color.build.object}compiling.xcode.$(mode) %s", sourcefile)

        -- get assetcatalog_generated_info.plist
        local assetcatalog_generated_info_plist = path.join(target:autogendir(), "rules", "xcode", "xcassets", "assetcatalog_generated_info.plist")
        io.writefile(assetcatalog_generated_info_plist, "")

        -- do compile
        local target_minver = nil
        local toolchain_xcode = toolchain.load("xcode", {plat = target:plat(), arch = target:arch()})
        if toolchain_xcode then
            target_minver = toolchain_xcode:config("target_minver")
        end
        local argv = {"--warnings", "--notices", "--output-format", "human-readable-text"}
        if target:is_plat("macosx") then
            table.insert(argv, "--target-device")
            table.insert(argv, "mac")
            table.insert(argv, "--platform")
            table.insert(argv, "macosx")
        elseif target:is_plat("iphoneos") then
            table.insert(argv, "--target-device")
            table.insert(argv, "iphone")
            table.insert(argv, "--target-device")
            table.insert(argv, "ipad")
            table.insert(argv, "--platform")
            table.insert(argv, "iphoneos")
        else
            assert("unknown device!")
        end
        if target_minver then
            table.insert(argv, "--minimum-deployment-target")
            table.insert(argv, target_minver)
        end
        table.insert(argv, "--app-icon")
        table.insert(argv, "AppIcon")
        if target:is_plat("iphoneos") then
            table.insert(argv, "--enable-on-demand-resources")
            table.insert(argv, "YES")
            table.insert(argv, "--compress-pngs")
        else
            table.insert(argv, "--enable-on-demand-resources")
            table.insert(argv, "NO")
        end
        table.insert(argv, "--output-partial-info-plist")
        table.insert(argv, assetcatalog_generated_info_plist)
        table.insert(argv, "--development-region")
        table.insert(argv, "en")
        table.insert(argv, "--product-type")
        table.insert(argv, "com.apple.product-type.application")
        table.insert(argv, "--compile")
        table.insert(argv, resourcesdir)
        table.insert(argv, sourcefile)
        os.vrunv(path.join(xcode_usrdir, "bin", "actool"), argv)

        -- update files and values to the dependent file
        dependinfo.files = {sourcefile}
        depend.save(dependinfo, dependfile)
    end)
