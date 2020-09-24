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
-- @file        resign.lua
--

-- imports
import("lib.detect.find_tool")
import("lib.detect.find_directory")
import("utils.archive.extract")
import("private.tools.codesign")
import("utils.ipa.package", {alias = "ipagen"})

-- resign *.app directory
function _resign_app(appdir, codesign_identity, mobile_provision, bundle_identifier)

    -- get default codesign identity
    if not codesign_identity then
        for identity, _ in pairs(codesign.codesign_identities()) do
            codesign_identity = identity
            break
        end
    end

    -- get default mobile provision
    if not mobile_provision then
        for provision, _ in pairs(codesign.mobile_provisions()) do
            mobile_provision = provision
            break
        end
    end

    -- generate embedded.mobileprovision to *.app/embedded.mobileprovision
    local mobile_provision_embedded = path.join(appdir, "embedded.mobileprovision")
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

    -- replace bundle identifier of Info.plist
    if bundle_identifier then
        local info_plist_file = path.join(appdir, "Info.plist")
        if os.isfile(info_plist_file) then
            local info_plist_data = io.readfile(info_plist_file)
            if info_plist_data then
                local p = info_plist_data:find("<key>CFBundleIdentifier</key>", 1, true)
                if p then
                    local e = info_plist_data:find("</string>", p, true)
                    if e then
                        local block = info_plist_data:sub(p, e + 9):match("<string>(.+)</string>")
                        if block then
                            info_plist_data = info_plist_data:gsub(block, bundle_identifier)
                            io.writefile(info_plist_file, info_plist_data)
                        end
                    end
                end
            end
        end
    end

    -- do codesign
    codesign(appdir, codesign_identity, mobile_provision)
end

-- resign *.ipa file
function _resign_ipa(ipafile, codesign_identity, mobile_provision, bundle_identifier)

    -- get resigned ipa file
    local ipafile_resigned = path.join(path.directory(ipafile), path.basename(ipafile) .. "_resign" .. path.extension(ipafile))

    -- extract *.ipa file
    local appdir = os.tmpfile() .. ".app"
    extract(ipafile, appdir, {extension = ".zip"})

    -- find real *.app directory
    local appdir_real = find_directory("**.app", appdir)
    if not appdir_real then
        appdir_real = appdir
    end

    -- resign *.app directory
    _resign_app(appdir_real, codesign_identity, mobile_provision, bundle_identifier)

    -- re-generate *.ipa file
    ipagen(appdir_real, ipafile_resigned)

    -- remove tmp files
    os.tryrm(appdir)

    -- trace
    cprint("output: ${bright}%s", ipafile_resigned)
end

-- main entry
function main (filepath, codesign_identity, mobile_provision, bundle_identifier)

    -- check
    assert(os.exists(filepath), "%s not found!", filepath)

    -- resign *.ipa or *.app application
    if os.isfile(filepath) then
        _resign_ipa(filepath, codesign_identity, mobile_provision, bundle_identifier)
    else
        _resign_app(filepath, codesign_identity, mobile_provision, bundle_identifier)
    end

    -- ok
    cprint("${color.success}resign ok!")
end

