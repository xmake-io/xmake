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
-- @file        xmake.lua
--

-- add *.idl for rc file
rule("platform.windows.idl")
    set_extensions(".idl")

    on_config("windows", "mingw", function (target)
        local sourcebatch = target:sourcebatches()["platform.windows.idl"]
        if sourcebatch then
            local autogendir = path.join(target:autogendir(), "platform/windows/idl")
            os.mkdir(autogendir)
            target:add("includedirs", autogendir, {public = true})
        end
    end)

    before_buildcmd_file(function (target, batchcmds, sourcefile, opt)
        import("lib.detect.find_tool")
        import("core.project.depend")
        import("utils.progress") -- it only for v2.5.9, we need use print to show prog

        local fileconfig = target:fileconfig(sourcefile)
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

        local msvc = target:toolchain("msvc") or target:toolchain("clang-cl") or target:toolchain("clang")
        local midl = assert(find_tool("midl", {envs = msvc:runenvs(), toolchain = msvc}), "midl not found!")

        local name = path.basename(sourcefile)
        local autogendir = path.join(target:autogendir(), "platform/windows/idl")

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
            table.insert(flags, path.absolute(inc))
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

        -- use this way to set depend to avoid generating files multiple times
        depend.on_changed(function() 
            progress.show(opt.progress, "${color.build.object}generating.idl %s", sourcefile)
            os.vrunv(midl.program, flags, { envs = msvc:runenvs() })
        end, { files = sourcefile, dependfile = path.join(autogendir, path.basename(sourcefile) .. ".idl.d") })
    end)
    
    --[[
        we don't have a way to detect which files midl.exe has generated and os.exists
        does not work in before_buildcmd_file because in the invokation of xmake
        the files might not have been generated yet from batchcmds, therefore
        the files are compiled and checked during the buildcmd as _i, _p, _c, _s
        might not exists depending on the idl file
    ]]
    on_buildcmd_file(function (target, batchcmds, sourcefile, opt)
        import("core.project.depend")

        local name = path.basename(sourcefile)
        local autogendir = path.join(target:autogendir(), "platform/windows/idl")

        -- we don't have a way to detect which midl files are generated

        local icfile = path.join(autogendir, name .. "_i.c")
        local icobj = target:objectfile(icfile)

        local scfile = path.join(autogendir, name .. "_s.c")
        local scobj = target:objectfile(scfile)

        local ccfile = path.join(autogendir, name .. "_c.c")
        local ccobj = target:objectfile(ccfile)

        local pcfile = path.join(autogendir, name .. "_p.c")
        local pcobj = target:objectfile(pcfile)

        local fileconfig = target:fileconfig(sourcefile)
        local enable_proxy = true
        if fileconfig then
            if fileconfig.proxy ~= nil then
                enable_proxy = fileconfig.proxy
            end
        end

        -- compile c files
        local configs = {includedirs = autogendir, languages = "c89"}

        if os.exists(icfile) then
            table.insert(target:objectfiles(), icobj)
            batchcmds:show_progress(opt.progress, "${color.build.object}compiling.$(mode) %s", icfile)
            batchcmds:compile(icfile, icobj, {sourcekind = "cxx", configs = configs})                 
            batchcmds:add_depfiles(icfile)
            batchcmds:set_depmtime(os.mtime(icobj))
            batchcmds:set_depcache(target:dependfile(icobj))
        end

        if os.exists(scfile) then
            table.insert(target:objectfiles(), scobj)
            batchcmds:show_progress(opt.progress, "${color.build.object}compiling.$(mode) %s", scfile)
            batchcmds:compile(scfile, scobj, {sourcekind = "cxx", configs = configs})
            batchcmds:add_depfiles(scfile)
            batchcmds:set_depmtime(os.mtime(scobj))
            batchcmds:set_depcache(target:dependfile(scobj))
        end

        if os.exists(pcfile) and enable_proxy then
            table.insert(target:objectfiles(), pcobj)
            batchcmds:show_progress(opt.progress, "${color.build.object}compiling.$(mode) %s", pcfile)
            batchcmds:compile(pcfile, pcobj, {sourcekind = "cxx", configs = configs})
            batchcmds:add_depfiles(pcfile)
            batchcmds:set_depmtime(os.mtime(pcobj))
            batchcmds:set_depcache(target:dependfile(pcobj))
        end

        if os.exists(ccfile) then
            table.insert(target:objectfiles(), ccobj)
            batchcmds:show_progress(opt.progress, "${color.build.object}compiling.$(mode) %s", ccfile)
            batchcmds:compile(ccfile, ccobj, {sourcekind = "cxx", configs = configs})
            batchcmds:add_depfiles(ccfile)
            batchcmds:set_depmtime(os.mtime(ccobj))
            batchcmds:set_depcache(target:dependfile(ccobj))
        end
    end)
