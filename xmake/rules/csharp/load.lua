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
-- @author      JassJam
-- @file        load.lua
--

function main(target)
    local targetdir = target:targetdir()
    if targetdir and path.filename(targetdir) ~= target:name() then
        target:set("targetdir", path.join(targetdir, target:name()))
    end

    if target:is_static() or target:is_shared() then
        if not target:get("extension") then
            target:set("extension", ".dll")
        end
        if target:get("prefixname") == nil then
            target:set("prefixname", "")
        end
    end

    -- find and cache the .csproj file for later use in build/install
    local csprojfiles = {}
    for _, sourcefile in ipairs(target:sourcefiles()) do
        if path.extension(sourcefile):lower() == ".csproj" then
            table.insert(csprojfiles, sourcefile)
        end
    end
    assert(#csprojfiles > 0, "target(%s): csharp requires one .csproj in add_files()!", target:name())
    assert(#csprojfiles == 1, "target(%s): csharp only supports one .csproj file!", target:name())

    local csprojfile = csprojfiles[1]
    local csprojabs = path.is_absolute(csprojfile) and csprojfile or path.absolute(csprojfile, os.projectdir())
    assert(os.isfile(csprojabs), "target(%s): csharp .csproj not found: %s", target:name(), csprojfile)

    if not target:get("filename") and not target:get("basename") then
        target:set("basename", path.basename(csprojabs))
    end
    target:data_set("csharp.csproj", csprojabs)
end
