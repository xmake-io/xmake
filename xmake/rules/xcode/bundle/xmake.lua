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

-- define rule: xcode bundle
rule("xcode.bundle")

    -- support add_files("Info.plist")
    add_deps("xcode.info_plist")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)

        -- get bundle directory
        local targetdir = target:targetdir()
        local bundledir = path.join(targetdir, target:basename() .. ".bundle")
        target:data_set("xcode.bundle.rootdir", bundledir)

        -- get contents and resources directory
        local contentsdir = bundledir
        local resourcesdir = bundledir
        if is_plat("macosx") then
            contentsdir = path.join(bundledir, "Contents")
            resourcesdir = path.join(bundledir, "Contents", "Resources")
        end
        target:data_set("xcode.bundle.contentsdir", contentsdir)
        target:data_set("xcode.bundle.resourcesdir", resourcesdir)

        -- set target info for bundle
        target:set("filename", target:basename())

        -- generate binary as bundle, we cannot set `-shared` or `-dynamiclib`
        target:set("kind", "binary")
        target:add("ldflags", "-bundle", {force = true})

        -- register clean files for `xmake clean`
        target:add("cleanfiles", bundledir)
    end)

    after_build(function (target, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.depend")
        import("private.tools.codesign")
        import("private.utils.progress")

        -- get bundle and resources directory
        local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
        local contentsdir = path.absolute(target:data("xcode.bundle.contentsdir"))
        local resourcesdir = path.absolute(target:data("xcode.bundle.resourcesdir"))

        -- do build if changed
        depend.on_changed(function ()

            -- trace progress info
            progress.show(opt.progress, "${color.build.target}generating.xcode.$(mode) %s", path.filename(bundledir))

            -- copy target file
            if is_plat("macosx") then
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
            codesign(bundledir, target:values("xcode.codesign_identity") or get_config("xcode_codesign_identity"))

        end, {dependfile = target:dependfile(bundledir), files = {bundledir, target:targetfile()}})
    end)

    on_install(function (target)
        local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
        local installdir = target:installdir()
        if not os.isdir(installdir) then
            os.mkdir(installdir)
        end
        os.vcp(bundledir, installdir)
    end)

    on_uninstall(function (target)
        local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
        local installdir = target:installdir()
        os.tryrm(path.join(installdir, path.filename(bundledir)))
    end)

    -- disable package
    on_package(function (target) end)

