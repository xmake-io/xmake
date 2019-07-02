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
-- @file        proto.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.project.config")
import("core.project.depend")
import("core.tool.compiler")
import("lib.detect.find_tool")

-- build protobuf file
function main(target, sourcekind, sourcefile_proto, opt)

    -- find protoc
    local protoc = target:data("protobuf.protoc")
    if not protoc and sourcekind == "cxx" then
        protoc = find_tool("protoc") 
        if protoc and protoc.program then
            target:data_set("protobuf.protoc", protoc.program)
        end
    end

    -- find protoc-c
    local protoc_c = target:data("protobuf.protoc-c")
    if not protoc_c and sourcekind == "cc" then
        protoc_c = find_tool("protoc-c") or protoc 
        if protoc_c and protoc_c.program then
            target:data_set("protobuf.protoc-c", protoc_c.program)
        end
    end

    -- get protoc
    protoc = assert(target:data(sourcekind == "cxx" and "protobuf.protoc" or "protobuf.protoc-c"), "protoc not found!")

    -- get c/c++ source file for protobuf
    local sourcefile_cx = path.join(target:autogendir(), "rules", "protobuf", path.basename(sourcefile_proto) .. ".pb" .. (sourcekind == "cxx" and ".cc" or "-c.c"))
    local sourcefile_dir = path.directory(sourcefile_cx)

    -- add includedirs
    target:add("includedirs", sourcefile_dir)

    -- get object file
    local objectfile = target:objectfile(sourcefile_cx)

    -- load compiler 
    local compinst = compiler.load(sourcekind, {target = target})

    -- get compile flags
    local configs = {includedirs = sourcefile_dir}
    if sourcekind == "cxx" then
        configs.languages = "c++11"
    end
    local compflags = compinst:compflags({target = target, sourcefile = sourcefile_cx, configs = configs})

    -- add objectfile
    table.insert(target:objectfiles(), objectfile)

    -- load dependent info 
    local dependfile = target:dependfile(objectfile)
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

    -- need build this object?
    local depvalues = {compinst:program(), compflags}
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(objectfile), values = depvalues}) then
        return 
    end

    -- trace progress info
    cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", opt.progress)
    if option.get("verbose") then
        cprint("${dim color.build.object}compiling.proto %s", sourcefile_proto)
    else
        cprint("${color.build.object}compiling.proto %s", sourcefile_proto)
    end

    -- ensure the source file directory
    if not os.isdir(sourcefile_dir) then
        os.mkdir(sourcefile_dir)
    end

    -- compile protobuf 
    os.vrunv(protoc, {sourcefile_proto, "-I" .. os.args(path.directory(sourcefile_proto)), (sourcekind == "cxx" and "--cpp_out=" or "--c_out=") .. sourcefile_dir})

    -- trace
    if option.get("verbose") then
        print(compinst:compcmd(sourcefile_cx, objectfile, {compflags = compflags}))
    end

    -- compile c/c++ source file for protobuf
    dependinfo.files = {}
    assert(compinst:compile(sourcefile_cx, objectfile, {dependinfo = dependinfo, compflags = compflags}))

    -- update files and values to the dependent file
    dependinfo.values = depvalues
    table.insert(dependinfo.files, sourcefile_proto)
    depend.save(dependinfo, dependfile)
end

