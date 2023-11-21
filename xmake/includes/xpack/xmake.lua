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

-- Define xpack interfaces to generate installation package. e.g. nsis, deb, rpm, ...
--
-- And we can call `xmake pack` plugin to pack them.
--
-- @see https://github.com/xmake-io/xmake/issues/1433
--

-- define apis
local apis = {
    values = {
        -- set package version,  we will also get it from project/target
        "xpack.set_version",
        -- set pacakge homepage url
        "xpack.set_homepage",
        -- set package description
        "xpack.set_description",
        -- set package copyright
        "xpack.set_copyright",
        -- set company name
        "xpack.set_company",
        -- set package formats, e.g. nsis, deb, rpm, targz, zip, runself, ...
        -- we can also add custom formats
        "xpack.set_formats",
        -- set the base name of the output file
        "xpack.set_basename",
        -- set the extension of the output file
        "xpack.set_extension",
        -- add targets to be packaged
        "xpack.add_targets",
        -- set installed binary directory, e.g. bin
        "xpack.set_bindir",
        -- set installed library directory, e.g. lib
        "xpack.set_libdir",
        -- set installed include directory, e.g. include
        "xpack.set_includedir",
        -- set prefix directory, e.g. prefixdir/bin, prefixdir/lib ..
        "xpack.set_prefixdir",
        -- set nsis display name
        "xpack.set_nsis_displayname",
        -- set nsis display icon
        "xpack.set_nsis_displayicon"
    },
    paths = {
        -- set the spec file path, support the custom variable pattern, e.g. set_specfile("", {pattern = "%${([^\n]-)}"})
        "xpack.set_specfile",
        -- set icon file path, e.g foo.ico
        "xpack.set_iconfile",
        -- set package license file, we will also get them from target
        "xpack.set_licensefile",
        -- add install files, we will also get them from target
        "xpack.add_installfiles"
    },
    script = {
        -- add custom load script
        "xpack.on_load",
        -- add custom package script before packing package
        "xpack.before_package",
        -- rewrite custom package script
        "xpack.on_package",
        -- add custom package script after packing package
        "xpack.after_package",
        -- add custom commands script before installing
        "xpack.before_installcmd",
        -- add custom commands script before uninstalling
        "xpack.before_uninstallcmd",
        -- rewrite custom install commands script, we will also get it from target/rules
        "xpack.on_installcmd",
        -- rewrite custom uninstall commands script, we will also get it from target/rules
        "xpack.on_uninstallcmd",
        -- add custom commands script after installing
        "xpack.after_installcmd",
        -- add custom commands script after uninstalling
        "xpack.after_uninstallcmd"
    },
    keyvalues = {
        -- set the spec variable
        "xpack.set_specvar",
        -- add nsis sections, e.g.
        -- add NSIS install commands that will be added to the end of the install Section, e.g.
        --[[
            add_nsis_installcmds("Enable Long Path",
                'WriteRegDWORD ${HKLM} "SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 1',
                {description = "Increases the maximum path length limit, up to 32,767 characters (before 256)."})
        --]]
        "xpack.add_nsis_installcmds"
    }
}
interp_add_scopeapis(apis)
