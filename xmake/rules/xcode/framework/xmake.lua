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

-- define rule: xcode framework
rule("xcode.framework")

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        
        -- get framework directory
        local targetdir = target:targetdir()
        local frameworkdir = path.join(targetdir, target:basename() .. ".framework")
        target:data_set("xcode.frameworkdir", frameworkdir)

        -- set target info for framework 
        target:set("kind", "shared")
        target:set("filename", target:basename())
        target:set("targetdir", path.join(frameworkdir, "Versions", "A"))

        -- export frameworks for `add_deps()`
        target:add("frameworks", target:basename(), {interface = true})
        target:add("frameworkdirs", targetdir, {interface = true})

        -- register clean files for `xmake clean`
        target:add("cleanfiles", frameworkdir)
    end)

    after_build(function (target)

        -- get framework directory
        local frameworkdir = path.absolute(target:data("xcode.frameworkdir"))
        local headersdir = path.join(frameworkdir, "Versions", "A", "Headers")
        local resourcesdir = path.join(frameworkdir, "Versions", "A", "Resources")

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

        -- copy resource files to the framework directory
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
        if not os.isdir(resourcesdir) then
            os.mkdir(resourcesdir)
        end

        -- link Versions/Current -> Versions/A
        local oldir = os.cd(path.join(frameworkdir, "Versions"))
        os.tryrm("Current")
        os.ln("A", "Current")

        -- link frameworkdir/* -> Versions/Current/*
        local target_filename = path.filename(target:targetfile())
        os.cd(frameworkdir)
        os.tryrm("Headers")
        os.tryrm("Resources")
        os.tryrm(target_filename)
        os.ln("Versions/Current/Headers", "Headers")
        os.ln("Versions/Current/Resources", "Resources")
        os.ln(path.join("Versions/Current", target_filename), target_filename)
        os.cd(oldir)
    end)

    on_install(function (target)
        local frameworkdir = path.absolute(target:data("xcode.frameworkdir"))
        local installdir = target:installdir()
        if not os.isdir(installdir) then
            os.mkdir(installdir)
        end
        os.vcp(frameworkdir, installdir)
    end)

    on_uninstall(function (target)
        local frameworkdir = path.absolute(target:data("xcode.frameworkdir"))
        local installdir = target:installdir()
        os.tryrm(path.join(installdir, path.filename(frameworkdir)))
    end)

    -- disable package
    on_package(function (target) end)

