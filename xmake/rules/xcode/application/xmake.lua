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
-- @file        xmake.lua
--

-- define rule: xcode application (TODO developing)
rule("xcode.application")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        
        -- get app directory
        local targetdir = target:targetdir()
        local appdir = path.join(targetdir, target:basename() .. ".app")
        target:data_set("xcode.appdir", appdir)

        -- set target info for app 
        target:set("kind", "binary")
        target:set("filename", target:basename())
        if is_plat("macosx") then
            target:set("targetdir", path.join(appdir, "Contents", "MacOS"))
        else
            target:set("targetdir", appdir)
        end

        -- add frameworks
        if is_plat("macosx") then
            target:add("frameworks", "AppKit")
        else
            target:add("frameworks", "UIKit")
        end

        -- register clean files for `xmake clean`
        target:add("cleanfiles", appdir)
    end)

    after_build(function (target)

        -- imports
        import("private.tools.codesign")

        -- generate Info.plist
        local function _gen_info_plist(info_plist_file)
            io.gsub(info_plist_file, "(%$%((.-)%))", function (_, variable)
                local maps = 
                {
                    DEVELOPMENT_LANGUAGE = "en",
                    EXECUTABLE_NAME = target:basename(),
                    PRODUCT_BUNDLE_IDENTIFIER = "org.tboox." .. target:name(),
                    PRODUCT_NAME = target:name(),
                    PRODUCT_BUNDLE_PACKAGE_TYPE = "APPL", -- application
                    CURRENT_PROJECT_VERSION = target:version() and tostring(target:version()) or "1.0",
                    MACOSX_DEPLOYMENT_TARGET = get_config("target_minver")
                }
                return maps[variable]
            end)
        end

        -- get app directory
        local appdir = path.absolute(target:data("xcode.appdir"))

        -- get contents directory
        local contentsdir = appdir
        if is_plat("macosx") then
            contentsdir = path.join(appdir, "Contents")
        end

        -- copy PkgInfo to the contents directory
        os.cp(path.join(os.programdir(), "scripts", "PkgInfo"), contentsdir)

        -- copy resource files to the contents directory
        local srcfiles, dstfiles = target:installfiles(contentsdir)
        if srcfiles and dstfiles then
            local i = 1
            for _, srcfile in ipairs(srcfiles) do
                local dstfile = dstfiles[i]
                if dstfile then
                    os.vcp(srcfile, dstfile)
                    if path.filename(srcfile) == "Info.plist" then
                        _gen_info_plist(dstfile)
                    end
                end
                i = i + 1
            end
        end

        -- do codesign
        codesign(appdir, target:values("xcode.codesign_identity") or get_config("xcode_codesign_identity"))
    end)

    on_install(function (target)
        local appdir = path.absolute(target:data("xcode.appdir"))
        local installdir = target:installdir()
        if not os.isdir(installdir) then
            os.mkdir(installdir)
        end
        os.vcp(appdir, installdir)
    end)

    on_uninstall(function (target)
        local appdir = path.absolute(target:data("xcode.appdir"))
        local installdir = target:installdir()
        os.tryrm(path.join(installdir, path.filename(appdir)))
    end)

    -- disable package
    on_package(function (target) end)

