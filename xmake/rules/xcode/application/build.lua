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

-- main entry
function main (target, opt)

    -- get app and resources directory
    local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
    local resourcesdir = path.absolute(target:data("xcode.bundle.resourcesdir"))

    -- need re-compile it?
    local dependfile = target:dependfile(bundledir)
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(dependfile)}) then
        return 
    end
 
    -- trace progress info
    cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", opt.progress)
    if option.get("verbose") then
        cprint("${dim color.build.target}generating.xcode.$(mode) %s", path.filename(bundledir))
    else
        cprint("${color.build.target}generating.xcode.$(mode) %s", path.filename(bundledir))
    end

    -- copy PkgInfo to the contents directory
    os.cp(path.join(os.programdir(), "scripts", "PkgInfo"), resourcesdir)

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

    -- do codesign
    codesign(bundledir, target:values("xcode.codesign_identity") or get_config("xcode_codesign_identity"))

    -- update files and values to the dependent file
    dependinfo.files = {bundledir}
    depend.save(dependinfo, dependfile)
end

