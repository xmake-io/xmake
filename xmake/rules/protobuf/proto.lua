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
import("lib.detect.find_tool")
import("core.project.depend")
import("private.action.build.object", {alias = "build_objectfiles"})
import("utils.progress")
import("private.async.jobpool")
import("async.runjobs")

-- get protoc
function _get_protoc(target, sourcekind)

    -- find protoc
    local protoc = target:data("protobuf.protoc")
    if not protoc and sourcekind == "cxx" then
        protoc = find_tool("protoc", {envs = target:pkgenvs()})
        if protoc and protoc.program then
            target:data_set("protobuf.protoc", protoc.program)
        end
    end

    -- find protoc-c
    local protoc_c = target:data("protobuf.protoc-c")
    if not protoc_c and sourcekind == "cc" then
        protoc_c = find_tool("protoc-c", {envs = target:pkgenvs()}) or protoc
        if protoc_c and protoc_c.program then
            target:data_set("protobuf.protoc-c", protoc_c.program)
        end
    end

    -- get protoc
    return assert(target:data(sourcekind == "cxx" and "protobuf.protoc" or "protobuf.protoc-c"), "protoc not found!")
end

-- get grpc_cpp_plugin
function _get_grpc_cpp_plugin(target, sourcekind)
    assert(sourcekind == "cxx", "grpc_cpp_plugin only support c++")
    local grpc_cpp_plugin = find_tool("grpc_cpp_plugin", {norun = true, force = true, envs = target:pkgenvs()})
    return assert(grpc_cpp_plugin and grpc_cpp_plugin.program, "grpc_cpp_plugin not found!")
end

-- we need to add some configs to export includedirs to other targets in on_load
-- @see https://github.com/xmake-io/xmake/issues/2256
function load(target, sourcekind)

    -- get the first sourcefile
    local sourcefile_proto
    local sourcebatch = target:sourcebatches()[sourcekind == "cxx" and "protobuf.cpp" or "protobuf.c"]
    if sourcebatch then
        sourcefile_proto = sourcebatch.sourcefiles[1]
    end
    if not sourcefile_proto then
        return
    end

    -- get c/c++ source file for protobuf
    local prefixdir
    local autogendir
    local public
    local fileconfig = target:fileconfig(sourcefile_proto)
    if fileconfig then
        public = fileconfig.proto_public
        prefixdir = fileconfig.proto_rootdir
        autogendir = fileconfig.proto_autogendir
    end
    local rootdir = autogendir and autogendir or path.join(target:autogendir(), "rules", "protobuf")
    local filename = path.basename(sourcefile_proto) .. ".pb" .. (sourcekind == "cxx" and ".cc" or "-c.c")
    local sourcefile_cx = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename})
    local sourcefile_dir = prefixdir and path.join(rootdir, prefixdir) or path.directory(sourcefile_cx)

    -- add includedirs
    target:add("includedirs", sourcefile_dir, {public = public})
end

function buildcmd_pfiles(target, batchcmds, sourcefile_proto, opt, sourcekind)

    -- get protoc
    local protoc = _get_protoc(target, sourcekind)

    -- get c/c++ source file for protobuf
    local prefixdir
    local autogendir
    local public
    local grpc_cpp_plugin
    local fileconfig = target:fileconfig(sourcefile_proto)
    if fileconfig then
        public = fileconfig.proto_public
        prefixdir = fileconfig.proto_rootdir
        -- custom autogen directory to access the generated header files
        -- @see https://github.com/xmake-io/xmake/issues/3678
        autogendir = fileconfig.proto_autogendir
        grpc_cpp_plugin = fileconfig.proto_grpc_cpp_plugin
    end
    local rootdir = autogendir and autogendir or path.join(target:autogendir(), "rules", "protobuf")
    local filename = path.basename(sourcefile_proto) .. ".pb" .. (sourcekind == "cxx" and ".cc" or "-c.c")
    local sourcefile_cx = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename})
    local sourcefile_dir = prefixdir and path.join(rootdir, prefixdir) or path.directory(sourcefile_cx)

    local grpc_cpp_plugin_bin
    local filename_grpc
    local sourcefile_cx_grpc
    if grpc_cpp_plugin then
        grpc_cpp_plugin_bin = _get_grpc_cpp_plugin(target, sourcekind)
        filename_grpc = path.basename(sourcefile_proto) .. ".grpc.pb.cc"
        sourcefile_cx_grpc = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename_grpc})
    end

    local protoc_args = {
        path(sourcefile_proto),
        path(prefixdir and prefixdir or path.directory(sourcefile_proto), function (p) return "-I" .. p end),
        path(sourcefile_dir, function (p) return (sourcekind == "cxx" and "--cpp_out=" or "--c_out=") .. p end)
    }

    if grpc_cpp_plugin then
        local extension = target:is_plat("windows") and ".exe" or ""
        table.insert(protoc_args, "--plugin=protoc-gen-grpc=" .. grpc_cpp_plugin_bin .. extension)
        table.insert(protoc_args, path(sourcefile_dir, function (p) return ("--grpc_out=") .. p end))
    end

    -- add commands
    batchcmds:mkdir(sourcefile_dir)
    batchcmds:show_progress(opt.progress, "${color.build.object}compiling.proto %s to %s", sourcefile_proto, sourcekind)
    batchcmds:vrunv(protoc, protoc_args)
