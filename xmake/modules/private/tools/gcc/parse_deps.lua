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
-- @file        parse_deps.lua
--

-- imports
import("core.project.project")
import("core.base.hashset")

-- a placeholder for spaces in path
local space_placeholder = "\001"

-- normailize path of a dependecy
function _normailize_dep(dep, projectdir)

    -- tranlate dep path
    if path.is_absolute(dep) then
        dep = path.translate(dep)
    else
        dep = path.absolute(dep, projectdir)
    end

    -- save it if belong to the project
    if dep:startswith(projectdir) then
        return path.relative(dep, projectdir)
    end
end

-- parse depsfiles from string
--
-- parse_deps(io.readfile(depfile, {continuation = "\\"}))
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

    -- we assume there is only one valid line
    local results = hashset.new()
    local projectdir = os.projectdir()
    local line = depsdata:rtrim() -- maybe there will be an empty newline at the end. so we trim it first
    line = line:gsub("\\ ", space_placeholder)
    for _, includefile in ipairs(line:split(' ', {plain = true})) do -- it will trim all internal spaces without `{strict = true}`
        if not includefile:endswith(":") then -- ignore "xxx.o:" prefix
            includefile = includefile:gsub(space_placeholder, ' ')
            if #includefile > 0 then
                includefile = _normailize_dep(includefile, projectdir)
                if includefile then
                    results:insert(includefile)
                end
            end
        end
    end
    return results:to_array()
end
