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
-- @file        proto.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.project.config")
import("core.project.depend")
import("core.tool.compiler")
import("lib.detect.find_tool")
import("private.utils.progress")

-- get protoc
function _get_protoc(target, sourcekind)

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
    return assert(target:data(sourcekind == "cxx" and "protobuf.protoc" or "protobuf.protoc-c"), "protoc not found!")
end

-- generate build commands
function buildcmd(target, batchcmds, sourcefile_proto, opt, sourcekind)

    -- get protoc
    local protoc = _get_protoc(target, sourcekind)

    -- get c/c++ source file for protobuf
    local prefixdir
    local fileconfig = target:fileconfig(sourcefile_proto)
    if fileconfig then
        prefixdir = fileconfig.proto_rootdir
    end
    local rootdir = path.join(target:autogendir(), "rules", "protobuf")
    local filename = path.basename(sourcefile_proto) .. ".pb" .. (sourcekind == "cxx" and ".cc" or "-c.c")
    local sourcefile_cx = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename})
    local sourcefile_dir = prefixdir and path.join(rootdir, prefixdir) or path.directory(sourcefile_cx)

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

    -- ensure the source file directory
    if not os.isdir(sourcefile_dir) then
        os.mkdir(sourcefile_dir)
    end

    -- get compilation flags
    local argv = {sourcefile_proto}
    if prefixdir then
        table.insert(argv, "-I" .. prefixdir)
    else
        table.insert(argv, "-I" .. path.directory(sourcefile_proto))
    end
    table.insert(argv, (sourcekind == "cxx" and "--cpp_out=" or "--c_out=") .. sourcefile_dir)

    -- add commands
    batchcmds:add_progress_tip(opt.progress, "${color.build.object}compiling.proto %s", sourcefile_proto)
    batchcmds:add_cmd(protoc, argv)
    batchcmds:add_cmd(compinst:compargv(sourcefile_cx, objectfile, {compflags = compflags}))

    -- add deps
    batchcmds:add_depfiles(sourcefile_proto)
    batchcmds:add_depvalues(compinst:program(), compflags)
    batchcmds:set_depmtime(os.mtime(objectfile))
    batchcmds:set_depcache(target:dependfile(objectfile))
end

-- build protobuf file
function build(target, sourcefile_proto, opt, sourcekind)

    -- get protoc
    local protoc = _get_protoc(target, sourcekind)

    -- get c/c++ source file for protobuf
    local prefixdir
    local fileconfig = target:fileconfig(sourcefile_proto)
    if fileconfig then
        prefixdir = fileconfig.proto_rootdir
    end
    local rootdir = path.join(target:autogendir(), "rules", "protobuf")
    local filename = path.basename(sourcefile_proto) .. ".pb" .. (sourcekind == "cxx" and ".cc" or "-c.c")
    local sourcefile_cx = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename})
    local sourcefile_dir = prefixdir and path.join(rootdir, prefixdir) or path.directory(sourcefile_cx)

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

    -- need build this object?
    local dryrun = option.get("dry-run")
    local depvalues = {compinst:program(), compflags}
    depend.on_changed(function ()

        -- trace progress info
        progress.show(opt.progress, "${color.build.object}compiling.proto %s", sourcefile_proto)

        -- ensure the source file directory
        if not os.isdir(sourcefile_dir) then
            os.mkdir(sourcefile_dir)
        end

        -- get compilation flags
        local argv = {sourcefile_proto}
        if prefixdir then
            table.insert(argv, "-I" .. prefixdir)
        else
            table.insert(argv, "-I" .. path.directory(sourcefile_proto))
        end
        table.insert(argv, (sourcekind == "cxx" and "--cpp_out=" or "--c_out=") .. sourcefile_dir)

        -- do compile
        os.vrunv(protoc, argv)

        -- trace
        if option.get("verbose") then
            print(compinst:compcmd(sourcefile_cx, objectfile, {compflags = compflags}))
        end

        -- compile c/c++ source file for protobuf
        if not dryrun then
            local dependinfo = {files = {}}
            assert(compinst:compile(sourcefile_cx, objectfile, {dependinfo = dependinfo, compflags = compflags}))
            return dependinfo
        end

    end, {  dependfile = target:dependfile(objectfile),
            lastmtime = os.mtime(objectfile),
            values = depvalues,
            files = sourcefile_proto,
            always_changed = dryrun})
end

