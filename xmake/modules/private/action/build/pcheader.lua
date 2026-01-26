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
-- @file        pcheader.lua
--

-- imports
import("core.language.language")
import("core.tool.compiler")
import("core.project.depend")
import("private.cache.build_cache")

function config(target, langkind, opt)
    local pcheaderfile = target:pcheaderfile(langkind)
    if pcheaderfile then
        local sourcekind = language.langkinds()[langkind] or "cxx"
        if target:has_tool(sourcekind, "cl", "clang_cl", "gcc", "gxx") then
            local headerfile = target:autogenfile(pcheaderfile)
            local gcc = false
            if target:has_tool(sourcekind, "gcc", "gxx") then
                local pcoutputfile = target:pcoutputfile(langkind)
                headerfile = path.join(path.directory(pcoutputfile), path.filename(headerfile))
                gcc = true
            end
            -- fix `#pragma once` for msvc
            -- https://github.com/xmake-io/xmake/issues/2667
            -- https://github.com/xmake-io/xmake/issues/5858
            if not os.isfile(headerfile) then
                io.writefile(headerfile, ([[
#pragma system_header
#ifdef __cplusplus
#include "%s"
#endif // __cplusplus
                ]]):format(path.absolute(pcheaderfile):gsub("\\", "/")))
            end
            -- we need only to add a header wrapper in .gch directory
            -- @see https://github.com/xmake-io/xmake/issues/5858#issuecomment-2506918167
            if not gcc then
                target:pcheaderfile_set(langkind, headerfile)
            end
        end

        -- enable precompiled header?
        return true
    end
end

-- add batch jobs to build the precompiled header file
function build(target, jobgraph, langkind, opt)
    opt = opt or {}
    local pcheaderfile = target:pcheaderfile(langkind)
    if pcheaderfile then
        local sourcefile = pcheaderfile
        local objectfile = target:pcoutputfile(langkind)
        local dependfile = target:dependfile(objectfile)
        local sourcekind = language.langkinds()[langkind]

        -- load compiler
        local compinst = compiler.load(sourcekind, {target = target})

        -- get compile flags
        local configs = {}
        if opt and opt.configs then
            configs = table.clone(opt.configs)
        end

        if target:has_tool(sourcekind, "gcc", "gxx", "clang", "clang++") then
            local EXTENSIONS = {
                [".h"] = true,
                [".hh"] = true,
                [".hpp"] = true,
                [".hxx"] = true,
                [".h++"] = true,
                [".tcc"] = true,
                [".inl"] = true,
                [".ii"] = true,
                [".ixx"] = true,
                [".cppm"] = true,
                [".mpp"] = true,
            }
            if not EXTENSIONS[path.extension(pcheaderfile):lower()] then
                configs.force = configs.force or {}
                configs.force.cxflags = (sourcekind == "cxx" and "-x c++-header" or "-x c-header")
            end
        end
        local compflags = compinst:compflags({target = target, sourcefile = sourcefile, configs = configs})

        -- filter flags
        local compflags_new = {}
        local skip = 0
        for i, flag in ipairs(compflags) do
            if skip > 0 then
                skip = skip - 1
            elseif flag == "-include-pch" then
                skip = 1
            elseif flag == "-include" then
                local nextval = compflags[i + 1]
                if nextval and (nextval:find(path.filename(pcheaderfile), 1, true) or path.absolute(nextval) == path.absolute(pcheaderfile)) then
                    skip = 1
                else
                    table.insert(compflags_new, flag)
                end
            else
                table.insert(compflags_new, flag)
            end
        end
        compflags = compflags_new

        -- add job
        local jobname = target:fullname() .. "/pch/" .. sourcefile
        jobgraph:add(jobname, function (index, total, jobopt)

            -- trace
            if not opt.quiet then
                print(compinst:compcmd(sourcefile, objectfile, {compflags = compflags}))
            end

            -- load dependent info
            local dependinfo = target:is_rebuilt() and {} or (depend.load(dependfile, {target = target}) or {})

            -- need build this object?
            local depvalues = {compinst:program(), compflags}
            local lastmtime = os.isfile(objectfile) and os.mtime(dependfile) or 0
            if not depend.is_changed(dependinfo, {lastmtime = lastmtime, values = depvalues}) then
                return
            end

            -- do compile
            dependinfo.files = {}
            assert(compinst:compile(sourcefile, objectfile, {dependinfo = dependinfo, compflags = compflags}))

            -- update files and values to the dependent file
            dependinfo.values = depvalues
            table.insert(dependinfo.files, sourcefile)
            depend.save(dependinfo, dependfile)

        end, {distcc = opt.distcc})
    end
end
