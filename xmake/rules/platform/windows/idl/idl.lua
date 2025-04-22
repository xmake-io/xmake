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

    local enable_server = true
    local enable_client = true
    local defs = table.wrap(target:get("defines") or {})
    local incs = table.wrap(target:get("includedirs") or {})
    local undefs = table.wrap(target:get("undefines") or {})

    if fileconfig then
        if fileconfig.server then
            enable_server = fileconfig.server
        end
        if fileconfig.client then
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

    local dependfile = path.join(autogendir, path.basename(sourcefile) .. ".idl.d")
    depend.on_changed(function()
        progress.show(opt.progress or 0, "${color.build.object}generating.idl %s", sourcefile)
        os.vrunv(midl.program, flags, { envs = msvc:runenvs() })
    end, {
        files = sourcefile,
        dependfile = dependfile
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
    local idljob = target:fullname() .. "/generate/midl"
    jobgraph:group(idljob, function()
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local midljob = target:fullname() .. "/generate/" .. sourcefile
            jobgraph:add(midljob, function (index, total, opt)
                generate_single(target, sourcefile, opt)
            end)
        end
    end)
end

function build_idlfiles(target, jobgraph, sourcebatch, opt)
    local autogendir = path.join(target:autogendir(), "platform/windows/idl")

    local function addsrc(sourcename, suffix, mysources)
        local fullfile = path.join(autogendir, sourcename .. suffix)
        if os.exists(fullfile) then
            table.insert(mysources, fullfile)
        end
    end

    local build_midl = target:fullname() .. "/obj/midl"
    jobgraph:group(build_midl, function()
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local ccjob = target:fullname() .. "/obj/" .. sourcefile
            jobgraph:add(ccjob, function (index, total, opt)
                local fileconfig = target:fileconfig(sourcefile)
                local enable_proxy = true
                if fileconfig then
                    if fileconfig.proxy then
                        enable_proxy = fileconfig.proxy
                    end
                end
                local name = path.basename(sourcefile)
                local mysources = {}

                -- we don't have a way to detect which midl files are generated
                addsrc(name, "_i.c", mysources)
                if enable_proxy then
                    addsrc(name, "_p.c", mysources)
                end
                addsrc(name, "_c.c", mysources)
                addsrc(name, "_s.c", mysources)

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
                    table.insert(target:objectfiles(), objfile)
                end
                build_objectfiles.build(target, batchcxx, opt)
            end)
        end
    end)
end
