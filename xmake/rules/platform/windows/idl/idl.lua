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
-- @file        idl.lua
--
import("private.action.build.object", {alias = "build_objectfiles"})
import("lib.detect.find_tool")
import("core.project.depend")
import("utils.progress") -- it only for v2.5.9, we need use print to show prog

function generate_single(target, sourcefile, opt)
    local msvc = target:toolchain("msvc") or target:toolchain("clang-cl") or target:toolchain("clang")
    local midl = assert(find_tool("midl", {envs = msvc:runenvs(), toolchain = msvc}), "midl not found!")

    local name = path.basename(sourcefile)
    local fileconfig = target:fileconfig(sourcefile)
    local autogendir = path.join(target:autogendir(), "platform/windows/idl")

    local enable_server = true
    local enable_client = true
    local defs = table.wrap(target:get("defines") or {})
    local incs = table.wrap(target:get("includedirs") or {})
    local undefs = table.wrap(target:get("undefines") or {})


    if fileconfig then
        if fileconfig.server ~= nil then
            enable_server = fileconfig.server
        end
        if fileconfig.client ~= nil then
            enable_client = fileconfig.client
        end
        if fileconfig.includedirs then
            table.join2(incs, fileconfig.includedirs)
        end
        if fileconfig.defines then
            table.join2(defs, fileconfig.defines)
        end
        if fileconfig.undefines then
            table.join2(undefs, fileconfig.undefines)
        end
    end


    local flags = {"/nologo"}
    table.join2(flags, table.wrap(target:values("idl.flags")))

    -- specify warn levels
    local warns = target:get("warnings")
    if warns == "none" then
        table.insert(flags, "/W0")
        table.insert(flags, "/no_warn")
    elseif warns == "less" then
        table.insert(flags, "/W1")
    elseif warns == "more" then
        table.insert(flags, "/W2")
    elseif warns == "extra" then
        table.insert(flags, "/W3")
    elseif warns == "error" then
        table.insert(flags, "/WX")
        table.insert(flags, "/W4")
    end

    -- add include dirs, defines and undefines from compiler flags
    for _, inc in ipairs(incs) do
        table.insert(flags, "/I")
        table.insert(flags, path(inc))
    end

    for _, def in ipairs(defs) do
        table.insert(flags, "/D")
        table.insert(flags, def)
    end

    for _, undef in ipairs(undefs) do
        table.insert(flags, "/U")
        table.insert(flags, undef)
    end

    table.join2(flags, {
        "/out",    path(autogendir),
        "/header", name .. ".h",
        "/iid",    name .. "_i.c",
        "/proxy",  name .. "_p.c",
        "/tlb",    name .. ".tlb",
        "/cstub",  name .. "_c.c",
        "/sstub",  name .. "_s.c",
        "/server", (enable_server and "stub" or "none"),
        "/client", (enable_client and "stub" or "none"),
        path(sourcefile)
    })

    depend.on_changed(function() 
        progress.show(opt.progress or 0, "${color.build.object}generating.idl %s", sourcefile)
        os.vrunv(midl.program, flags, { envs = msvc:runenvs() })
    end, {files = sourcefile, 
         dependfile = path.join(autogendir, path.basename(sourcefile) .. ".idl.d") }
    )
end

-- add *.idl for rc file

function configure(target)
    local sourcebatch = target:sourcebatches()["platform.windows.idl"]
    if sourcebatch then
        local autogendir = path.join(target:autogendir(), "platform/windows/idl")
        os.mkdir(autogendir)
        target:add("includedirs", autogendir, {public = true})
    end
end

function build_idlfiles(target, jobgraph, sourcebatch, opt)
    local mysources = {}
    local autogendir = path.join(target:autogendir(), "platform/windows/idl")

    local addsrc = function (sourcename, suffix)
        local fullfile = path.join(autogendir, sourcename .. suffix)
        if os.exists(fullfile) then
            table.insert(mysources, fullfile)
        end
    end

    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local fileconfig = target:fileconfig(sourcefile)
        local enable_proxy = true
        if fileconfig then
            if fileconfig.proxy ~= nil then
                enable_proxy = fileconfig.proxy
            end
        end

        generate_single(target, sourcefile, opt)

        local name = path.basename(sourcefile)

        addsrc(name, "_i.c")

        if enable_proxy then
            addsrc(name, "_p.c")
        end

        addsrc(name, "_c.c")
        addsrc(name, "_s.c")
    end

    -- we don't have a way to detect which midl files are generated

    local batchcxx = {
        rulename = "c.build",
        sourcekind = "cc",
        sourcefiles = mysources,
        objectfiles = {},
        dependfiles = {}
    }
    for _, sourcefile in ipairs(batchcxx.sourcefiles) do
        local objfile = target:objectfile(sourcefile)
        local depfile = target:objectfile(objfile)
        table.insert(target:objectfiles(), objfile)
        table.insert(batchcxx.objectfiles, objfile)
        table.insert(batchcxx.dependfiles, depfile)
    end
    build_objectfiles(target, jobgraph, batchcxx, opt)
end
