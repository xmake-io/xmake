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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        gcc.lua
--

-- imports
import("core.project.project")

-- a placeholder for spaces in path
local spacePlaceHolder = "\001*\002"

-- normailize path of a dependecy
function _normailize_dep(dep)
    dep = dep:trim()
    if #dep == 0 then
        return nil
    end
    dep = path.relative(dep, project.directory())
    dep = path.absolute(dep, project.directory())
    -- save it if belong to the project
    if dep:startswith(os.projectdir()) then
        -- get the relative
        dep = path.relative(dep, project.directory())
        return dep
    end
end

-- parse deps file (*.d)
--
-- eg.
-- strcpy.o: src/tbox/libc/string/strcpy.c src/tbox/libc/string/string.h \
--  src/tbox/libc/string/prefix.h src/tbox/libc/string/../prefix.h \
--  src/tbox/libc/string/../../prefix.h \
--  src/tbox/libc/string/../../prefix/prefix.h \
--  src/tbox/libc/string/../../prefix/config.h \
--  src/tbox/libc/string/../../prefix/../config.h \
--  build/iphoneos/x86_64/release/tbox.config.h \
--
function main(depsdata)
    if not depsdata or #depsdata == 0 then
        return {}
    end

    local results = {}

    -- translate it
    local data = depsdata:gsub("\\\n", "")

    for _, line in ipairs(data:split("\n")) do
        local p = line:find(':', 1, true)
        if p ~= nil then
            line = line:sub(p + 1)
            line = line:gsub("\\ ", spacePlaceHolder)
            for _, includefile in ipairs(line:split("%s")) do
                includefile = includefile:gsub(spacePlaceHolder, " ")
                includefile = _normailize_dep(includefile)
                if includefile then
                    table.insert(results, includefile)
                end
            end
        end
    end
    return table.unique(results)
end