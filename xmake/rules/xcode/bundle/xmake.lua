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

-- define rule: xcode bundle
rule("xcode.bundle")

    -- support add_files("Info.plist")
    add_deps("xcode.info_plist")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)

        -- get bundle directory
        local targetdir = target:targetdir()
        local bundledir = path.join(targetdir, target:basename() .. ".bundle")
        target:data_set("xcode.bundle.rootdir", bundledir)

        -- get contents and resources directory
        local contentsdir = bundledir
        local resourcesdir = bundledir
        if target:is_plat("macosx") then
            contentsdir = path.join(bundledir, "Contents")
            resourcesdir = path.join(bundledir, "Contents", "Resources")
        end
        target:data_set("xcode.bundle.contentsdir", contentsdir)
        target:data_set("xcode.bundle.resourcesdir", resourcesdir)

        -- register clean files for `xmake clean`
        target:add("cleanfiles", bundledir)

        -- generate binary as bundle, we cannot set `-shared` or `-dynamiclib`
        target:set("kind", "binary")

        -- set target info for bundle
        target:set("filename", target:basename())
    end)

    on_config(function (target)
        -- add bundle flags
        local linker = target:linker():name()
        if linker == "swiftc" then
            target:add("ldflags", "-Xlinker -bundle", {force = true})
        else
            target:add("ldflags", "-bundle", {force = true})
        end
    end)

    after_build(function (target, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.depend")
        import("private.tools.codesign")
        import("utils.progress")

        -- get bundle and resources directory
        local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
        local contentsdir = path.absolute(target:data("xcode.bundle.contentsdir"))
        local resourcesdir = path.absolute(target:data("xcode.bundle.resourcesdir"))

        -- do build if changed
        depend.on_changed(function ()

            -- trace progress info
            progress.show(opt.progress, "${color.build.target}generating.xcode.$(mode) %s", path.filename(bundledir))

            -- copy target file
            if target:is_plat("macosx") then
                os.vcp(target:targetfile(), path.join(contentsdir, "MacOS", path.filename(target:targetfile())))
            else
                os.vcp(target:targetfile(), path.join(contentsdir, path.filename(target:targetfile())))
            end

            -- copy resource files
            local srcfiles, dstfiles = target:installfiles(resourcesdir)
            if srcfiles and dstfiles then
                local i = 1
                for _, srcfile in ipairs(srcfiles) do
                    local dstfile = dstfiles[i]
                    if dstfile then
                        os.vcp(srcfile, dstfile)
                    end
                    i = i + 1
                end
            end

            -- do codesign
            local codesign_identity = target:values("xcode.codesign_identity") or get_config("xcode_codesign_identity")
            if target:is_plat("macosx") or (target:is_plat("iphoneos") and target:is_arch("x86_64", "i386")) then
                codesign_identity = nil
            end
            codesign(bundledir, codesign_identity)

        end, {dependfile = target:dependfile(bundledir), files = {bundledir, target:targetfile()}})
    end)

    on_install(function (target)
        local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
        local installdir = target:installdir()
        if installdir then
            if not os.isdir(installdir) then
                os.mkdir(installdir)
            end
            os.vcp(bundledir, installdir)
        end
    end)

    on_uninstall(function (target)
        local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
        local installdir = target:installdir()
        os.tryrm(path.join(installdir, path.filename(bundledir)))
    end)

    -- disable package
    on_package(function (target) end)

