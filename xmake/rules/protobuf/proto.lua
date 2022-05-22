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
import("private.utils.batchcmds")
import("module_parser")

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

-- we need add some configs to export includedirs to other targets in on_load
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
    local public
    local fileconfig = target:fileconfig(sourcefile_proto)
    if fileconfig then
        public = fileconfig.proto_public
        prefixdir = fileconfig.proto_rootdir
    end
    local rootdir = path.join(target:autogendir(), "rules", "protobuf")
    local filename = path.basename(sourcefile_proto) .. ".pb" .. (sourcekind == "cxx" and ".cc" or "-c.c")
    local sourcefile_cx = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename})
    local sourcefile_dir = prefixdir and path.join(rootdir, prefixdir) or path.directory(sourcefile_cx)

    -- add includedirs
    target:add("includedirs", sourcefile_dir, {public = public})
end

-- generate build commands
function buildcmd(target, batchcmds, sourcefile_proto, opt, sourcekind)

    -- get protoc
    local protoc = _get_protoc(target, sourcekind)

    -- get c/c++ source file for protobuf
    local prefixdir
    local public
    local fileconfig = target:fileconfig(sourcefile_proto)
    if fileconfig then
        public = fileconfig.proto_public
        prefixdir = fileconfig.proto_rootdir
    end
    local rootdir = path.join(target:autogendir(), "rules", "protobuf")
    local filename = path.basename(sourcefile_proto) .. ".pb" .. (sourcekind == "cxx" and ".cc" or "-c.c")
    local sourcefile_cx = target:autogenfile(sourcefile_proto, {rootdir = rootdir, filename = filename})
    local sourcefile_dir = prefixdir and path.join(rootdir, prefixdir) or path.directory(sourcefile_cx)

    -- add includedirs
    target:add("includedirs", sourcefile_dir, {public = public})

    -- add objectfile
    local objectfile = target:objectfile(sourcefile_cx)
    table.insert(target:objectfiles(), objectfile)

    -- add commands
    batchcmds:mkdir(sourcefile_dir)
    batchcmds:show_progress(opt.progress, "${color.build.object}compiling.proto %s", sourcefile_proto)
    batchcmds:vrunv(protoc, {path(sourcefile_proto),
        path(prefixdir and prefixdir or path.directory(sourcefile_proto), function (p) return "-I" .. p end),
        path(sourcefile_dir, function (p) return (sourcekind == "cxx" and "--cpp_out=" or "--c_out=") .. p end)})
    batchcmds:compile(sourcefile_cx, objectfile, {configs = {includedirs = sourcefile_dir, languages = (sourcekind == "cxx" and "c++11")}})

    -- add deps
    batchcmds:add_depfiles(sourcefile_proto)
    batchcmds:set_depmtime(os.mtime(objectfile))
    batchcmds:set_depcache(target:dependfile(objectfile))
end

-- build batch jobs
function build_batchjobs(target, batchjobs, sourcebatch, opt, sourcekind)

    -- get the root directory of protobuf
    local proto_rootdir
    if #sourcebatch.sourcefiles > 0 then
        local sourcefile = sourcebatch.sourcefiles[1]
        local fileconfig = target:fileconfig(sourcefile)
        if fileconfig then
            proto_rootdir = fileconfig.proto_rootdir
        end
    end

    -- load moduledeps
    opt = opt or {}
    local moduledeps, moduledeps_files = module_parser.load(target, sourcebatch, table.join(opt, {proto_rootdir = proto_rootdir}))

    -- generate jobs
    local sourcefiles_total = #sourcebatch.sourcefiles
    for i = 1, sourcefiles_total do
        local sourcefile = sourcebatch.sourcefiles[i]
        local moduleinfo = moduledeps_files[sourcefile] or {}

        -- make build job
        moduleinfo.job = batchjobs:newjob(sourcefile, function (index, total)
            local batchcmds_ = batchcmds.new({target = target})
            buildcmd(target, batchcmds_, sourcefile, {progress = (index * 100) / total}, sourcekind)
            batchcmds_:runcmds({dryrun = option.get("dry-run")})
        end)
    end

    -- build batchjobs
    module_parser.build_batchjobs(moduledeps, batchjobs, opt.rootjob)
end

