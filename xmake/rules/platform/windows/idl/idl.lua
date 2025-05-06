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

-- imports
import("lib.detect.find_tool")
import("core.project.depend")
import("utils.progress")
import("private.action.build.object", {alias = "build_objectfiles"})

function generate_single(target, sourcefile, opt)
    local msvc = target:toolchain("msvc") or target:toolchain("clang-cl") or target:toolchain("clang")
    local midl = assert(find_tool("midl", {envs = msvc:runenvs(), toolchain = msvc}), "midl not found!")

    local name = path.basename(sourcefile)
    local fileconfig = target:fileconfig(sourcefile)
    local autogendir = path.join(target:autogendir(), "platform/windows/idl")

    local enable_server
    local enable_client
    local defs = table.wrap(target:get("defines") or {})
    local incs = table.wrap(target:get("includedirs") or {})
    local undefs = table.wrap(target:get("undefines") or {})

    if fileconfig then
        enable_server = fileconfig.server
        enable_client = fileconfig.client
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

    local dependfile = path.join(autogendir, path.basename(sourcefile) .. ".idl.d")
    depend.on_changed(function()
        progress.show(opt.progress or 0, "${color.build.object}generating.idl %s", sourcefile)
        os.vrunv(midl.program, flags, { envs = msvc:runenvs() })
    end, {
        files = sourcefile,
        dependfile = target:dependfile(sourcefile),
        changed = target:is_rebuilt()
    })
end

function configure(target)
    local sourcebatch = target:sourcebatches()["platform.windows.idl"]
    if sourcebatch then
        local autogendir = path.join(target:autogendir(), "platform/windows/idl")
        os.mkdir(autogendir)
        target:add("includedirs", autogendir, {public = true})
    end
end

function generate_idl(target, jobgraph, sourcebatch, opt)
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local midljob = target:fullname() .. "/generate/" .. sourcefile
        jobgraph:add(midljob, function (index, total, opt)
            generate_single(target, sourcefile, opt)
        end)
    end
end

function build_idlfiles(target, jobgraph, sourcebatch, opt)
    local autogendir = path.join(target:autogendir(), "platform/windows/idl")
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local fileconfig = target:fileconfig(sourcefile)
        local files = {"_i.c", "_c.c", "_s.c"}
        if fileconfig and fileconfig.proxy then
            table.insert(files, "_p.c")
        end

        local name = path.basename(sourcefile)
        for _, suffix in ipairs(files) do
            local c_sourcefile = path.join(autogendir, name .. suffix)
            local objectfile = target:objectfile(c_sourcefile)
            local dependfile = target:dependfile(objectfile)
            local cc_job_name = path.join(target:fullname(), "/obj/", c_sourcefile)
            jobgraph:add(cc_job_name, function (index, total, jobopt)
                -- we don't have a way to detect which midl files are generated
                if os.exists(c_sourcefile) then
                    table.insert(target:objectfiles(), objectfile)
                    local build_opt = table.join({objectfile = objectfile, dependfile = dependfile, sourcekind = "cc", progress = jobopt.progress}, opt)
                    build_objectfiles.build_object(target, c_sourcefile, build_opt)
                end
            end, {distcc = opt.distcc})
        end
    end
end