end

function buildcmd_cxfiles(target, batchcmds, sourcefile_proto, opt, sourcekind)

    -- get protoc
    local protoc = _get_protoc(target, sourcekind)

    -- get c/c++ source file for protobuf
    local prefixdir
    local autogendir
    local public
    local grpc_cpp_plugin
    local fileconfig = target:fileconfig(sourcefile_proto)
    if fileconfig then
        public = fileconfig.proto_public
        prefixdir = fileconfig.proto_rootdir
        -- custom autogen directory to access the generated header files
        -- @see https://github.com/xmake-io/xmake/issues/3678
        autogendir = fileconfig.proto_autogendir
        grpc_cpp_plugin = fileconfig.proto_grpc_cpp_plugin
    end
    local rootdir = autogendir and autogendir or path.join(target:autogendir(), "rules", "protobuf")
    local filename = path.basename(sourcefile_proto) .. ".pb" .. (sourcekind == "cxx" and ".cc" or "-c.c")
    local sourcefile_cx = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename})
    local sourcefile_dir = prefixdir and path.join(rootdir, prefixdir) or path.directory(sourcefile_cx)

    local grpc_cpp_plugin_bin
    local filename_grpc
    local sourcefile_cx_grpc
    if grpc_cpp_plugin then
        grpc_cpp_plugin_bin = _get_grpc_cpp_plugin(target, sourcekind)
        filename_grpc = path.basename(sourcefile_proto) .. ".grpc.pb.cc"
        sourcefile_cx_grpc = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename_grpc})
    end

    -- add includedirs
    target:add("includedirs", sourcefile_dir, {public = public})

    -- add objectfile
    local objectfile = target:objectfile(sourcefile_cx)
    table.insert(target:objectfiles(), objectfile)

    local objectfile_grpc
    if grpc_cpp_plugin then
        objectfile_grpc = target:objectfile(sourcefile_cx_grpc)
        table.insert(target:objectfiles(), objectfile_grpc)
    end

    batchcmds:show_progress(opt.progress, "${color.build.object}compiling.proto %s sourcefile %s", sourcefile_proto, sourcefile_cx)
    batchcmds:compile(sourcefile_cx, objectfile, {configs = {includedirs = sourcefile_dir}})
    if grpc_cpp_plugin then
        batchcmds:compile(sourcefile_cx_grpc, objectfile_grpc, {configs = {includedirs = sourcefile_dir}})
    end

    -- add deps
    local depmtime = os.mtime(objectfile)
    batchcmds:add_depfiles(sourcefile_proto)
    batchcmds:set_depcache(target:dependfile(objectfile))
    if grpc_cpp_plugin then
        batchcmds:set_depmtime(math.max(os.mtime(objectfile_grpc), depmtime))
    else
        batchcmds:set_depmtime(depmtime)
    end
end

