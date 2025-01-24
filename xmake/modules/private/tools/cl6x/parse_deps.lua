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
-- @file        parse_deps.lua
--

-- imports
import("core.project.config")
import("core.project.project")
import("core.base.hashset")

-- normailize path of a dependecy
function _normailize_dep(dep, projectdir)
    -- escape characters, e.g. \#Qt.Widget_pch.h -> #Qt.Widget_pch.h
    -- @see https://github.com/xmake-io/xmake/issues/4134
    -- https://github.com/xmake-io/xmake/issues/4273
    if not is_host("windows") then
        dep = dep:gsub("\\(.)", "%1")
    end
    if path.is_absolute(dep) then
        dep = path.translate(dep)
    else
        dep = path.absolute(dep, projectdir)
    end
    if dep:startswith(projectdir) then
        return path.relative(dep, projectdir)
    else
        -- we also need to check header files outside project
        -- https://github.com/xmake-io/xmake/issues/1154
        return dep
    end
end

-- parse depsfiles from string
--
-- parse_deps(io.readfile(depfile, {continuation = "\\"}))
--
-- eg.
--
-- build/.objs/foo/linux/x86_64/release/src/foo.c.o: src/foo.c
-- build/.objs/foo/linux/x86_64/release/src/foo.c.o: src/foo.h
--
-- build/.objs/tests/linux/x86_64/release/src/main.c.o: src/main.c
-- build/.objs/tests/linux/x86_64/release/src/main.c.o: src/foo.h
-- build/.objs/tests/linux/x86_64/release/src/main.c.o: src/bar.h
-- build/.objs/tests/linux/x86_64/release/src/main.c.o: src/zoo.h
--
function main(depsdata, opt)
    local results = hashset.new()
    local projectdir = os.projectdir()
    local line = depsdata:rtrim() -- maybe there will be an empty newline at the end. so we trim it first
    local plain = {plain = true}
    for _, includefile in ipairs(line:split('\n', plain)) do -- it will trim all internal spaces without `{strict = true}`
        includefile = includefile:split(": ", plain)[2]
        if includefile and #includefile > 0 then
            includefile = _normailize_dep(includefile, projectdir)
            if includefile then
                results:insert(includefile)
            end
        end
    end
    return results:to_array()
end
