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

-- define rule: xcode framework
rule("xcode.framework")

    -- support add_files("Info.plist")
    add_deps("xcode.info_plist")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    on_load(function (target)

        -- get framework directory
        local targetdir = target:targetdir()
        local bundledir = path.join(targetdir, target:basename() .. ".framework")
        target:data_set("xcode.bundle.rootdir", bundledir)

        -- get contents and resources directory
        local contentsdir = target:is_plat("macosx") and path.join(bundledir, "Versions", "A") or bundledir
        local resourcesdir = path.join(contentsdir, "Resources")
        target:data_set("xcode.bundle.contentsdir", contentsdir)
        target:data_set("xcode.bundle.resourcesdir", resourcesdir)

        -- set target info for framework
        if not target:get("kind") then
            target:set("kind", "shared")
        end
        target:set("filename", target:basename())

        -- export frameworks for `add_deps()`
        target:data_set("inherit.links", false) -- disable to inherit links, @see rule("utils.inherit.links")
        target:add("frameworks", target:basename(), {interface = true})
        target:add("frameworkdirs", targetdir, {interface = true})
        target:add("includedirs", path.join(contentsdir, "Headers.tmp"), {interface = true})

        -- register clean files for `xmake clean`
        target:add("cleanfiles", bundledir)
    end)

    before_build(function (target)

        -- get framework directory
        local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
        local contentsdir = path.absolute(target:data("xcode.bundle.contentsdir"))
        local headersdir = path.join(contentsdir, "Headers.tmp", target:basename())

        -- copy header files to the framework directory
        local srcheaders, dstheaders = target:headerfiles(headersdir)
        if srcheaders and dstheaders then
            local i = 1
            for _, srcheader in ipairs(srcheaders) do
                local dstheader = dstheaders[i]
                if dstheader then
                    os.vcp(srcheader, dstheader)
                end
                i = i + 1
            end
        end
        if not os.isdir(headersdir) then
            os.mkdir(headersdir)
        end
    end)

    after_build(function (target, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.depend")
        import("private.tools.codesign")
        import("utils.progress")

        -- get framework directory
        local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
        local contentsdir = target:data("xcode.bundle.contentsdir")
        local resourcesdir = target:data("xcode.bundle.resourcesdir")
        local headersdir = path.join(contentsdir, "Headers")

        -- do build if changed
        depend.on_changed(function ()

            -- trace progress info
            progress.show(opt.progress, "${color.build.target}generating.xcode.$(mode) %s", path.filename(bundledir))

            -- copy target file
            if not os.isdir(contentsdir) then
                os.mkdir(contentsdir)
            end
            os.vcp(target:targetfile(), contentsdir)

            -- change rpath
            -- @see https://github.com/xmake-io/xmake/issues/2679#issuecomment-1221839215
            local filename = path.filename(target:targetfile())
            local targetfile = path.join(contentsdir, filename)
            local rpath = path.relative(contentsdir, path.directory(bundledir))
            os.vrunv("install_name_tool", {"-id", path.join("@rpath", rpath, filename), targetfile})

            -- move header files
            os.tryrm(headersdir)
            os.mv(path.join(contentsdir, "Headers.tmp", target:basename()), headersdir)
            os.rm(path.join(contentsdir, "Headers.tmp"))

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

            -- link Versions/Current -> Versions/A
            -- only for macos, @see https://github.com/xmake-io/xmake/issues/2765
            if target:is_plat("macosx") then
                local oldir = os.cd(path.join(bundledir, "Versions"))
                os.tryrm("Current")
                os.ln("A", "Current")

                -- link bundledir/* -> Versions/Current/*
                local target_filename = path.filename(target:targetfile())
                os.cd(bundledir)
                os.tryrm("Headers")
                os.tryrm("Resources")
                os.tryrm(target_filename)
                os.tryrm("Info.plist")
                os.ln("Versions/Current/Headers", "Headers")
                if os.isdir(resourcesdir) then
                    os.ln("Versions/Current/Resources", "Resources")
                end
                os.ln(path.join("Versions/Current", target_filename), target_filename)
                os.cd(oldir)
            end

            -- do codesign, only for dynamic library
            if target:is_shared() then
                local codesign_identity = target:values("xcode.codesign_identity") or get_config("xcode_codesign_identity")
                if target:is_plat("macosx") or (target:is_plat("iphoneos") and target:is_arch("x86_64", "i386")) then
                    codesign_identity = nil
                end
                codesign(contentsdir, codesign_identity)
            end
        end, {dependfile = target:dependfile(bundledir), files = {bundledir, target:targetfile()}})
    end)

    on_install(function (target)
        import("xcode.application.build", {alias = "appbuild", rootdir = path.join(os.programdir(), "rules")})
        local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
        local installdir = target:installdir()
        if installdir then
            if not os.isdir(installdir) then
                os.mkdir(installdir)
            end
            os.vcp(bundledir, installdir, {symlink = true})
        end
    end)

    on_uninstall(function (target)
        local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
        local installdir = target:installdir()
        os.tryrm(path.join(installdir, path.filename(bundledir)))
    end)

    -- disable package
    on_package(function (target) end)

