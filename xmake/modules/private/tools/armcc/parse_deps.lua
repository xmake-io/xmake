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
-- @author      smalli
-- @file        parse_deps_armcc.lua
--

-- imports
import("core.project.project")
import("core.base.hashset")

-- a placeholder for spaces in path
local space_placeholder = "\001"

-- normailize path of a dependecy
function _normailize_dep(dep, projectdir)
    if path.is_absolute(dep) then
        dep = path.translate(dep)
    else
        dep = path.absolute(dep, projectdir)
    end
    if dep:startswith(projectdir) then
        return path.relative(dep, projectdir)
    else
        return dep
    end
end

-- parse depsfiles from string
--
-- parse_deps(io.readfile(depfile, {continuation = "\\"}))
--
-- eg.
-- build\\.objs\\apps\\cross\\cortex-m3\\release\\APPS\\main.c.o: APPS\\main.c\
-- build\\.objs\\apps\\cross\\cortex-m3\\release\\APPS\\main.c.o: D:\\Keil533\\ARM\\ARMCC\\bin\\..\\include\\stdarg.h\
-- build\\.objs\\apps\\cross\\cortex-m3\\release\\APPS\\main.c.o: D:\\Keil533\\ARM\\ARMCC\\bin\\..\\include\\stdio.h\
-- build\\.objs\\apps\\cross\\cortex-m3\\release\\APPS\\main.c.o: D:\\Keil533\\ARM\\ARMCC\\bin\\..\\include\\string.h\
-- build\\.objs\\apps\\cross\\cortex-m3\\release\\APPS\\main.c.o: APPS\\main.h\
--
--
function main(depsdata)

    local block = 0
    local results = hashset.new()
    local projectdir = os.projectdir()
    local line = depsdata:rtrim() -- maybe there will be an empty newline at the end. so we trim it first
    local plain = {plain = true}
    line = line:replace("\\ ", space_placeholder, plain)
    for _, includefile in ipairs(line:split('\n', plain)) do
        if is_host("windows") and includefile:match("^%w\\:") then
            includefile = includefile:replace("\\:", ":", plain)
        end
        includefile = includefile:replace(space_placeholder, ' ', plain)
        includefile = includefile:split(".o:", {plain = true})[2]
        includefile = includefile:replace(' ', '', plain)
        if #includefile > 0 then
            includefile = _normailize_dep(includefile, projectdir)
            if includefile then
                results:insert(includefile)
            end
        end
    end
    return results:to_array()
end
