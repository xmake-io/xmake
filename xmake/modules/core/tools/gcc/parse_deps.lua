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

-- a placeholder for spaces in path
local space_placeholder = "\001"

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

-- load module mapper
function _load_module_mapper(target)
    local mapper = {}
    local mapperfile = path.join(config.buildir(), target:name(), "mapper.txt")
    for line in io.lines(mapperfile) do
        local moduleinfo = line:split(" ", {plain = true})
        if #moduleinfo == 2 then
            mapper[moduleinfo[1]] = moduleinfo[2]
        end
    end
    return mapper
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
-- with c++ modules (gcc):
-- build/.objs/dependence/linux/x86_64/release/src/foo.mpp.o: src/foo.mpp\
-- build/.objs/dependence/linux/x86_64/release/src/foo.mpp.o  gcm.cache/foo.gcm: bar.c++m cat.c++m\
-- foo.c++m: gcm.cache/foo.gcm\
-- .PHONY: foo.c++m\
-- gcm.cache/foo.gcm:|  build/.objs/dependence/linux/x86_64/release/src/foo.mpp.o\
-- CXX_IMPORTS += bar.c++m cat.c++m\
--
function main(depsdata, opt)

    -- we assume there is only one valid line
    local block = 0
    local results = hashset.new()
    local projectdir = os.projectdir()
    local line = depsdata:rtrim() -- maybe there will be an empty newline at the end. so we trim it first
    local plain = {plain = true}
    line = line:replace("\\ ", space_placeholder, plain)
    for _, includefile in ipairs(line:split(' ', plain)) do -- it will trim all internal spaces without `{strict = true}`
        -- some gcc toolchains will some invalid paths (e.g. `d\:\xxx`), we need to fix it
        -- https://github.com/xmake-io/xmake/issues/1196
        if is_host("windows") and includefile:match("^%w\\:") then
            includefile = includefile:replace("\\:", ":", plain)
        end
        if includefile:endswith(":") then -- ignore "xxx.o:" prefix
            block = block + 1
            if block > 1 then
                -- skip other `xxx.o:` block
                break
            end
        else
            includefile = includefile:replace(space_placeholder, ' ', plain)
            includefile = includefile:split("\n", plain)[1]
            if #includefile > 0 then
                includefile = _normailize_dep(includefile, projectdir)
                if includefile then
                    results:insert(includefile)
                end
            end
        end
    end

    -- translate .c++m module file path
    -- with c++ modules (gcc):
    -- CXX_IMPORTS += bar.c++m cat.c++m\
    --
    -- @see https://github.com/xmake-io/xmake/issues/3000
    -- https://github.com/xmake-io/xmake/issues/4215
    local target = opt and opt.target
    if target and line:find("CXX_IMPORTS += ", 1, true) then
        local mapper = _load_module_mapper(target)
        local modulefiles = line:split("CXX_IMPORTS += ", plain)[2]
        if modulefiles then
            for _, modulefile in ipairs(modulefiles:split(' ', plain)) do
                if modulefile:endswith(".c++m") then
                    local modulekey = modulefile:sub(1, #modulefile - 5)
                    local modulepath = mapper[modulekey]
                    if modulepath then
                        modulepath = _normailize_dep(modulepath, projectdir)
                        results:insert(modulepath)
                    end
                end
            end
        end
    end

    return results:to_array()
end
