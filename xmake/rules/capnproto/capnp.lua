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
-- @author      wsw0108
-- @file        capnp.lua
--

-- imports
import("lib.detect.find_tool")

-- get capnp
function _get_capnp(target)

    -- find capnp
    local capnp = target:data("capnproto.capnp")
    if not capnp then
        capnp = find_tool("capnp")
        if capnp and capnp.program then
            target:data_set("capnproto.capnp", capnp.program)
        end
    end

    -- get capnp
    return assert(target:data("capnproto.capnp"), "capnp not found!")
end

-- generate build commands
function buildcmd(target, batchcmds, sourcefile_capnp, opt)

    -- get capnp
    local capnp = _get_capnp(target)

    -- get c/c++ source file for capnproto
    local prefixdir
    local public
    local fileconfig = target:fileconfig(sourcefile_capnp)
    if fileconfig then
        public = fileconfig.capnp_public
        prefixdir = fileconfig.capnp_rootdir
    end
    local rootdir = path.join(target:autogendir(), "rules", "capnproto")
    local filename = path.basename(sourcefile_capnp) .. ".capnp.c++"
    local sourcefile_cx = target:autogenfile(sourcefile_capnp, {rootdir = rootdir, filename = filename})
    local sourcefile_dir = prefixdir and path.join(rootdir, prefixdir) or path.directory(sourcefile_cx)

    -- add includedirs
    target:add("includedirs", sourcefile_dir, {public = public})

    -- add objectfile
    local objectfile = target:objectfile(sourcefile_cx)
    table.insert(target:objectfiles(), objectfile)

    -- add commands
    batchcmds:mkdir(sourcefile_dir)
    batchcmds:show_progress(opt.progress, "${color.build.object}compiling.capnp %s", sourcefile_capnp)
    local capnproto = target:pkg("capnproto")
    local includes = capnproto:get("sysincludedirs")
    local argv = {"compile"}
    for _, value in ipairs(includes) do
        table.insert(argv, path(value, function (p) return "-I" .. p end))
    end
    table.insert(argv, path(prefixdir and prefixdir or path.directory(sourcefile_capnp), function (p) return "-I" .. p end))
    if prefixdir then
        table.insert(argv, path(prefixdir, function (p) return "--src-prefix=" .. p end))
    end
    table.insert(argv, "-o")
    table.insert(argv, path(sourcefile_dir, function (p) return "c++:" .. p end))
    table.insert(argv, path(sourcefile_capnp))
    batchcmds:vrunv(capnp, argv)
    local configs = {includedirs = sourcefile_dir, languages = "c++14"}
    if target:is_plat("windows") then
        configs.cxflags = "/TP"
    end
    batchcmds:compile(sourcefile_cx, objectfile, {sourcekind = "cxx", configs = configs})

    -- add deps
    batchcmds:add_depfiles(sourcefile_capnp)
    batchcmds:set_depmtime(os.mtime(objectfile))
    batchcmds:set_depcache(target:dependfile(objectfile))
end
