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
rule("xcode.info_plist")

    -- support add_files("Info.plist")
    set_extensions(".plist")

    -- build Info.plist
    on_build_file(function (target, sourcefile, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.depend")
        import("core.tool.toolchain")
        import("utils.progress")

        -- check
        assert(path.filename(sourcefile) == "Info.plist", "we only support Info.plist file!")

        -- get contents and resources directory
        local contentsdir = assert(target:data("xcode.bundle.contentsdir"), "contents directory not found!")
        local resourcesdir = assert(target:data("xcode.bundle.resourcesdir"), "resources directory not found!")

        -- need re-compile it?
        local dependfile = target:dependfile(sourcefile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(dependfile)}) then
            return
        end

        -- trace progress info
        progress.show(opt.progress, "${color.build.object}processing.xcode.$(mode) %s", sourcefile)

        -- process and generate Info.plist
        -- https://github.com/xmake-io/xmake/issues/2765#issuecomment-1251738622
        local info_plist_file
        if target:rule("xcode.framework") and target:is_plat("macosx") then
            info_plist_file = path.join(resourcesdir, path.filename(sourcefile))
        else
            info_plist_file = path.join(contentsdir, path.filename(sourcefile))
        end
        local maps =
        {
            DEVELOPMENT_LANGUAGE = "en",
            EXECUTABLE_NAME = target:basename(),
            PRODUCT_BUNDLE_IDENTIFIER = target:values("xcode.bundle_identifier") or get_config("xcode_bundle_identifier") or "io.xmake." .. target:name(),
            PRODUCT_NAME = target:name(),
            PRODUCT_DISPLAY_NAME = target:name(),
            CURRENT_PROJECT_VERSION = target:version() and tostring(target:version()) or "1.0",
        }
        if target:is_plat("macosx") then
            local toolchain_xcode = toolchain.load("xcode", {plat = target:plat(), arch = target:arch()})
            if toolchain_xcode then
                maps.MACOSX_DEPLOYMENT_TARGET = toolchain_xcode:config("target_minver")
            end
        end
        if target:rule("xcode.bundle") then
            maps.PRODUCT_BUNDLE_PACKAGE_TYPE = "BNDL"
        elseif target:rule("xcode.framework") then
            maps.PRODUCT_BUNDLE_PACKAGE_TYPE = "FMWK"
        elseif target:rule("xcode.application") then
            maps.PRODUCT_BUNDLE_PACKAGE_TYPE = "APPL"
        end

        os.vcp(sourcefile, info_plist_file)
        io.gsub(info_plist_file, "(%$%((.-)%))", function (_, variable)
            return maps[variable]
        end)

        -- patch some entries for mac catalyst
        local xcode = target:toolchain("xcode")
        if xcode and xcode:config("appledev") == "catalyst" then
            -- remove entry for "LSRequiresIPhoneOS" - not supported on macOS
            --
            -- <key>LSRequiresIPhoneOS</key>
            -- <true/>
            io.replace(info_plist_file, "<key>LSRequiresIPhoneOS</key>.-<true/>", "")
        end

        -- update files and values to the dependent file
        dependinfo.files = {sourcefile}
        depend.save(dependinfo, dependfile)
    end)
