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
-- @file        parse_deps.lua
--

-- imports
import("core.project.project")

-- a placeholder for spaces in path
local space_placeholder = "\001"

-- normailize path of a dependecy
function _normailize_dep(dep)
    
    -- check
    dep = dep:trim()
    if #dep == 0 then
        return nil
    end
    
    -- tranlate dep path
    dep = path.relative(dep, project.directory())
    dep = path.absolute(dep, project.directory())

    -- save it if belong to the project
    if dep:startswith(os.projectdir()) then
        return path.relative(dep, project.directory())
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
function main(depsfile)

    local depsdata = io.readfile(depsfile, { continuation = "\\"})
    -- check
    if not depsdata or #depsdata == 0 then
        return {}
    end

    -- parse results
    local results = {}
    for _, line in ipairs(depsdata:split("\n", {plain = true})) do
        local p = line:find(':', 1, true)
        if p then
            line = line:sub(p + 1)
            line = line:gsub("\\ ", space_placeholder)
            for _, includefile in ipairs(line:split("%s")) do
                includefile = includefile:gsub(space_placeholder, " ")
                includefile = _normailize_dep(includefile)
                if includefile then
                    table.insert(results, includefile)
                end
            end
        end
    end
    return table.unique(results)
end
