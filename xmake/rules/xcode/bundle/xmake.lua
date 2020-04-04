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

    -- we must set kind before target.on_load(), may we will use target in on_load()
    before_load(function (target)
        
        -- get bundle directory
        local targetdir = target:targetdir()
        local bundledir = path.join(targetdir, target:basename() .. ".bundle")
        target:data_set("xcode.bundledir", bundledir)

        -- set target info for bundle 
        target:set("filename", target:basename())
        target:set("targetdir", path.join(bundledir, "Contents", "MacOS"))

        -- generate binary as bundle, we cannot set `-shared` or `-dynamiclib`
        target:set("kind", "binary")
        target:add("ldflags", "-bundle", {force = true})

        -- register clean files for `xmake clean`
        target:add("cleanfiles", bundledir)
    end)

    after_build(function (target)

        -- imports
        import("private.tools.codesign")

        -- get bundle directory
        local bundledir = path.absolute(target:data("xcode.bundledir"))

        -- copy resource files to the content directory
        local srcfiles, dstfiles = target:installfiles(path.join(bundledir, "Contents"))
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
        codesign(bundledir)
    end)

    on_install(function (target)
        local bundledir = path.absolute(target:data("xcode.bundledir"))
        local installdir = target:installdir()
        if not os.isdir(installdir) then
            os.mkdir(installdir)
        end
        os.vcp(bundledir, installdir)
    end)

    on_uninstall(function (target)
        local bundledir = path.absolute(target:data("xcode.bundledir"))
        local installdir = target:installdir()
        os.tryrm(path.join(installdir, path.filename(bundledir)))
    end)

    -- disable package
    on_package(function (target) end)

