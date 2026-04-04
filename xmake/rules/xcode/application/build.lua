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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        build.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.project.depend")
import("lib.detect.find_library")
import("private.tools.codesign")
import("private.utils.target", {alias = "target_utils"})
import("utils.binary.deplibs", {alias = "get_depend_libraries"})
import("utils.progress")

function _is_non_system_dylib(libfile)
    return libfile and libfile:endswith(".dylib")
       and not libfile:startswith("/usr/lib/")
       and not libfile:startswith("/System/Library/")
end

local function _get_target_linkdirs(target)
    local linkdirs = {}
    for _, values in ipairs(table.wrap(target:get_from("linkdirs", "*"))) do
        for _, linkdir in ipairs(table.wrap(values)) do
            table.insert(linkdirs, path.absolute(linkdir))
        end
    end
    return table.unique(linkdirs)
end

local function _get_target_linklibfiles(target)
    local linkdirs = _get_target_linkdirs(target)
    local libfiles = {}
    for _, values in ipairs(table.wrap(target:get_from("links", "*"))) do
        for _, link in ipairs(table.wrap(values)) do
            local libinfo = find_library(link, linkdirs, {plat = target:plat(), kind = "shared"})
            if libinfo then
                table.insert(libfiles, path.join(libinfo.linkdir, libinfo.filename))
            end
        end
    end
    return table.unique(libfiles)
end

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

        -- change rpath
        -- @see https://github.com/xmake-io/xmake/issues/2679#issuecomment-1221839215
        local targetfile = path.join(binarydir, path.filename(target:targetfile()))
        try { function () os.vrunv("install_name_tool", {"-delete_rpath", "@loader_path", targetfile}) end }
        os.vrunv("install_name_tool", {"-add_rpath", "@executable_path/../Frameworks", targetfile})

        -- copy dependent frameworks and dynamic libraries
        local frameworks_to_copy = {}
        local framework_targetfiles = {}
        for _, dep in ipairs(target:orderdeps()) do
            local frameworkdir = dep:data("xcode.bundle.rootdir")
            if dep:rule("xcode.framework") and frameworkdir then
                table.insert(frameworks_to_copy, frameworkdir)
                framework_targetfiles[path.absolute(dep:targetfile())] = true
            end
        end
        local libfiles = {}
        target_utils.get_target_libfiles(target, libfiles, target:targetfile(), {})
        table.join2(libfiles, _get_target_linklibfiles(target))
        local dependfiles = get_depend_libraries(target:targetfile(), {
            plat = target:plat(),
            arch = target:arch(),
            recursive = true,
            resolve_path = true,
            resolve_hint_paths = libfiles
        })
        for _, dependfile in ipairs(table.wrap(dependfiles)) do
            if _is_non_system_dylib(dependfile) then
                table.insert(libfiles, dependfile)
            end
        end
        local dylibs_to_copy = {}
        for _, libfile in ipairs(table.unique(libfiles)) do
            if not framework_targetfiles[path.absolute(libfile)] then
                table.insert(dylibs_to_copy, libfile)
            end
        end
        if #frameworks_to_copy > 0 or #dylibs_to_copy > 0 then
            if not os.isdir(frameworksdir) then
                os.mkdir(frameworksdir)
            end
            for _, frameworkdir in ipairs(frameworks_to_copy) do
                os.cp(frameworkdir, frameworksdir, {symlink = true})
            end
            for _, libfile in ipairs(dylibs_to_copy) do
                os.vcp(libfile, frameworksdir)
            end
        end

        -- copy PkgInfo to the contents directory
        os.mkdir(resourcesdir)
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
        local mobile_provision
        local mobile_provision_embedded = path.join(bundledir, "embedded.mobileprovision")
        if target:is_plat("iphoneos") then
            mobile_provision = target:values("xcode.mobile_provision") or codesign.xcode_mobile_provision()
            if mobile_provision then
                os.tryrm(mobile_provision_embedded)
                local provisions = codesign.mobile_provisions()
                if provisions then
                    local mobile_provision_data = provisions[mobile_provision]
                    if mobile_provision_data then
                        io.writefile(mobile_provision_embedded, mobile_provision_data)
                    end
                end
            end
        end

        -- do codesign
        local codesign_identity = target:values("xcode.codesign_identity") or codesign.xcode_codesign_identity()
        if target:is_plat("macosx") or (target:is_plat("iphoneos") and target:is_arch("x86_64", "i386")) then
            codesign_identity = nil
        end
        codesign(bundledir, codesign_identity, mobile_provision, {deep = true})

    end, {dependfile = target:dependfile(bundledir), files = {bundledir, target:targetfile()}, changed = target:is_rebuilt()})
end
