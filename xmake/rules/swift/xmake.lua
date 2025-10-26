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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        xmake.lua
--

rule("swift.interop", function()
    set_sourcekinds("sc")
    add_orders("swift.interop", "swift.build")
    add_orders("swift.interop", "c++.build")
    on_config(function(target)
        import("core.base.json")

        if not target:values("swift.interop") then
            target:rule_enable("swift.interop", false)
            return
        end

        local sourcebatches = target:sourcebatches()
        local sourcebatch = sourcebatches and sourcebatches["swift.interop"]
        local sourcefiles = sourcebatch and sourcebatch.sourcefiles
        sourcefiles = sourcefiles or {}
        local enabled = false
        for _, sourcefile in ipairs(sourcefiles) do
            local fileconfig = target:fileconfig(sourcefile)
            if fileconfig and fileconfig.public then
                enabled = true
                break
            end
        end
        if not enabled then
            target:rule_enable("swift.interop", false)
            return
        end

        local sc = target:tool("sc")
        assert(sc, "No swift compiler found!")
        local outdata, errdata = os.iorunv(sc, {"-print-target-info"})
        assert(outdata, errdata)

        local target_info = json.decode(outdata)
        assert(target_info and target_info.paths and target_info.paths.runtimeResourcePath, "Failed to get swift resource path")
        target:add("includedirs", target_info.paths.runtimeResourcePath, {public = true})

        local outdir = target:autogendir("swift.interop")
        target:add("includedirs", outdir, {public = true})

        local mode = (type(target:values("swift.interop")) == "string") and target:values("swift.interop") or "objc"

        local headername = (target:values("swift.interop.headername") or (target:name() .. "-Swift.h"))
        local header = path.join(outdir, headername)
        target:add("headerfiles", header)

        target:data_set("swift.interop", mode)
        target:data_set("swift.interop.outdir", outdir)
    end)

    on_prepare_files(function(target, jobgraph, sourcebatch, opt)
        import("utils.progress")
        import("core.base.option")
        import("core.tool.compiler")
        import("core.language.language")
        import("core.project.depend")
        import("core.cache.localcache")

        local function _get_target_cpp_langflags()
            local cpp_langflags = _g.cpp_langflags
            if cpp_langflags == nil then
                local languages = target:get("languages")
                for _, language in ipairs(languages) do
                    if language:startswith("c++")
                        or language:startswith("cxx")
                        or language:startswith("gnu++")
                        or language:startswith("gnuxx") then
                        -- c++26 currently prevent compilation of swift modules
                        language = language:gsub("26", "23"):gsub("latest", "23")
                        cpp_langflags = compiler.map_flags("cxx", "language", language, {target = target})
                        _g.cpp_langflags = cpp_langflags or false
                    end
                end
            end
            return cpp_langflags or nil
        end

        local mode = target:data("swift.interop")
        local sc = target:tool("sc")
        assert(sc, "No swift compiler found!")
        local outdir = target:data("swift.interop.outdir")
        if not os.isdir(outdir) then os.mkdir(outdir) end
        assert(outdir)

        local sourcefiles = sourcebatch.sourcefiles
        local public_sourcefiles
        for _, sourcefile in ipairs(sourcefiles) do
            local fileconfig = target:fileconfig(sourcefile)
            if fileconfig and fileconfig.public then
                public_sourcefiles = public_sourcefiles or {}
                table.insert(public_sourcefiles, sourcefile)
            end
        end

        if public_sourcefiles then
            local modulename = target:values("swift.modulename") or target:name()
            local headername = (target:values("swift.interop.headername") or (target:name() .. "-Swift.h"))
            local header = path.join(outdir, headername)

            jobgraph:add(target:fullname() .. "/gen_swift_header", function(index, total, opt)
                depend.on_changed(function()
                    local stdflag
                    if mode == "cxx" then
                        local cpp_langflags = _get_target_cpp_langflags()
                        if cpp_langflags then
                            for _, flag in ipairs(cpp_langflags) do
                                stdflag = stdflag or {}
                                table.join2(stdflag, {"-Xcc", flag})
                            end
                        end
                    end

                    if opt.progress then
                        progress.show(
                            opt.progress,
                            "${clear}${color.build.target}<%s> generating.swift.header %s",
                            target:fullname(),
                            headername
                        )
                    end

                    local compinst = import("core.tool.compiler").load("sc")
                    local _scflags = compinst:compflags({target = target, sourcekind = "sc"})
                    local scflags
                    if target:has_tool("sc", "swift_frontend") then
                        for _, scflag in ipairs(_scflags) do
                            scflags = scflags or {}
                            if not os.isfile(scflag) then
                                table.insert(scflags, scflag)
                            end
                        end
                    else
                        scflags = _scflags
                    end

                    local emit_flag = mode == "cxx" and "-emit-clang-header-path" or "-emit-objc-header-path"

                    local flags = table.join({
                        "-frontend",
                        "-typecheck",
                        emit_flag,
                        header,
                        },
                        scflags or {},
                        stdflag or {},
                        public_sourcefiles)
                    if option.get("verbose") then
                        print(os.args(table.join(sc, flags)))
                    end

                    if os.isfile(header) then
                        os.rm(header)
                    end
                    local outdata, errdata = os.iorunv(sc, flags)
                    assert(outdata, errdata)
                end, {
                    files = public_sourcefiles,
                    changed = target:is_rebuilt() or not os.isfile(header),
                })
            end)
        end
    end, { jobgraph = true })
end)

-- define rule: swift.build
rule("swift.build")
    set_sourcekinds("sc")
    on_build_files("private.action.build.object", {jobgraph = true, batch = true})
    on_config(function (target)
        local mode = (type(target:values("swift.interop")) == "string") and target:values("swift.interop") or "objc"
        if mode == "cxx" then
            target:add("scflags", "-cxx-interoperability-mode=default")
        end

        if target:is_library() or target:values("swift.interop.cxxmain") then
            target:add("scflags", "-parse-as-library")
        end
        local modulename = target:values("swift.modulename") or target:name()
        target:add("scflags", "-module-name", modulename, {force = true})
        -- we use swift-frontend to support multiple modules
        -- @see https://github.com/xmake-io/xmake/issues/3916
        if target:has_tool("sc", "swift_frontend") then
            local sourcebatch = target:sourcebatches()["swift.build"]
            if sourcebatch then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    target:add("scflags", sourcefile, {force = true})
                end
            end
        end
    end)

-- define rule: swift
rule("swift")
    -- add build rules
    add_deps("swift.interop")

    -- add build rules
    add_deps("swift.build")

    -- set compiler runtime, e.g. vs runtime
    add_deps("utils.compiler.runtime")

    -- inherit links and linkdirs of all dependent targets by default
    add_deps("utils.inherit.links")

    -- support `add_files("src/*.o")` to merge object files to target
    add_deps("utils.merge.object")

    -- add linker rules
    add_deps("linker")
