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
-- @file        build.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.project.depend")
import("private.tools.codesign")
import("utils.progress")

-- copy frameworks with symlink
--
-- TODO we should improve os.cp to support for copying directory with symlink
-- os.vcp(frameworkdir, frameworksdir, {symlink = true})
function _copy_frameworks(frameworkdir, frameworksdir)
    os.mkdir(frameworksdir)
    for _, filepath in ipairs(os.filedirs(path.join(frameworkdir, "*"))) do
        if path.filename(filepath) == "Versions" then
            _copy_frameworks(filepath, path.join(frameworksdir, "Versions"))
        else
            os.cp(filepath, path.join(frameworksdir, path.filename(filepath)), {symlink = true})
        end
    end
end

-- main entry
function main (target, opt)

    -- get app and resources directory
    local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
    local contentsdir = path.absolute(target:data("xcode.bundle.contentsdir"))
    local resourcesdir = path.absolute(target:data("xcode.bundle.resourcesdir"))
    local frameworksdir = path.join(contentsdir, "Frameworks")

    -- do build if changed
    depend.on_changed(function ()

        -- trace progress info
        progress.show(opt.progress, "${color.build.target}generating.xcode.$(mode) %s", path.filename(bundledir))

        -- copy target file
        local binarydir = contentsdir
        if target:is_plat("macosx") then
            binarydir = path.join(contentsdir, "MacOS")
        end
        os.vcp(target:targetfile(), path.join(binarydir, path.filename(target:targetfile())))

        -- copy dependent dynamic libraries and frameworks
        for _, dep in ipairs(target:orderdeps()) do
            if dep:kind() == "shared" then
                local frameworkdir = dep:data("xcode.bundle.rootdir")
                if dep:rule("xcode.framework") and frameworkdir then
                    _copy_frameworks(frameworkdir, frameworksdir, {symlink = true})
                else
                    os.vcp(dep:targetfile(), binarydir)
                end
            end
        end

        -- copy PkgInfo to the contents directory
        os.vcp(path.join(os.programdir(), "scripts", "PkgInfo"), resourcesdir)

        -- copy resource files to the resources directory
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

        -- generate embedded.mobileprovision to *.app/embedded.mobileprovision
        local mobile_provision_embedded = path.join(bundledir, "embedded.mobileprovision")
        local mobile_provision = target:values("xcode.mobile_provision") or get_config("xcode_mobile_provision")
        if mobile_provision and target:is_plat("iphoneos") then
            os.tryrm(mobile_provision_embedded)
            local provisions = codesign.mobile_provisions()
            if provisions then
                local mobile_provision_data = provisions[mobile_provision]
                if mobile_provision_data then
                    io.writefile(mobile_provision_embedded, mobile_provision_data)
                end
            end
        end

        -- do codesign
        local codesign_identity = target:values("xcode.codesign_identity") or get_config("xcode_codesign_identity")
        if target:is_plat("macosx") or (target:is_plat("iphoneos") and target:is_arch("x86_64", "i386")) then
            codesign_identity = nil
        end
        codesign(bundledir, codesign_identity, mobile_provision, {deep = true})

    end, {dependfile = target:dependfile(bundledir), files = {bundledir, target:targetfile()}})
end

