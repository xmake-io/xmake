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
-- @file        build.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.project.depend")
import("private.tools.codesign")

-- generate Info.plist
function _gen_info_plist(target, info_plist_file)
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

-- main entry
function main (target, opt)

    -- get app and contents directory
    local appdir = path.absolute(target:data("xcode.app.rootdir"))
    local contentsdir = path.absolute(target:data("xcode.app.contentsdir"))

    -- need re-compile it?
    local dependfile = target:dependfile(appdir)
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(dependfile)}) then
        return 
    end
 
    -- trace progress info
    cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", opt.progress)
    if option.get("verbose") then
        cprint("${dim color.build.target}generating.xcode.app %s", path.filename(appdir))
    else
        cprint("${color.build.target}generating.xcode.app %s", path.filename(appdir))
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
                    _gen_info_plist(target, dstfile)
                end
            end
            i = i + 1
        end
    end

    -- do codesign
    codesign(appdir, target:values("xcode.codesign_identity") or get_config("xcode_codesign_identity"))

    -- update files and values to the dependent file
    dependinfo.files = {appdir}
    depend.save(dependinfo, dependfile)
end

