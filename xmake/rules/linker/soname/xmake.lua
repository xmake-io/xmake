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

rule("linker.soname")
    on_config(function (target)
        local soname = target:soname()
        if target:is_shared() and soname then
            if target:has_tool("sh", "gcc", "gxx", "clang", "clangxx") then
                if target:is_plat("macosx", "iphoneos", "watchos", "appletvos") then
                    target:add("shflags", "-Wl,-install_name,@rpath/" .. soname, {force = true})
                else
                    target:add("shflags", "-Wl,-soname," .. soname, {force = true})
                end
                target:data_set("soname.enabled", true)
            end
        end
    end)

    after_link(function (target)
        import("core.project.depend")
        local soname = target:soname()
        if target:is_shared() and soname and target:data("soname.enabled") then
            local version = target:version()
            local filename = target:filename()
            local extension = path.extension(filename)
            local targetfile_with_version = path.join(target:targetdir(), filename .. "." .. version)
            if extension == ".dylib" then
                targetfile_with_version = path.join(target:targetdir(), path.basename(filename) .. "." .. version .. extension)
            end
            local targetfile_with_soname = path.join(target:targetdir(), soname)
            local targetfile = target:targetfile()
            if soname ~= filename and soname ~= path.filename(targetfile_with_version) then
                depend.on_changed(function ()
                    os.cp(target:targetfile(), targetfile_with_version)
                    os.rm(target:targetfile())
                    local oldir = os.cd(target:targetdir())
                    os.ln(path.filename(targetfile_with_version), soname, {force = true})
                    os.ln(soname, path.filename(targetfile), {force = true})
                    os.cd(oldir)
                end, {dependfile = target:dependfile(targetfile_with_version),
                      files = {target:targetfile()},
                      values = {soname, version},
                      changed = target:is_rebuilt()})
            end
        end
    end)

    after_clean(function (target)
        import("private.action.clean.remove_files")
        local soname = target:soname()
        if target:is_shared() and soname then
            local version = target:version()
            local filename = target:filename()
            local extension = path.extension(filename)
            local targetfile_with_version = path.join(target:targetdir(), filename .. "." .. version)
            if extension == ".dylib" then
                targetfile_with_version = path.join(target:targetdir(), path.basename(filename) .. "." .. version .. extension)
            end
            local targetfile_with_soname = path.join(target:targetdir(), soname)
            remove_files(targetfile_with_soname)
            remove_files(targetfile_with_version)
        end
    end)