function build_cxfile_objects(target, batchjobs, opt, sourcekind)
    -- do build
    local sourcebatch_cx = {
        rulename = (sourcekind == "cxx" and "c++" or "c").. ".build",
        sourcekind = sourcekind,
        sourcefiles = {},
        objectfiles = {},
        dependfiles = {}
    }
    for _, sourcefile_proto in ipairs(sourcefiles) do
        -- get c/c++ source file for protobuf
        local prefixdir
        local autogendir
        local public
        local grpc_cpp_plugin
        local fileconfig = target:fileconfig(sourcefile_proto)
        if fileconfig then
            public = fileconfig.proto_public
            prefixdir = fileconfig.proto_rootdir
            -- custom autogen directory to access the generated header files
            -- @see https://github.com/xmake-io/xmake/issues/3678
            autogendir = fileconfig.proto_autogendir
            grpc_cpp_plugin = fileconfig.proto_grpc_cpp_plugin
        end
        local rootdir = autogendir and autogendir or path.join(target:autogendir(), "rules", "protobuf")
        local filename = path.basename(sourcefile_proto) .. ".pb" .. (sourcekind == "cxx" and ".cc" or "-c.c")
        local sourcefile_cx = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename})
        local sourcefile_dir = prefixdir and path.join(rootdir, prefixdir) or path.directory(sourcefile_cx)
        
        local grpc_cpp_plugin_bin
        local filename_grpc
        local sourcefile_cx_grpc
        if grpc_cpp_plugin then
            grpc_cpp_plugin_bin = _get_grpc_cpp_plugin(target, sourcekind)
            filename_grpc = path.basename(sourcefile_proto) .. ".grpc.pb.cc"
            sourcefile_cx_grpc = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename_grpc})
        end

        -- add includedirs
        target:add("includedirs", sourcefile_dir, {public = public})
        
        -- add objectfile
        local objectfile = target:objectfile(sourcefile_cx)
        local dependfile = target:dependfile(sourcefile_proto)
        table.insert(sourcebatch_cx.sourcefiles, sourcefile_cx)
        table.insert(sourcebatch_cx.objectfiles, objectfile)
        table.insert(sourcebatch_cx.dependfiles, dependfile)

        local objectfile_grpc
        if grpc_cpp_plugin then
            objectfile_grpc = target:objectfile(sourcefile_cx_grpc)
            table.insert(sourcebatch_cx.sourcefiles, sourcefile_cx_grpc)
            table.insert(sourcebatch_cx.objectfiles, objectfile_grpc)
            table.insert(sourcebatch_cx.dependfiles, dependfile)
        end
    end
    build_objectfiles(target, batchjobs, sourcebatch_cx, opt)
end

-- build batch jobs
function build_cxfiles(target, batchjobs, sourcebatch, opt, sourcekind)
    -- load moduledeps
    opt = opt or {}

    local jobs = jobpool.new()

    local root = jobs:addjob("job/root", function(_index, _total)
        build_cxfile_objects(target, batchjobs, opt, sourcekind)
    end)

    -- get protoc
    local protoc = _get_protoc(target, sourcekind)

    local sourcefiles = sourcebatch.sourcefiles
    for _, sourcefile_proto in ipairs(sourcefiles) do
        local dependfile = target:dependfile(sourcefile_proto)
        depend.on_changed(function()
            -- get c/c++ source file for protobuf
            local prefixdir
            local autogendir
            local public
            local grpc_cpp_plugin
            local fileconfig = target:fileconfig(sourcefile_proto)
            if fileconfig then
                public = fileconfig.proto_public
                prefixdir = fileconfig.proto_rootdir
                -- custom autogen directory to access the generated header files
                -- @see https://github.com/xmake-io/xmake/issues/3678
                autogendir = fileconfig.proto_autogendir
                grpc_cpp_plugin = fileconfig.proto_grpc_cpp_plugin
            end
            local rootdir = autogendir and autogendir or path.join(target:autogendir(), "rules", "protobuf")
            local filename = path.basename(sourcefile_proto) .. ".pb" .. (sourcekind == "cxx" and ".cc" or "-c.c")
            local sourcefile_cx = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename})
            local sourcefile_dir = prefixdir and path.join(rootdir, prefixdir) or path.directory(sourcefile_cx)
        
            local grpc_cpp_plugin_bin
            local filename_grpc
            local sourcefile_cx_grpc
            if grpc_cpp_plugin then
                grpc_cpp_plugin_bin = _get_grpc_cpp_plugin(target, sourcekind)
                filename_grpc = path.basename(sourcefile_proto) .. ".grpc.pb.cc"
                sourcefile_cx_grpc = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename_grpc})
            end
        
            local protoc_args = {
                path(sourcefile_proto),
                path(prefixdir and prefixdir or path.directory(sourcefile_proto), function (p) return "-I" .. p end),
                path(sourcefile_dir, function (p) return (sourcekind == "cxx" and "--cpp_out=" or "--c_out=") .. p end)
            }
        
            if grpc_cpp_plugin then
                local extension = target:is_plat("windows") and ".exe" or ""
                table.insert(protoc_args, "--plugin=protoc-gen-grpc=" .. grpc_cpp_plugin_bin .. extension)
                table.insert(protoc_args, path(sourcefile_dir, function (p) return ("--grpc_out=") .. p end))
            end

            os.mkdir(sourcefile_dir)

            local job = jobs:addjob("job/" .. sourcefile_proto, function(index, total)
                progress.show((index * 100) / total, "${color.build.object}compiling.proto %s", sourcefile_proto)
                os.vrunv(protoc, protoc_args)
            end, {rootjob = root})
        end, {
            dependfile = dependfile,
            files = {sourcefile_proto},
            changed = target:is_rebuilt()
        })
    end
    runjobs("build_compile_proto", jobs, opt)    
end
